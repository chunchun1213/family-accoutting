# 資料模型：會員註冊與登入系統

**分支**: `1-auth-home` | **日期**: 2025-11-14  
**基於**: [research.md](./research.md) - Part D & Part F

---

## 目錄

1. [資料庫概述](#資料庫概述)
2. [核心實體](#核心實體)
3. [實體關係圖](#實體關係圖)
4. [資料表結構](#資料表結構)
5. [索引策略](#索引策略)
6. [狀態轉換](#狀態轉換)
7. [資料完整性規則](#資料完整性規則)
8. [清理策略](#清理策略)

---

## 資料庫概述

### 技術棧
- **資料庫**: PostgreSQL 15+ (Supabase)
- **ORM**: Supabase Client (JavaScript/Dart)
- **遷移工具**: Supabase Migrations

### 設計原則
1. **最小化信任原則**: 驗證前資料暫存在 `public` schema，驗證後才建立 Supabase Auth 使用者
2. **並發安全**: 使用 `SELECT FOR UPDATE` 處理驗證碼嘗試計數
3. **自動清理**: 使用 PostgreSQL 函式與 pg_cron 定期清理過期資料
4. **稽核追蹤**: 所有表格包含時間戳記欄位（`created_at`, `updated_at`）

---

## 核心實體

### 1. User (使用者) - Supabase Auth

**用途**: 已驗證的應用程式使用者帳號

**管理方式**: 
- 由 Supabase Auth 管理（`auth.users` 表格）
- 透過 Admin API 建立（`supabase.auth.admin.createUser()`）

**主要欄位**:
```typescript
interface User {
  id: string;                    // UUID, Supabase Auth 產生
  email: string;                 // 唯一，已驗證
  email_confirmed_at: Date;      // Email 確認時間（建立時直接設為當前時間）
  created_at: Date;              // 帳號建立時間
  last_sign_in_at: Date | null;  // 最後登入時間
  // encrypted_password: string; // bcrypt hash, Supabase Auth 內部管理
}
```

**擴充資料** (儲存於 `public.user_profiles`):
```typescript
interface UserProfile {
  user_id: string;               // FK to auth.users.id
  name: string;                  // 使用者姓名 (最多 50 字元)
  created_at: Date;
  updated_at: Date;
}
```

---

### 2. RegistrationRequest (註冊請求)

**用途**: 驗證前暫存使用者註冊資料

**生命週期**: 
- 建立：使用者提交註冊表單
- 刪除：驗證成功建立 Supabase Auth 使用者後，或 30 分鐘後自動過期

**欄位**:
```typescript
interface RegistrationRequest {
  id: string;                    // UUID, PRIMARY KEY
  email: string;                 // UNIQUE, 註冊 Email
  name: string;                  // 使用者姓名
  password_hash: string;         // bcrypt hash (cost factor 10)
  created_at: Date;              // 建立時間
  expires_at: Date;              // 過期時間 (created_at + 30 分鐘)
}
```

**驗證規則**:
- Email: 必須符合標準格式，統一轉換為小寫
- Name: 1-50 字元，支援中英文與常見符號
- password_hash: 儲存 bcrypt hash，原始密碼規則為 8-20 碼（大小寫字母 + 數字）

---

### 3. VerificationCode (驗證碼)

**用途**: Email 驗證碼管理與失敗嘗試追蹤

**生命週期**:
- 建立：發送驗證碼時
- 鎖定：5 次錯誤嘗試後
- 標記為已使用：驗證成功後
- 刪除：驗證成功後或過期 24 小時後自動清理

**欄位**:
```typescript
enum VerificationStatus {
  PENDING = 'pending',           // 待驗證
  VERIFIED = 'verified',         // 已驗證
  LOCKED = 'locked',             // 已鎖定（5 次失敗）
  EXPIRED = 'expired'            // 已過期（超過 5 分鐘）
}

interface VerificationCode {
  id: string;                    // UUID, PRIMARY KEY
  email: string;                 // 關聯的 Email (FK to registration_requests.email)
  code: string;                  // 6 位數驗證碼 (bcrypt hash 儲存)
  attempt_count: number;         // 錯誤嘗試次數 (0-5)
  max_attempts: number;          // 最大嘗試次數 (固定 5)
  status: VerificationStatus;    // 驗證碼狀態
  created_at: Date;              // 建立時間
  expires_at: Date;              // 過期時間 (created_at + 5 分鐘)
  verified_at: Date | null;      // 驗證成功時間
  last_attempt_at: Date | null;  // 最後嘗試時間
}
```

**驗證規則**:
- 每個 Email 同時僅能有一個 `status = 'pending'` 的驗證碼（UNIQUE 約束）
- 驗證碼儲存為 bcrypt hash（防止資料庫洩漏時直接使用）
- 錯誤嘗試達 5 次時自動將 `status` 設為 `'locked'`

---

### 4. Session (會話) - Supabase Auth

**用途**: 使用者登入會話管理

**管理方式**:
- 由 Supabase Auth 管理（JWT token + refresh token）
- 前端使用 `flutter_secure_storage` 儲存 access token

**主要欄位** (Supabase Auth 內建):
```typescript
interface Session {
  access_token: string;          // JWT token
  refresh_token: string;         // 用於刷新 access token
  expires_in: number;            // Token 有效秒數
  expires_at: number;            // Token 過期時間戳記
  user: User;                    // 使用者資訊
}
```

**本地儲存格式** (flutter_secure_storage):
```dart
class SessionData {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String userId;
  final int version;             // 版本控制 (目前 1)
  
  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toIso8601String(),
    'user_id': userId,
    'version': version,
  };
}
```

**會話策略**:
- Access token 有效期: 1 小時
- Refresh token 有效期: 30 天
- 自動刷新: 前端在 access token 過期前 5 分鐘自動刷新

---

## 實體關係圖

```
┌─────────────────────────┐
│  auth.users             │
│  (Supabase Auth)        │
├─────────────────────────┤
│ • id (PK)               │
│ • email (UNIQUE)        │
│ • email_confirmed_at    │
│ • created_at            │
│ • last_sign_in_at       │
└───────────┬─────────────┘
            │ 1
            │
            │ 1
            │
┌───────────▼─────────────┐
│  public.user_profiles   │
├─────────────────────────┤
│ • user_id (PK, FK)      │
│ • name                  │
│ • created_at            │
│ • updated_at            │
└─────────────────────────┘


┌──────────────────────────┐
│  public.registration_    │
│  requests                │
├──────────────────────────┤
│ • id (PK)                │
│ • email (UNIQUE)         │
│ • name                   │
│ • password_hash          │
│ • created_at             │
│ • expires_at             │
└────────────┬─────────────┘
             │ 1
             │
             │ 1..*
             │
┌────────────▼─────────────┐
│  public.verification_    │
│  codes                   │
├──────────────────────────┤
│ • id (PK)                │
│ • email (FK)             │
│ • code (bcrypt hash)     │
│ • attempt_count          │
│ • max_attempts           │
│ • status                 │
│ • created_at             │
│ • expires_at             │
│ • verified_at            │
│ • last_attempt_at        │
└──────────────────────────┘
```

**關聯說明**:
- `user_profiles.user_id` → `auth.users.id` (1:1, CASCADE DELETE)
- `verification_codes.email` → `registration_requests.email` (1:N, NO ACTION)
  - 一個註冊請求可能產生多個驗證碼（重新發送）
  - 驗證碼不強制關聯完整性（允許孤立驗證碼以便稽核）

---

## 資料表結構

### DDL: public.user_profiles

```sql
CREATE TABLE public.user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(50) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS 政策：僅使用者本人可讀寫
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON public.user_profiles
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON public.user_profiles
  FOR UPDATE
  USING (auth.uid() = user_id);

-- 觸發器：自動更新 updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

### DDL: public.registration_requests

```sql
CREATE TABLE public.registration_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  name VARCHAR(50) NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '30 minutes')
);

-- 索引：加速 email 查詢與過期清理
CREATE INDEX idx_registration_requests_email 
  ON public.registration_requests(email);
  
CREATE INDEX idx_registration_requests_expires_at 
  ON public.registration_requests(expires_at) 
  WHERE expires_at > now();

-- RLS 政策：僅透過 Service Role Key 存取（Edge Functions）
ALTER TABLE public.registration_requests ENABLE ROW LEVEL SECURITY;
-- 不建立任何政策，僅允許 service_role 存取

-- 約束：Email 格式驗證
ALTER TABLE public.registration_requests
  ADD CONSTRAINT email_format_check 
  CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- 約束：姓名長度
ALTER TABLE public.registration_requests
  ADD CONSTRAINT name_length_check 
  CHECK (char_length(name) BETWEEN 1 AND 50);
```

---

### DDL: public.verification_codes

```sql
-- 驗證碼狀態列舉
CREATE TYPE verification_status AS ENUM (
  'pending',
  'verified',
  'locked',
  'expired'
);

CREATE TABLE public.verification_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  code TEXT NOT NULL,  -- bcrypt hash
  attempt_count INT NOT NULL DEFAULT 0,
  max_attempts INT NOT NULL DEFAULT 5,
  status verification_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '5 minutes'),
  verified_at TIMESTAMPTZ,
  last_attempt_at TIMESTAMPTZ,
  
  -- 約束：每個 email 僅能有一個 pending 驗證碼
  CONSTRAINT unique_pending_code_per_email 
    UNIQUE (email, status) 
    WHERE status = 'pending'
);

-- 複合索引：快速查詢待驗證且未過期的驗證碼
CREATE INDEX idx_verification_codes_lookup 
  ON public.verification_codes(email, status, expires_at)
  WHERE status = 'pending';

-- 索引：加速過期清理
CREATE INDEX idx_verification_codes_cleanup 
  ON public.verification_codes(created_at)
  WHERE status IN ('verified', 'expired', 'locked');

-- RLS 政策：僅透過 Service Role Key 存取
ALTER TABLE public.verification_codes ENABLE ROW LEVEL SECURITY;

-- 約束：嘗試次數不超過上限
ALTER TABLE public.verification_codes
  ADD CONSTRAINT attempt_count_check 
  CHECK (attempt_count >= 0 AND attempt_count <= max_attempts);

-- 約束：驗證成功時必須有 verified_at
ALTER TABLE public.verification_codes
  ADD CONSTRAINT verified_at_required 
  CHECK (
    (status = 'verified' AND verified_at IS NOT NULL) OR
    (status != 'verified')
  );
```

---

## 索引策略

### 查詢優化

| 表格 | 索引 | 用途 | 預期影響 |
|------|------|------|---------|
| `registration_requests` | `email` | 檢查 Email 是否已註冊 | 查詢時間 < 10ms |
| `registration_requests` | `expires_at` (WHERE > now()) | 定期清理過期記錄 | 批次刪除 < 100ms |
| `verification_codes` | `(email, status, expires_at)` | 查詢有效驗證碼 | 查詢時間 < 5ms |
| `verification_codes` | `created_at` (WHERE status IN ...) | 清理已處理的驗證碼 | 批次刪除 < 50ms |

### 索引維護

- **VACUUM**: 每日自動執行（Supabase 預設）
- **ANALYZE**: 每週執行以更新統計資訊
- **REINDEX**: 無需手動執行（B-tree 索引自動平衡）

---

## 狀態轉換

### VerificationCode 狀態機

```
          ┌─────────┐
          │ PENDING │ ← 初始狀態（發送驗證碼）
          └────┬────┘
               │
       ┌───────┼───────┐
       │       │       │
       │       │       │ (attempt_count < 5 && expires_at > now())
       │       │       │
   超過 5     驗證     超過 5
   分鐘      成功      次失敗
       │       │       │
       │       │       │
       ▼       ▼       ▼
  ┌─────────┐ ┌─────────┐ ┌─────────┐
  │ EXPIRED │ │VERIFIED │ │ LOCKED  │ ← 終止狀態
  └─────────┘ └─────────┘ └─────────┘
```

**狀態轉換規則**:
1. `PENDING` → `VERIFIED`: 使用者輸入正確驗證碼且未過期
2. `PENDING` → `LOCKED`: 錯誤嘗試達 5 次
3. `PENDING` → `EXPIRED`: 超過 5 分鐘（由定時任務標記）
4. **不可逆**: 一旦進入終止狀態，無法再轉換

### RegistrationRequest 生命週期

```
使用者提交註冊
       │
       ▼
  建立 RegistrationRequest
  (expires_at = now() + 30分鐘)
       │
       ├─────────────┐
       │             │
   驗證成功       30分鐘後
       │             │
       ▼             ▼
  建立 auth.users  自動刪除
  & user_profiles  (pg_cron)
       │
       ▼
  刪除 RegistrationRequest
```

---

## 資料完整性規則

### 應用層驗證

**前端 (Flutter)**:
```dart
// lib/core/utils/validators.dart
class Validators {
  static String? email(String? value) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    if (value == null || !emailRegex.hasMatch(value)) {
      return 'Email 格式不正確';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 8 || value.length > 20) {
      return '密碼必須為 8-20 碼';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return '密碼必須包含至少一個大寫字母';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return '密碼必須包含至少一個小寫字母';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return '密碼必須包含至少一個數字';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '姓名不可為空';
    }
    if (value.length > 50) {
      return '姓名不可超過 50 字元';
    }
    return null;
  }

  static String? verificationCode(String? value) {
    if (value == null || !RegExp(r'^\d{6}$').hasMatch(value)) {
      return '驗證碼必須為 6 位數字';
    }
    return null;
  }
}
```

**後端 (Supabase Edge Functions)**:
```typescript
// supabase/functions/_shared/validators.ts
import { z } from 'zod';

export const RegisterSchema = z.object({
  email: z.string().email().toLowerCase(),
  name: z.string().min(1).max(50),
  password: z.string()
    .min(8)
    .max(20)
    .regex(/[A-Z]/, '必須包含大寫字母')
    .regex(/[a-z]/, '必須包含小寫字母')
    .regex(/[0-9]/, '必須包含數字'),
});

export const VerifyCodeSchema = z.object({
  email: z.string().email().toLowerCase(),
  code: z.string().regex(/^\d{6}$/, '驗證碼必須為 6 位數字'),
});
```

### 資料庫約束

- ✅ PRIMARY KEY 約束確保唯一性
- ✅ FOREIGN KEY 約束確保關聯完整性
- ✅ CHECK 約束驗證資料格式
- ✅ UNIQUE 約束防止重複
- ✅ NOT NULL 約束確保必填欄位

---

## 清理策略

### 自動清理函式

```sql
-- 標記過期的驗證碼
CREATE OR REPLACE FUNCTION mark_expired_verification_codes()
RETURNS void AS $$
BEGIN
  UPDATE public.verification_codes
  SET status = 'expired'
  WHERE status = 'pending'
    AND expires_at < now();
END;
$$ LANGUAGE plpgsql;

-- 刪除過期的註冊請求
CREATE OR REPLACE FUNCTION cleanup_expired_registration_requests()
RETURNS void AS $$
BEGIN
  DELETE FROM public.registration_requests
  WHERE expires_at < now();
END;
$$ LANGUAGE plpgsql;

-- 刪除舊的驗證碼記錄（保留 7 天以供稽核）
CREATE OR REPLACE FUNCTION cleanup_old_verification_codes()
RETURNS void AS $$
BEGIN
  DELETE FROM public.verification_codes
  WHERE status IN ('verified', 'expired', 'locked')
    AND created_at < now() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;
```

### pg_cron 排程

```sql
-- 安裝 pg_cron 擴充功能（需要 Supabase Pro 方案）
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 每 5 分鐘標記過期的驗證碼
SELECT cron.schedule(
  'mark-expired-codes',
  '*/5 * * * *',  -- 每 5 分鐘
  'SELECT mark_expired_verification_codes();'
);

-- 每小時清理過期的註冊請求
SELECT cron.schedule(
  'cleanup-expired-registrations',
  '0 * * * *',  -- 每小時
  'SELECT cleanup_expired_registration_requests();'
);

-- 每日凌晨 2 點清理舊的驗證碼
SELECT cron.schedule(
  'cleanup-old-codes',
  '0 2 * * *',  -- 每日 02:00
  'SELECT cleanup_old_verification_codes();'
);
```

**替代方案** (若無 pg_cron):
- 使用 Supabase Database Webhooks 觸發 Edge Function 執行清理
- 在應用程式啟動時執行清理邏輯（不建議，效率較低）

---

## 遷移腳本

### Migration: 20251114000001_create_auth_tables.sql

```sql
-- 建立使用者擴充資料表
CREATE TABLE public.user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(50) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON public.user_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON public.user_profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- 觸發器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 建立註冊請求表
CREATE TABLE public.registration_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  name VARCHAR(50) NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '30 minutes'),
  
  CONSTRAINT email_format_check 
    CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  CONSTRAINT name_length_check 
    CHECK (char_length(name) BETWEEN 1 AND 50)
);

CREATE INDEX idx_registration_requests_email 
  ON public.registration_requests(email);
  
CREATE INDEX idx_registration_requests_expires_at 
  ON public.registration_requests(expires_at) 
  WHERE expires_at > now();

ALTER TABLE public.registration_requests ENABLE ROW LEVEL SECURITY;

-- 建立驗證碼表
CREATE TYPE verification_status AS ENUM (
  'pending', 'verified', 'locked', 'expired'
);

CREATE TABLE public.verification_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  attempt_count INT NOT NULL DEFAULT 0,
  max_attempts INT NOT NULL DEFAULT 5,
  status verification_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '5 minutes'),
  verified_at TIMESTAMPTZ,
  last_attempt_at TIMESTAMPTZ,
  
  CONSTRAINT unique_pending_code_per_email 
    UNIQUE (email, status) WHERE status = 'pending',
  CONSTRAINT attempt_count_check 
    CHECK (attempt_count >= 0 AND attempt_count <= max_attempts),
  CONSTRAINT verified_at_required 
    CHECK (
      (status = 'verified' AND verified_at IS NOT NULL) OR
      (status != 'verified')
    )
);

