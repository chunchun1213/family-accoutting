# 任務清單：會員註冊與登入系統

**功能分支**: `1-auth-home`  
**更新日期**: 2025-11-14  
**總任務數**: 47 個任務

---

## 📋 任務概覽

### 進度統計
- [ ] **Phase 1: 專案設定與基礎建設** (6 個任務)
- [ ] **Phase 2: 共用模組與類型定義** (5 個任務)
- [ ] **Phase 3: User Story 1 - 會員註冊與 Email 驗證 [P1]** (9 個任務)
- [ ] **Phase 4: User Story 3 - 使用者登入 [P1]** (7 個任務)
- [ ] **Phase 5: User Story 2 - 重新發送驗證碼 [P2]** (4 個任務)
- [ ] **Phase 6: User Story 4 - 使用者登出 [P2]** (4 個任務)
- [ ] **Phase 7: User Story 5 - 記帳主頁 [P3]** (3 個任務)
- [ ] **Phase 8: 跨切面功能與優化** (9 個任務)

---

## 依賴關係圖

```
Phase 1 (設定) 
    ↓
Phase 2 (共用模組)
    ↓
Phase 3 (註冊 US1) ←→ Phase 4 (登入 US3)  [P1 - MVP]
    ↓                       ↓
Phase 5 (重發 US2)      Phase 6 (登出 US4)  [P2]
    ↓                       ↓
Phase 7 (主頁 US5)  [P3]
    ↓
Phase 8 (優化)
```

**平行開發建議**:
- Phase 3 和 Phase 4 可同時開發（前端 UI、後端 API）
- Phase 5 和 Phase 6 可同時開發

---

## Phase 1: 專案設定與基礎建設

