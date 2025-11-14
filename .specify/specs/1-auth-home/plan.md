# 實作計畫：會員註冊與登入系統以及記帳主頁顯示功能

**分支**: `1-auth-home` | **日期**: 2025-11-13 | **規格**: [spec.md](./spec.md)  
**輸入**: 功能規格來自 `/specs/1-auth-home/spec.md`

## 摘要

本功能實作家庭記帳應用程式的核心認證系統，包含：
- **會員註冊與 Email 驗證**：使用者透過姓名、Email、密碼註冊，系統發送 6 位數驗證碼到 Email，驗證後建立帳號
- **登入與會話管理**：使用者使用 Email/密碼登入，系統建立 30 天有效期的會話，支援自動登入
- **登出功能**：使用者可主動登出，清除本地會話資料
- **記帳主頁（施工中）**：登入後顯示「功能開發中」佔位頁面

**技術方案**：
- **前端**：Flutter (Material 3)，使用 Riverpod 狀態管理，flutter_secure_storage 儲存會話
- **後端**：Supabase Auth + Supabase Edge Functions (Hono Server) 處理驗證碼邏輯
- **Email 服務**：Resend Email API 發送驗證碼
- **安全性**：密碼使用 bcrypt 雜湊儲存（透過 Supabase Auth），驗證碼 5 次錯誤後鎖定

## 技術背景

**語言/版本**: 
- 前端：Flutter SDK 3.16+, Dart 3.2+
- 後端：Deno 1.40+ (Supabase Edge Functions runtime), TypeScript 5.3+

**主要相依套件**:
- 前端：
  - `flutter_riverpod`: ^2.4.0 (狀態管理)
  - `flutter_secure_storage`: ^9.0.0 (安全儲存會話)
  - `flutter_form_builder`: ^9.1.0 (表單驗證)
  - `supabase_flutter`: ^2.0.0 (Supabase 客戶端)
- 後端：
  - `hono`: ^3.11.0 (輕量級 Web 框架)
  - `@supabase/supabase-js`: ^2.38.0 (Supabase 客戶端)
  - `@resend/sdk`: ^1.0.0 (Resend Email API)

**儲存**:
- **Supabase PostgreSQL**: 使用者帳號、驗證碼記錄、會話資料
  - `auth.users` (Supabase Auth 內建表格)
  - `public.verification_codes` (自訂驗證碼表格)
  - `public.registration_requests` (註冊請求追蹤)
- **本地儲存**: flutter_secure_storage (會話 token)

**測試**:
- 前端：Flutter widget testing, Integration testing
- 後端：Deno test (單元測試), Supabase local testing

**目標平台**:
- 前端：iOS 13+, Android 8.0+ (API 26+)
- 後端：Supabase Edge Functions (Deno runtime, 全球分散式邊緣運算)

**專案類型**: Mobile + API (Flutter 前端 + Supabase 後端)

**效能目標**:
- 註冊流程完成時間：< 3 分鐘 (含 Email 接收)
- 登入回應時間：< 10 秒
- 驗證碼發送時間：< 30 秒 (95%)
- 自動登入時間：< 2 秒
- API 回應時間：< 1 秒 (p95)

**限制條件**:
- 驗證碼有效期：5 分鐘
- 驗證碼重發冷卻：60 秒
- 驗證碼錯誤嘗試上限：5 次
- 會話有效期：30 天
- 密碼長度：8-20 字元（必須包含大小寫字母和數字）
- 姓名長度：≤ 50 字元
- 並發處理能力：≥ 100 個註冊請求

**規模/範圍**:
- 預期使用者數量：初期 < 1000 個家庭
- 頁面數量：4 個主要頁面（登入、註冊、Email 驗證、主頁）
- API 端點：約 6-8 個
- 資料表：4 個（Users, VerificationCode, Session, RegistrationRequest）

## 憲章檢查

*關卡：必須在 Phase 0 研究前通過。Phase 1 設計後重新檢查。*

**狀態**: ✅ 通過

本專案憲章為通用模板，無特定原則需驗證。以下為本功能的開發準則：

1. **測試優先**: 
   - 所有 API 端點需要單元測試
   - 關鍵使用者流程需要整合測試（註冊→驗證→登入）
   - Widget 測試覆蓋所有表單驗證邏輯