CREATE INDEX idx_verification_codes_lookup 
  ON public.verification_codes(email, status, expires_at)
  WHERE status = 'pending';

CREATE INDEX idx_verification_codes_cleanup 
  ON public.verification_codes(created_at)
  WHERE status IN ('verified', 'expired', 'locked');

ALTER TABLE public.verification_codes ENABLE ROW LEVEL SECURITY;

-- 清理函式
CREATE OR REPLACE FUNCTION mark_expired_verification_codes()
RETURNS void AS $$
BEGIN
  UPDATE public.verification_codes
  SET status = 'expired'
  WHERE status = 'pending' AND expires_at < now();
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_expired_registration_requests()
RETURNS void AS $$
BEGIN
  DELETE FROM public.registration_requests WHERE expires_at < now();
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_old_verification_codes()
RETURNS void AS $$
BEGIN
  DELETE FROM public.verification_codes
  WHERE status IN ('verified', 'expired', 'locked')
    AND created_at < now() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;
```

---

## 資料字典

### public.user_profiles

| 欄位 | 型別 | 約束 | 說明 |
|------|------|------|------|
| user_id | UUID | PK, FK | 關聯到 auth.users.id |
| name | VARCHAR(50) | NOT NULL | 使用者姓名 |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | 建立時間 |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | 更新時間（觸發器自動維護） |

### public.registration_requests

| 欄位 | 型別 | 約束 | 說明 |
|------|------|------|------|
| id | UUID | PK | 註冊請求 ID |
| email | TEXT | UNIQUE, NOT NULL | 註冊 Email（小寫） |
| name | VARCHAR(50) | NOT NULL | 使用者姓名 |
| password_hash | TEXT | NOT NULL | bcrypt hash (cost 10) |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | 建立時間 |
| expires_at | TIMESTAMPTZ | NOT NULL, DEFAULT +30min | 過期時間 |

### public.verification_codes

| 欄位 | 型別 | 約束 | 說明 |
|------|------|------|------|
| id | UUID | PK | 驗證碼 ID |
| email | TEXT | NOT NULL | 關聯的 Email |
| code | TEXT | NOT NULL | 驗證碼 bcrypt hash |
| attempt_count | INT | NOT NULL, DEFAULT 0 | 錯誤嘗試次數 (0-5) |
| max_attempts | INT | NOT NULL, DEFAULT 5 | 最大嘗試次數 |
| status | verification_status | NOT NULL, DEFAULT 'pending' | 狀態 |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | 建立時間 |
| expires_at | TIMESTAMPTZ | NOT NULL, DEFAULT +5min | 過期時間 |
| verified_at | TIMESTAMPTZ | NULL | 驗證成功時間 |
| last_attempt_at | TIMESTAMPTZ | NULL | 最後嘗試時間 |

---

**文件版本**: 1.0  
**最後更新**: 2025-11-14  
**維護者**: GitHub Copilot
