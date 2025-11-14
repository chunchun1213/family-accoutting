-- 建立認證相關表格
-- Migration: 20251114014634_create_auth_tables

-- ============================================
-- 1. 使用者個人資料表格 (user_profiles)
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (length(name) >= 1 AND length(name) <= 50),
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS 政策：使用者僅能讀取自己的個人資料
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "使用者可讀取自己的個人資料" 
  ON public.user_profiles 
  FOR SELECT 
  USING (auth.uid() = id);

CREATE POLICY "使用者可更新自己的個人資料" 
  ON public.user_profiles 
  FOR UPDATE 
  USING (auth.uid() = id);

-- 索引：Email 查詢優化
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);

-- 更新時間自動觸發器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 2. 註冊請求表格 (registration_requests)
-- ============================================
CREATE TABLE IF NOT EXISTS public.registration_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  name TEXT NOT NULL CHECK (length(name) >= 1 AND length(name) <= 50),
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  
  -- 約束：Email 格式驗證
  CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
  
  -- 約束：過期時間必須在建立時間之後
  CONSTRAINT valid_expiration CHECK (expires_at > created_at)
);

-- 索引：Email 查詢優化
CREATE INDEX idx_registration_requests_email 
  ON public.registration_requests(email);

-- 索引:過期清理優化
CREATE INDEX idx_registration_requests_expires 
  ON public.registration_requests(expires_at);

-- RLS 政策：僅透過 Service Role Key 存取
ALTER TABLE public.registration_requests ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. 驗證碼狀態列舉
-- ============================================
CREATE TYPE verification_status AS ENUM (
  'pending',    -- 等待驗證
  'verified',   -- 已驗證
  'locked',     -- 已鎖定 (失敗次數達上限)
  'expired'     -- 已過期
);

-- ============================================
-- 4. 驗證碼表格 (verification_codes)
-- ============================================
CREATE TABLE IF NOT EXISTS public.verification_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  code_hash TEXT NOT NULL,
  
  -- 嘗試追蹤欄位
  attempt_count INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 5,
  status verification_status NOT NULL DEFAULT 'pending',
  
  -- 時間戳記
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  locked_at TIMESTAMPTZ,
  verified_at TIMESTAMPTZ,
  
  -- Email 發送追蹤
  email_id TEXT,
  
  -- 約束：Email 格式驗證
  CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
  
  -- 約束：嘗試次數範圍
  CONSTRAINT attempt_count_check 
    CHECK (attempt_count >= 0 AND attempt_count <= max_attempts),
  
  -- 約束：過期時間必須在建立時間之後
  CONSTRAINT valid_expiration CHECK (expires_at > created_at),
  
  -- 約束:驗證成功時必須有 verified_at
  CONSTRAINT verified_at_required 
    CHECK (
      (status::text = 'verified' AND verified_at IS NOT NULL) OR
      (status::text != 'verified')
    )
);

-- 複合索引:快速查詢待驗證且未過期的驗證碼
CREATE INDEX idx_verification_codes_lookup 
  ON public.verification_codes(email, status, expires_at);

-- 索引:加速過期清理
CREATE INDEX idx_verification_codes_cleanup 
  ON public.verification_codes(created_at);

-- RLS 政策：僅透過 Service Role Key 存取
ALTER TABLE public.verification_codes ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 5. 清理函式與定時任務
-- ============================================

-- 標記過期的驗證碼
CREATE OR REPLACE FUNCTION mark_expired_verification_codes()
RETURNS void AS $$
BEGIN
  UPDATE public.verification_codes
  SET status = 'expired'
  WHERE status = 'pending'
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 清理過期的註冊請求
CREATE OR REPLACE FUNCTION cleanup_expired_registration_requests()
RETURNS void AS $$
BEGIN
  DELETE FROM public.registration_requests
  WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 清理已處理的驗證碼 (7 天前)
CREATE OR REPLACE FUNCTION cleanup_old_verification_codes()
RETURNS void AS $$
BEGIN
  DELETE FROM public.verification_codes
  WHERE status IN ('verified', 'expired', 'locked')
    AND created_at < NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 註解
COMMENT ON TABLE public.user_profiles IS '使用者個人資料（關聯到 auth.users）';
COMMENT ON TABLE public.registration_requests IS '註冊請求暫存表（30 分鐘有效期）';
COMMENT ON TABLE public.verification_codes IS 'Email 驗證碼表（5 分鐘有效期，5 次嘗試上限）';

COMMENT ON COLUMN public.verification_codes.attempt_count IS '當前失敗嘗試次數（成功後重設為 0）';
COMMENT ON COLUMN public.verification_codes.max_attempts IS '最大嘗試次數（預設 5 次）';
COMMENT ON COLUMN public.verification_codes.status IS '驗證碼狀態：pending（待驗證）、verified（已驗證）、locked（已鎖定）、expired（已過期）';