2. **安全性優先**:
   - 密碼透過 Supabase Auth 的 bcrypt 機制儲存
   - 會話 token 使用 flutter_secure_storage 加密儲存
   - Email 驗證碼限制嘗試次數（5 次）
   - 錯誤訊息不洩漏資訊（統一「Email 或密碼錯誤」）

3. **效能與可靠性**:
   - Supabase Edge Functions 提供全球低延遲
   - 驗證碼發送使用 Resend API（高可靠性）
   - 本地會話快取減少網路請求

4. **可維護性**:
   - Flutter 使用 Material 3 設計系統，參考 `doc/Flutter前端設計規格書.md`
   - Riverpod 提供清晰的狀態管理架構
   - Hono Server 提供輕量級、易於擴展的 API 架構

## 專案結構

### 文件 (此功能)

```text
specs/1-auth-home/
├── plan.md              # 本檔案 (/speckit.plan 指令輸出)
├── research.md          # Phase 0 輸出 (/speckit.plan 指令)
├── data-model.md        # Phase 1 輸出 (/speckit.plan 指令)
├── quickstart.md        # Phase 1 輸出 (/speckit.plan 指令)
├── contracts/           # Phase 1 輸出 (/speckit.plan 指令)
│   ├── auth-api.yaml   # 認證 API OpenAPI 規格
│   └── types.ts        # 共用型別定義
└── checklists/
    └── requirements.md  # 需求檢查清單
```

### 原始碼 (專案根目錄)

```text
# 前端 (Flutter)
lib/
├── main.dart                      # 應用程式入口
├── app/
│   ├── router.dart               # 路由配置
│   └── theme.dart                # Material 3 主題
├── features/
│   └── auth/
│       ├── data/
│       │   ├── models/
│       │   │   ├── user.dart
│       │   │   └── verification_code.dart
│       │   ├── repositories/
│       │   │   └── auth_repository.dart
│       │   └── datasources/
│       │       ├── auth_remote_datasource.dart
│       │       └── auth_local_datasource.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── user_entity.dart
│       │   ├── repositories/
│       │   │   └── auth_repository_interface.dart
│       │   └── usecases/
│       │       ├── register_user.dart
│       │       ├── verify_email.dart
│       │       ├── login_user.dart
│       │       └── logout_user.dart
│       └── presentation/
│           ├── pages/
│           │   ├── login_page.dart
│           │   ├── register_page.dart
│           │   ├── email_verification_page.dart
│           │   └── home_page.dart
│           ├── widgets/
│           │   ├── custom_text_field.dart
│           │   ├── primary_button.dart
│           │   └── verification_code_input.dart
│           └── providers/
│               ├── auth_state_provider.dart
│               └── auth_notifier.dart
└── core/
    ├── constants/
    │   ├── colors.dart           # 設計系統色彩
    │   └── text_styles.dart      # 設計系統字體
    ├── utils/
    │   └── validators.dart       # 表單驗證邏輯
    └── services/
        └── storage_service.dart  # flutter_secure_storage 封裝

test/
├── features/
│   └── auth/
│       ├── data/
│       │   └── repositories/
│       │       └── auth_repository_test.dart
│       ├── domain/
│       │   └── usecases/
│       │       ├── register_user_test.dart
│       │       └── login_user_test.dart
│       └── presentation/
│           └── pages/
│               └── login_page_test.dart
└── integration/
    └── auth_flow_test.dart       # 完整認證流程測試

# 後端 (Supabase Edge Functions)
supabase/
├── functions/
│   ├── send-verification-code/
│   │   └── index.ts              # 發送驗證碼 API
│   ├── verify-code/
│   │   └── index.ts              # 驗證驗證碼 API
│   ├── resend-verification-code/
│   │   └── index.ts              # 重新發送驗證碼 API
│   └── _shared/
│       ├── types.ts              # 共用型別
│       ├── validators.ts         # 輸入驗證
│       └── email-service.ts      # Resend Email 整合
└── migrations/
    ├── 20251113000001_create_verification_codes.sql
    └── 20251113000002_create_registration_requests.sql

# 設計資源
design-assets/
├── icons/
│   ├── login-user-icon.svg
│   ├── home-calendar-icon.svg
│   ├── email-verification-icon.svg
│   ├── password-toggle-icon.svg
│   ├── notification-bell-icon.svg
│   ├── menu-icon.svg
│   ├── back-arrow-icon.svg
│   └── info-icon.svg
└── README.md

# 文件
doc/
├── Flutter前端設計規格書.md     # UI/UX 設計規格
└── 1-使用者原始需求.md          # 原始需求文件
```