### 環境設定與配置
- [ ] [T001] [P] 設定 Supabase 專案與環境變數  
  - 檔案: `supabase/.env`, `lib/core/config/.env`  
  - 內容: 配置 `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `RESEND_API_KEY`

- [ ] [T002] [P] 執行資料庫遷移  
  - 檔案: `supabase/migrations/20251114014634_create_auth_tables.sql`  
  - 指令: `supabase db push`  
  - 驗證: 確認 `user_profiles`, `registration_requests`, `verification_codes` 資料表已建立

- [ ] [T003] 初始化 Flutter Supabase 用戶端  
  - 檔案: `lib/core/config/supabase_config.dart`  
  - 內容: 實作 `SupabaseConfig.initialize()`, 使用 `flutter_dotenv` 載入環境變數

- [ ] [T004] [P] 設定 flutter_secure_storage  
  - 檔案: `lib/data/datasources/session_local_datasource.dart`  
  - 內容: 封裝 token 儲存/讀取/刪除方法

- [ ] [T005] [P] 設定 go_router 路由  
  - 檔案: `lib/core/router/app_router.dart`  
  - 內容: 定義路由: `/login`, `/register`, `/verify-email`, `/home`

- [ ] [T006] 建立應用程式常數  
  - 檔案: `lib/core/constants/app_constants.dart`  
  - 內容: API 端點、驗證碼規則 (5 分鐘有效期、5 次嘗試上限、60 秒冷卻)

---

## Phase 2: 共用模組與類型定義

### 後端共用模組
- [ ] [T007] [P] 實作 TypeScript 類型定義  
  - 檔案: `supabase/functions/_shared/types.ts`  
  - 內容: 所有 API request/response 介面、資料庫實體型別、錯誤碼常數 (已完成,需驗證)

- [ ] [T008] [P] 實作輸入驗證器 (TypeScript)  
  - 檔案: `supabase/functions/_shared/validators.ts`  
  - 內容: Email、密碼 (8-20 碼、大小寫+數字)、姓名 (1-50 字元)、驗證碼 (6 位數字) 驗證

- [ ] [T009] 實作 Email 服務模組  
  - 檔案: `supabase/functions/_shared/email-service.ts`  
  - 內容: 使用 Resend API 發送驗證碼 Email, 範本支援 HTML 格式
  - 依賴: [T001] (RESEND_API_KEY)

- [ ] [T010] [P] 實作資料庫輔助函式  
  - 檔案: `supabase/functions/_shared/db-helpers.ts`  
  - 內容: 產生 6 位數驗證碼、bcrypt hash/compare、SELECT FOR UPDATE 查詢輔助

### 前端共用模組
- [ ] [T011] [P] 實作輸入驗證器 (Dart)  
  - 檔案: `lib/core/utils/validators.dart`  
  - 內容: Email、密碼、姓名、驗證碼驗證, 回傳中文錯誤訊息

---

## Phase 3: User Story 1 - 會員註冊與 Email 驗證 [P1]

### 後端 API (Edge Functions)
- [ ] [T012] [US1] [P1] 實作 POST /auth/register 端點  
  - 檔案: `supabase/functions/auth/index.ts`  
  - 業務邏輯:
    1. 驗證 Email 格式與密碼強度
    2. 檢查 Email 是否已在 auth.users 或 registration_requests
    3. 建立 registration_request 記錄 (密碼 bcrypt hash)
    4. 產生 6 位數驗證碼並儲存 bcrypt hash
    5. 透過 Resend API 發送驗證碼
  - 錯誤處理: EMAIL_EXISTS (400), INVALID_EMAIL (400), INVALID_PASSWORD (400), EMAIL_SEND_FAILED (503)
  - 依賴: [T008], [T009], [T010]

- [ ] [T013] [US1] [P1] 實作 POST /auth/verify-code 端點  
  - 檔案: `supabase/functions/auth/index.ts`  
  - 業務邏輯:
    1. SELECT FOR UPDATE 鎖定驗證碼記錄
    2. 檢查狀態 (pending/locked/expired)
    3. 驗證驗證碼 (bcrypt.compare)
    4. 錯誤則增加 attempt_count, 5 次鎖定
    5. 正確則建立 Supabase Auth 使用者
    6. 建立 user_profile 記錄
    7. 刪除 registration_request 與 verification_code
    8. 產生 JWT token
  - 錯誤處理: INVALID_CODE (400 + 剩餘次數), CODE_EXPIRED (400), CODE_LOCKED (403), CODE_NOT_FOUND (404)
  - 依賴: [T010], [T012]

### 前端資料層 (Data Layer)
- [ ] [T014] [US1] [P1] 建立 API 回應模型  
  - 檔案: `lib/data/models/api_response_model.dart`  
  - 內容: `RegisterResponse`, `VerifyCodeResponse` 使用 `freezed` 與 `json_serializable`

- [ ] [T015] [US1] [P1] 實作註冊 API 呼叫  
  - 檔案: `lib/data/datasources/auth_remote_datasource.dart`  
  - 方法: `registerUser(email, name, password)`, `verifyCode(email, code)`
  - 依賴: [T003]

- [ ] [T016] [US1] [P1] 實作 AuthRepository 介面實作  
  - 檔案: `lib/data/repositories/auth_repository_impl.dart`  
  - 方法: `register()`, `verifyCode()`
  - 錯誤處理: 將 API 錯誤碼轉換為領域層例外

### 前端領域層 (Domain Layer)
- [ ] [T017] [US1] [P1] 建立 Use Cases  
  - 檔案: `lib/domain/usecases/register_usecase.dart`, `lib/domain/usecases/verify_code_usecase.dart`  
  - 內容: 呼叫 repository 方法, 回傳 `Either<Failure, Success>`

### 前端展示層 (Presentation Layer)
- [ ] [T018] [US1] [P1] 建立註冊狀態管理  
  - 檔案: `lib/presentation/providers/registration_provider.dart`  
  - 內容: 使用 `StateNotifier` 管理註冊流程狀態 (idle/loading/success/error)
  - 依賴: [T017]

- [ ] [T019] [US1] [P1] 實作註冊頁面 UI  
  - 檔案: `lib/presentation/pages/registration_page.dart`  
  - 欄位: Email, 姓名, 密碼 (即時驗證), 錯誤訊息顯示
  - 依賴: [T011], [T018]

- [ ] [T020] [US1] [P1] 實作 Email 驗證頁面 UI  
  - 檔案: `lib/presentation/pages/email_verification_page.dart`  
  - 功能: 6 位數驗證碼輸入, 倒數計時顯示 (5 分鐘), 剩餘嘗試次數, 重新發送連結 (60 秒冷卻)
  - 依賴: [T018]

---

## Phase 4: User Story 3 - 使用者登入 [P1]

### 後端 API (Edge Functions)
- [ ] [T021] [US3] [P1] 實作 POST /auth/login 端點  
  - 檔案: `supabase/functions/auth/index.ts`  
  - 業務邏輯:
    1. 驗證 Email 與密碼格式
    2. 呼叫 Supabase Auth `signInWithPassword`
    3. 回傳 session (access token + refresh token)
  - 錯誤處理: INVALID_CREDENTIALS (401), EMAIL_NOT_VERIFIED (403), ACCOUNT_LOCKED (403)
  - 依賴: [T008]

- [ ] [T022] [US3] [P1] 實作 GET /auth/me 端點  
  - 檔案: `supabase/functions/auth/index.ts`  
  - 業務邏輯:
    1. 驗證 Authorization header 中的 access token
    2. 從 JWT payload 取得 user_id
    3. 查詢 auth.users 與 user_profiles
    4. 回傳使用者資訊 (不含密碼)
  - 錯誤處理: UNAUTHORIZED (401)

### 前端資料層 (Data Layer)
- [ ] [T023] [US3] [P1] 建立登入 API 回應模型  
  - 檔案: `lib/data/models/api_response_model.dart`  
  - 內容: `LoginResponse`, `UserInfoResponse`

- [ ] [T024] [US3] [P1] 實作登入 API 呼叫  
  - 檔案: `lib/data/datasources/auth_remote_datasource.dart`  
  - 方法: `loginUser(email, password)`, `getCurrentUser(accessToken)`

- [ ] [T025] [US3] [P1] 實作 Session 本地儲存  
  - 檔案: `lib/data/datasources/session_local_datasource.dart`  
  - 方法: `saveSession(accessToken, refreshToken)`, `getSession()`, `clearSession()`
  - 依賴: [T004]

### 前端領域層 (Domain Layer)
- [ ] [T026] [US3] [P1] 建立登入 Use Case  
  - 檔案: `lib/domain/usecases/login_usecase.dart`  
  - 內容: 呼叫 login API, 儲存 session 到本地

### 前端展示層 (Presentation Layer)
- [ ] [T027] [US3] [P1] 建立認證狀態管理  
  - 檔案: `lib/presentation/providers/auth_provider.dart`  
  - 內容: 使用 `StateNotifier` 管理登入狀態 (authenticated/unauthenticated), 自動登入邏輯
  - 依賴: [T026], [T025]

- [ ] [T028] [US3] [P1] 實作登入頁面 UI  
  - 檔案: `lib/presentation/pages/login_page.dart`  
  - 欄位: Email, 密碼, 錯誤訊息顯示, 導航到註冊頁面連結
  - 依賴: [T027]

---

## Phase 5: User Story 2 - 重新發送驗證碼 [P2]

### 後端 API (Edge Functions)
- [ ] [T029] [US2] [P2] 實作 POST /auth/resend-code 端點  
  - 檔案: `supabase/functions/auth/index.ts`  
  - 業務邏輯:
    1. 檢查 Email 是否存在 registration_request
    2. 檢查上次發送時間 (60 秒冷卻)
    3. 將舊的 pending 驗證碼標記為 expired
    4. 產生新的 6 位數驗證碼並儲存 bcrypt hash
    5. 透過 Resend API 發送驗證碼
    6. 重設 registration_request.expires_at (當前時間 + 30 分鐘)
  - 錯誤處理: EMAIL_NOT_FOUND (404), RATE_LIMIT (429 + 剩餘秒數), EMAIL_SEND_FAILED (503)
  - 依賴: [T009], [T010], [T012]

### 前端資料層 (Data Layer)
- [ ] [T030] [US2] [P2] 建立重發 API 回應模型  
  - 檔案: `lib/data/models/api_response_model.dart`  
  - 內容: `ResendCodeResponse`

- [ ] [T031] [US2] [P2] 實作重發 API 呼叫  
  - 檔案: `lib/data/datasources/auth_remote_datasource.dart`  
  - 方法: `resendVerificationCode(email)`

### 前端展示層 (Presentation Layer)
- [ ] [T032] [US2] [P2] 在 Email 驗證頁面新增重發功能  
  - 檔案: `lib/presentation/pages/email_verification_page.dart`  
  - 功能: "重新發送" 按鈕, 60 秒冷卻倒數計時, 成功後顯示提示訊息
  - 依賴: [T020], [T031]

---

## Phase 6: User Story 4 - 使用者登出 [P2]

### 後端 API (Edge Functions)
- [ ] [T033] [US4] [P2] 實作 POST /auth/logout 端點  
  - 檔案: `supabase/functions/auth/index.ts`  
  - 業務邏輯:
    1. 驗證 Authorization header 中的 access token
    2. 呼叫 Supabase Auth `signOut`
    3. 撤銷 refresh token (Supabase Auth 自動處理)
  - 錯誤處理: UNAUTHORIZED (401)

### 前端資料層 (Data Layer)
- [ ] [T034] [US4] [P2] 實作登出 API 呼叫  
  - 檔案: `lib/data/datasources/auth_remote_datasource.dart`  
  - 方法: `logoutUser(accessToken)`

### 前端領域層 (Domain Layer)
- [ ] [T035] [US4] [P2] 建立登出 Use Case  
  - 檔案: `lib/domain/usecases/logout_usecase.dart`  
  - 內容: 呼叫 logout API, 清除本地 session

### 前端展示層 (Presentation Layer)
- [ ] [T036] [US4] [P2] 在主頁新增登出功能  
  - 檔案: `lib/presentation/pages/home_page.dart`  
  - 功能: AppBar 選單 "登出", 確認對話框, 登出後導航到登入頁面
  - 依賴: [T027], [T035]

---

## Phase 7: User Story 5 - 記帳主頁 [P3]

### 前端展示層 (Presentation Layer)
- [ ] [T037] [US5] [P3] 實作記帳主頁 UI (佔位符)  
  - 檔案: `lib/presentation/pages/home_page.dart`  
  - 內容: 簡單的歡迎訊息, 顯示使用者姓名, AppBar 包含登出按鈕
  - 依賴: [T027]

- [ ] [T038] [US5] [P3] 設定路由守衛  
  - 檔案: `lib/core/router/app_router.dart`  
  - 內容: 檢查 token 有效性, 未登入則導航到登入頁面
  - 依賴: [T005], [T025]

- [ ] [T039] [US5] [P3] 實作自動登入流程  
  - 檔案: `lib/main.dart`, `lib/presentation/providers/auth_provider.dart`  
  - 內容: App 啟動時檢查本地 token, 有效則自動登入並導航到主頁
  - 依賴: [T025], [T027]

---

## Phase 8: 跨切面功能與優化

### 安全性與錯誤處理
- [ ] [T040] 實作 CORS 配置  
  - 檔案: `supabase/functions/auth/index.ts`  
  - 內容: 設定允許的前端網域, 正式環境移除 `*` wildcard

- [ ] [T041] 實作 Rate Limiting  
  - 檔案: `supabase/functions/auth/index.ts`  
  - 內容: 使用 Supabase Edge Functions 的內建 rate limiting 或自訂實作 (每 IP 每分鐘 60 次請求)

- [ ] [T042] 統一前端錯誤處理  
  - 檔案: `lib/core/errors/failures.dart`, `lib/core/errors/error_handler.dart`  
  - 內容: 定義 Failure 類別, 實作全域錯誤處理器, 顯示使用者友善的錯誤訊息

### Token 管理與自動刷新
- [ ] [T043] 實作 POST /auth/refresh-token 端點  
  - 檔案: `supabase/functions/auth/index.ts`  
  - 業務邏輯:
    1. 驗證 refresh token 有效性
    2. 檢查是否過期 (30 天)
    3. 產生新的 access token (1 小時)
    4. 回傳新的 session
  - 錯誤處理: INVALID_REFRESH_TOKEN (401), REFRESH_TOKEN_EXPIRED (401)

- [ ] [T044] 實作自動刷新 Token 邏輯  
  - 檔案: `lib/presentation/providers/auth_provider.dart`  
  - 內容: 使用 Riverpod timer 在 access token 過期前 5 分鐘自動刷新
  - 依賴: [T043], [T027]

### 測試與品質保證
- [ ] [T045] [P] 撰寫後端單元測試  
  - 檔案: `supabase/functions/auth/index.test.ts`  
  - 內容: 測試所有 API 端點的成功與錯誤情境, 使用 Deno 測試框架

- [ ] [T046] [P] 撰寫前端 Widget 測試  
  - 檔案: `test/presentation/pages/*.test.dart`  
  - 內容: 測試所有頁面的 UI 互動與狀態變化

- [ ] [T047] [P] 撰寫整合測試  
  - 檔案: `test/integration/auth_flow_test.dart`  
  - 內容: 測試完整的註冊→驗證→登入→登出流程

---

## 執行建議

### MVP 優先順序 (Phase 3 + Phase 4)
1. **平行開發**: 同時進行 Phase 3 (註冊) 和 Phase 4 (登入) 的後端 API
2. **平行開發**: 同時進行 Phase 3 和 Phase 4 的前端 UI
3. **串接測試**: 完成後進行整合測試

### 平行開發範例 (標記 [P] 的任務)
- **T001 + T002 + T004 + T005**: 環境設定可同時進行
- **T007 + T008 + T010 + T011**: 共用模組可同時開發
- **T012 + T021**: 後端 API 可同時實作
- **T045 + T046 + T047**: 測試可平行撰寫

### 里程碑檢查點
- **Milestone 1**: Phase 1-2 完成 → 驗證環境設定與共用模組
- **Milestone 2**: Phase 3-4 完成 → MVP 可運行 (註冊+登入)
- **Milestone 3**: Phase 5-6 完成 → 完整認證系統
- **Milestone 4**: Phase 7-8 完成 → 產品級品質

---

## 更新紀錄

| 日期 | 作者 | 變更內容 |
|------|------|---------|
| 2025-11-14 | GitHub Copilot | 初始任務清單建立 |

---

**下一步**: 開始執行 Phase 1 的環境設定任務 (T001-T006)
