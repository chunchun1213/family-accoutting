# 開發環境設定狀態

**更新時間**: 2025-11-14

## ✅ 已完成設定

### 1. 開發工具安裝
- [x] Flutter SDK 3.35.7 (Dart 3.9.2)
- [x] Android Studio & Xcode
- [x] Supabase CLI 2.54.11
- [x] Deno 2.5.6
- [x] Node.js 22.21.0

### 2. 專案結構初始化
- [x] Flutter 專案建立
- [x] Supabase 專案初始化
- [x] 目錄結構建立
  - `lib/core/config/` - Flutter 配置
  - `supabase/functions/auth/` - 認證 Edge Function
  - `supabase/functions/_shared/` - 共用模組
  - `supabase/migrations/` - 資料庫遷移

### 3. 相依套件配置
- [x] pubspec.yaml 已更新（包含所有必要套件）
  - flutter_riverpod 2.6.1
  - supabase_flutter 2.10.3
  - flutter_secure_storage 9.2.4
  - go_router 13.2.5
  - freezed & json_serializable
  - 測試工具 (mockito, integration_test)

### 4. 環境變數檔案
- [x] `.env.example` 建立
- [x] `.env` 建立（待填入實際值）
- [x] `.gitignore` 更新（排除敏感檔案）

### 5. 資料庫遷移
- [x] `20251114014634_create_auth_tables.sql` 建立
  - user_profiles 表格
  - registration_requests 表格
  - verification_codes 表格（含狀態列舉）
  - 索引與約束
  - 清理函式

### 6. Edge Function 基礎結構
- [x] `auth/index.ts` 建立（Hono 框架）
- [x] `_shared/types.ts` 建立（型別定義）

---

## ⚠️ 待完成步驟

### 步驟 1: 建立 Supabase 雲端專案
1. 前往 https://supabase.com/
2. 建立新專案（選擇 Singapore region）
3. 取得以下金鑰：
   ```
   Settings → API
   - Project URL (SUPABASE_URL)
   - anon/public (SUPABASE_ANON_KEY)
   - service_role (SUPABASE_SERVICE_ROLE_KEY)
   ```

### 步驟 2: 更新環境變數
編輯 `lib/core/config/.env`:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
API_BASE_URL=https://your-project-id.supabase.co/functions/v1
ENVIRONMENT=development
```

### 步驟 3: 連結本地專案到雲端
```bash
supabase login
supabase link --project-ref <your-project-id>
```

### 步驟 4: 推送資料庫遷移
```bash
supabase db push
```

### 步驟 5: 部署 Edge Functions
```bash
supabase functions deploy auth
```

### 步驟 6: 註冊 Resend Email 服務
1. 前往 https://resend.com/
2. 註冊帳號並取得 API Key
3. 設定環境變數：
```bash
supabase secrets set RESEND_API_KEY=re_your_api_key
supabase secrets set VERIFICATION_EMAIL_FROM="Family Accounting <noreply@yourdomain.com>"
```

### 步驟 7: 啟動本地開發環境
```bash
# 啟動 Supabase 本地服務
supabase start

# 啟動 Flutter 應用程式
flutter run
```

---

## 📚 參考文件

- [quickstart.md](.specify/specs/1-auth-home/quickstart.md) - 完整開發指南
- [data-model.md](.specify/specs/1-auth-home/data-model.md) - 資料庫設計
- [auth-api.yaml](.specify/specs/1-auth-home/contracts/auth-api.yaml) - API 規格
- [research.md](.specify/specs/1-auth-home/research.md) - 技術研究

---

## 🔄 可選更新

```bash
# 更新 Supabase CLI
brew upgrade supabase

# 更新 Flutter
flutter upgrade

# 檢查套件更新
flutter pub outdated
```

---

## ❓ 常見問題

### Q: 如何檢查環境是否正確設定？
```bash
flutter doctor
supabase --version
deno --version
```

### Q: 如何重設本地 Supabase？
```bash
supabase db reset
```

### Q: 如何查看 Edge Function 日誌？
```bash
supabase functions logs auth
```

---

**下一步**: 完成「待完成步驟」後，即可開始實作認證功能。