**結構決策**: 選擇 **Mobile + API 架構**，因為：
- 前端使用 Flutter 跨平台框架，遵循 Clean Architecture 分層（data/domain/presentation）
- 後端使用 Supabase Edge Functions，每個功能獨立部署
- 設計資源集中在 `design-assets/` 目錄，參照 `doc/Flutter前端設計規格書.md`

## 複雜度追蹤

> **僅在憲章檢查有違規需要說明時填寫**

N/A - 無憲章違規項目

---

## Phase 0: 大綱與研究

### 待研究項目

以下項目需要在 Phase 0 完成研究，並產出 `research.md`：

1. **Supabase Auth 與自訂驗證碼整合**
   - Supabase Auth 預設使用魔法連結或 OTP，需研究如何整合自訂的 6 位數驗證碼流程
   - 研究 Supabase Auth 的註冊流程鉤子（hooks）或客製化方式

2. **Resend Email API 整合最佳實踐**
   - Email 模板設計（驗證碼格式、品牌識別）
   - 錯誤處理策略（發送失敗、API 限額）
   - Webhook 設定（追蹤發送狀態）

3. **Flutter Riverpod 認證狀態管理模式**
   - 全域認證狀態 provider 設計
   - 自動登入流程的狀態同步
   - 登出後的狀態清理策略

4. **flutter_secure_storage 最佳實踐**
   - iOS Keychain 與 Android Keystore 配置
   - 會話 token 儲存格式
   - 跨平台加密一致性

5. **Hono Server 在 Supabase Edge Functions 的使用模式**
   - 路由配置與中介軟體（middleware）
   - 錯誤處理與回應格式標準化
   - CORS 設定（Supabase Edge Functions 環境）

6. **驗證碼錯誤嘗試追蹤機制**
   - PostgreSQL 資料表設計（計數器、時間戳記）
   - 並發請求下的計數器原子性操作
   - 鎖定後的解鎖策略

### 研究任務分派

研究結果將整合至 `research.md`，格式如下：
- **決策**: [選擇的方案]
- **理由**: [為何選擇]
- **考慮的替代方案**: [評估過的其他選項]

---

## Phase 1: 設計與合約

**前置條件**: `research.md` 完成

### 產出文件

1. **data-model.md**: 資料模型設計
   - User（使用者）實體與欄位
   - VerificationCode（驗證碼）實體與狀態機
   - Session（會話）實體與過期邏輯
   - RegistrationRequest（註冊請求）實體與追蹤

2. **contracts/auth-api.yaml**: API 合約（OpenAPI 3.0）
   - `POST /auth/register` - 註冊使用者
   - `POST /auth/send-verification-code` - 發送驗證碼
   - `POST /auth/verify-code` - 驗證驗證碼
   - `POST /auth/resend-verification-code` - 重新發送驗證碼
   - `POST /auth/login` - 登入
   - `POST /auth/logout` - 登出
   - `GET /auth/session` - 檢查會話狀態

3. **contracts/types.ts**: TypeScript 型別定義（前後端共用）
   - `RegisterRequest`, `RegisterResponse`
   - `VerificationCodeRequest`, `VerificationCodeResponse`
   - `LoginRequest`, `LoginResponse`
   - `ErrorResponse`

4. **quickstart.md**: 快速開始指南
   - 開發環境設定（Flutter, Supabase CLI）
   - 本地測試流程
   - Supabase 專案配置步驟

### Agent 上下文更新

執行 `.specify/scripts/bash/update-agent-context.sh copilot` 更新 GitHub Copilot 上下文文件，加入：
- 技術棧資訊（Flutter 3.16+, Supabase, Hono）
- 專案結構說明
- 設計規格參考（`doc/Flutter前端設計規格書.md`）

---

## 下一步

1. **完成 Phase 0**: 執行研究任務，產出 `research.md`
2. **執行 Phase 1**: 根據研究結果設計資料模型與 API 合約
3. **執行 `/speckit.tasks`**: 將計畫轉換為可執行的開發任務（`tasks.md`）

**分支**: `1-auth-home`  
**計畫路徑**: `.specify/specs/1-auth-home/plan.md`  
**規格路徑**: `.specify/specs/1-auth-home/spec.md`
