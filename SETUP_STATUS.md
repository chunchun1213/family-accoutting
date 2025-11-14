# 開發環境設定狀態

**更新時間**: 2025-11-14  
**狀態**: 🟢 Phase 2 完成,準備開始 Phase 3 實作  
**開發進度**: Phase 1 ✅ | Phase 2 ✅ | Phase 3 (進行中)

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
- [x] **Hono basePath 設定** (關鍵修正)
  - 必須設定 `.basePath("/auth")` 才能正確匹配路由
  - 已解決 404 問題

---

## ✅ 本地開發環境已完成

### 7. 本地 Supabase 服務
- [x] Supabase 本地環境已啟動
  - API URL: http://127.0.0.1:54321
  - Database URL: postgresql://postgres:postgres@127.0.0.1:54322/postgres
  - Studio URL: http://127.0.0.1:54323
  - Mailpit URL: http://127.0.0.1:54324
- [x] 資料庫遷移已套用
  - user_profiles 表格
  - registration_requests 表格  
  - verification_codes 表格
- [x] Edge Function 基礎結構完成
  - auth/index.ts 已實作
  - 包含所有 API 端點 (register, verify-code, login, logout, me, resend-code, refresh-token)

### 8. 規格文件完成
- [x] tasks.md 已生成 (48 個任務)
- [x] analyze-01.md 已生成並修復所有問題
  - 需求覆蓋率: 100% (54/54)
  - 所有 CRITICAL/HIGH 問題已解決
- [x] spec.md 已更新
  - 新增 FR-049~054 (Token refresh, 驗證碼儲存等)
  - 新增 NFR-001~009 (非功能需求)
- [x] plan.md 已更新
  - API 端點清單已同步

### 9. Edge Function 部署與測試 ✅
- [x] 解決 Hono 404 問題
  - **根本原因**: Hono 在 Supabase Edge Functions 中必須設定 basePath
  - **解決方案**: `const app = new Hono().basePath("/auth")`
- [x] config.toml 設定
  - 本地開發設定 `verify_jwt = false`
- [x] 所有 API 端點測試通過
  - GET /auth - API 資訊
  - GET /auth/health - 健康檢查
  - POST /auth/register - 註冊 (含驗證)
  - POST /auth/verify-code - 驗證碼
  - POST /auth/login - 登入
  - POST /auth/resend-code - 重送驗證碼
  - POST /auth/refresh-token - 刷新 Token
  - GET /auth/me - 取得使用者資訊
  - POST /auth/logout - 登出

### 10. Phase 2 共用模組完成 ✅
- [x] 後端共用模組 (TypeScript)
  - types.ts - 完整型別定義
  - validators.ts - 輸入驗證器
  - email-service.ts - Resend Email 整合
  - db-helpers.ts - 資料庫輔助函式
- [x] 前端共用模組 (Dart)
  - validators.dart - 輸入驗證器 (中文錯誤訊息)
  - 所有驗證通過 flutter analyze

---

## 📝 待辦事項 (依優先順序)

### 高優先級 - 開始實作

#### 1. 提交當前變更到 Git
**狀態**: 準備就緒  
**包含檔案**:
- spec.md (新增需求)
- plan.md (更新 API 清單)
- tasks.md (48 個任務)
- analyze-01.md (分析報告)
- auth/index.ts (Edge Function 更新)

**建議提交訊息**:
```
feat: 完成本地開發環境設定與 Edge Function 實作

## 規格與分析
- 新增 FR-049~054 (Token refresh, 驗證碼儲存等)
- 新增 NFR-001~009 (安全性、錯誤處理、效能需求)
- 更新 API 端點清單 (plan.md)
- 修正 tasks.md 依賴關係
- 生成完整分析報告 analyze-01.md
- 需求覆蓋率: 91.7% → 100%

## Edge Function 實作
- 實作所有 7 個 API 端點骨架
- 修正 Hono basePath 設定 (關鍵修正)
- 設定 config.toml verify_jwt = false (本地開發)
- 整合 _shared 模組 (validators, db-helpers, email-service)
- 所有端點測試通過 ✅

## 測試結果
- GET /auth - API 資訊 ✅
- GET /auth/health - 健康檢查 ✅  
- POST /auth/register - 註冊 ✅
- POST /auth/verify-code - 驗證 ✅
- POST /auth/login - 登入 ✅
- POST /auth/resend-code - 重送驗證碼 ✅
- POST /auth/refresh-token - 刷新 Token ✅
- GET /auth/me - 取得使用者 ✅
- POST /auth/logout - 登出 ✅

狀態: 本地環境完全就緒,可開始實作業務邏輯
```

---

### 中優先級 - 生產環境部署 (可選)

#### 3. 建立 Supabase 雲端專案
**狀態**: 未開始  
**用途**: 生產環境部署、團隊協作

**步驟**:
1. 前往 https://supabase.com/
2. 建立新專案 (建議 Singapore region)
3. 取得金鑰: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
4. 連結本地專案: `supabase link --project-ref <your-project-id>`
5. 推送遷移: `supabase db push`
6. 部署 Edge Functions: `supabase functions deploy auth`

#### 4. 註冊 Resend Email 服務
**狀態**: 未開始  
**用途**: 發送驗證碼 Email

**步驟**:
1. 前往 https://resend.com/
2. 註冊並取得 API Key
3. 設定環境變數:
   ```bash
   supabase secrets set RESEND_API_KEY=re_your_api_key
   supabase secrets set VERIFICATION_EMAIL_FROM="Family Accounting <noreply@yourdomain.com>"
   ```

---

### 低優先級 - 優化項目

#### 5. 升級 Supabase CLI
**當前版本**: v2.54.11  
**最新版本**: v2.58.5  
**指令**: `brew upgrade supabase`

#### 6. 設定 Resend Email 模板
**用途**: 美化驗證碼 Email
**參考**: `.specify/specs/1-auth-home/contracts/auth-api.yaml`

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
