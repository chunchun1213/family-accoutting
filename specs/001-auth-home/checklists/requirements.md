# Requirements Checklist: 會員註冊與登入系統以及記帳主頁顯示功能

## Content Quality Checks

- [X] **User Stories 具備清晰的使用者價值**: ✅ 5 個 User Stories 皆有明確的使用者目標 (US1-5: 註冊驗證/重發驗證碼/登入/登出/主頁)
- [X] **Acceptance Scenarios 使用 Given-When-Then 格式**: ✅ 所有 User Stories 包含 3 個完整的 Given-When-Then 場景 (正常/錯誤/邊界)
- [X] **Priority 分配合理**: ✅ P1 (註冊 US1, 登入 US3) / P2 (重發驗證碼 US2, 登出 US4) / P3 (主頁 US5)
- [X] **Edge Cases 涵蓋完整**: ✅ 10 個邊界情況 (驗證碼 5 次鎖定/Email 格式/會話過期/密碼顯示/網路失敗/重複註冊/特殊字元/多裝置登入等)
- [X] **Functional Requirements 編號清晰**: ✅ FR-001 至 FR-054 (54 個) + NFR-001 至 NFR-009 (9 個), 編號連續無重複
- [X] **Key Entities 定義明確**: ✅ 5 個實體 (User, UserProfile, RegistrationRequest, VerificationCode, Session) 包含屬性/型別/約束/關聯
- [X] **Success Criteria 可測量**: ✅ SC-001 至 SC-016 (16 個) 包含具體數值與測量方法 (時間/並發數/P95 延遲/滿意度評分)

## Requirement Completeness Checks

- [X] **註冊流程完整性**: ✅ 表單 (FR-001, FR-054) / 驗證規則 (FR-002~005) / 驗證碼生成 (FR-006, FR-053 bcrypt) / Email 發送 (FR-007, FR-045 Resend) / 有效期 (FR-008) / 導航 (FR-009)
- [X] **Email 驗證流程完整性**: ✅ 驗證介面 (FR-010) / 驗證邏輯 (FR-011~013) / 成功流程 (FR-014) / 重發功能 (FR-015~017 60秒冷卻) / 倒數計時 (FR-018) / 過期處理 (FR-019) / 錯誤追蹤 (FR-020~021 5次鎖定)
- [X] **登入流程完整性**: ✅ 表單 (FR-022) / 驗證 (FR-023) / 錯誤處理 (FR-024) / 會話管理 (FR-025~026) / 自動登入 (FR-028~029) / Token刷新 (FR-049~050) / 會話驗證 (FR-051~052) / 導航 (FR-027) / 密碼顯示 (FR-030)
- [X] **登出流程完整性**: ✅ 登出按鈕 (FR-031) / 確認對話框 (FR-032) / 清理會話 (FR-033) / 導航 (FR-034)
- [X] **主頁功能完整性**: ✅ 顯示條件 (FR-035) / 標題 (FR-036) / 按鈕 (FR-037~038) / 內容區域 (FR-039) / 登出整合 (FR-040)
- [X] **一般性需求涵蓋**: ✅ 即時驗證 (FR-041) / 載入狀態 (FR-042) / 網路錯誤 (FR-043) / Email 正規化 (FR-044) / Email 服務 (FR-045) / 技術架構 (FR-046~048)
- [X] **安全性考量**: ✅ CORS (NFR-001) / Rate Limiting (NFR-002) / 驗證碼保護 (NFR-003, FR-053 bcrypt) / 密碼雜湊 (FR-048) / SQL injection 防護 (FR-054) / XSS 防護 (FR-054) / 統一錯誤訊息 (FR-024)
- [X] **使用者體驗考量**: ✅ 即時驗證 (FR-041 <500ms) / 載入回饋 (FR-042) / 友善錯誤 (FR-043, NFR-005) / 密碼可見性 (FR-030) / 倒數計時 (FR-018) / 冷卻提示 (FR-016) / 自動導航 / 自動登入 (FR-028~029)

## Feature Readiness Checks

- [X] **技術可行性**: ✅ Flutter 3.35.7 已驗證 / Supabase local 運行中 / Edge Functions (Hono 3.11.7) 測試通過 / bcrypt 可用 / Resend API 已配置 / flutter_secure_storage 9.2.4 已安裝
- [X] **相依性識別**: ✅ 前端 (flutter_riverpod 2.6.1, go_router 13.2.5, supabase_flutter 2.8.3) / 後端 (Hono 3.11.7, Resend, bcrypt) / 資料庫 (PostgreSQL 15+, Supabase Auth) / Phase 相依 (Phase 1&2 完成)
- [X] **測試能力**: ✅ 單元測試 (≥80% NFR-008) / 整合測試 (NFR-009) / 負載測試 (k6 驗證 100 並發 NFR-007) / E2E 測試 (Flutter integration_test) / API 測試 (curl 已驗證)
- [X] **效能指標**: ✅ 驗證碼發送 P95 <30s (NFR-006, SC-004) / 並發處理 100 請求<3s (NFR-007, SC-011) / 即時驗證 <500ms (FR-041, SC-006) / 登入 <10s (SC-002) / 自動登入 <2s (SC-005)
- [X] **使用者體驗指標**: ✅ 註冊完成率 90% (SC-003) / 註冊時間 <3 分鐘 (SC-001) / 介面滿意度 ≥4.0 (SC-014) / 流程易理解度 85% (SC-013) / 錯誤訊息清晰度 ≥4.0 (SC-016) / 自動登入理解度 90% (SC-015)
- [X] **資料模型完整**: ✅ 5 個實體已定義 (User, UserProfile, RegistrationRequest, VerificationCode, Session) / 關聯關係 (1:1, 1:N) / 索引策略 / RLS 政策 / 清理策略 (pg_cron)
- [X] **錯誤處理策略**: ✅ 統一錯誤格式 (NFR-004) / 網路錯誤 (NFR-005) / 驗證錯誤 (FR-041) / 驗證碼錯誤追蹤 (FR-021) / 會話過期 (FR-052) / Email 重複 (FR-005) / 登入失敗 (FR-024)
- [X] **無 NEEDS CLARIFICATION 標記**: ✅ 已搜尋所有規格文件 (spec.md, data-model.md, research.md) 未發現任何 "NEEDS CLARIFICATION" 或 "TODO" 標記 / 所有技術決策已記錄於 research.md Part A~F

## Implementation Details Checks

- [X] **UI/UX 規格明確**: ✅ 註冊頁面 (4 欄位, 即時驗證, 載入狀態) / 驗證碼頁面 (顯示 Email, 6 位數輸入, 倒數計時, 重發按鈕 60s冷卻) / 登入頁面 (2 欄位, 密碼顯示/隱藏, 載入) / 主頁 (標題, 選單, 通知, 日曆圖示+「功能開發中」)
- [X] **API 需求識別**: ✅ POST /auth/register, POST /auth/verify-code, POST /auth/login, POST /auth/logout, GET /auth/me, POST /auth/resend-code, POST /auth/refresh-token / 所有端點已實作骨架 / contracts/auth-api.yaml 定義完整
- [X] **資料驗證規則具體**: ✅ Email (標準格式 含@, 統一小寫) / Password (8-20碼, 1大寫+1小寫+1數字) / Name (1-50字元, 過濾危險字元) / Code (6位數字) / 前端: validators.dart / 後端: validators.ts (Zod)
- [X] **時間參數明確**: ✅ 驗證碼有效期 5分鐘 (FR-008, FR-012) / 重發冷卻 60秒 (FR-016) / 註冊請求過期 30分鐘 / Access token 1小時 (FR-049) / Refresh token 30天 (FR-049) / Token 自動刷新 過期前5分鐘 (FR-050) / 舊驗證碼清理 7天後
- [X] **錯誤訊息標準化**: ✅ 前端: "Email 格式不正確", "密碼必須為 8-20 碼" 等中文訊息 (validators.dart) / 後端: { error_code, message, details } (NFR-004) / 網路錯誤: "網路連線失敗..." (FR-043) / 驗證碼: "驗證碼輸入錯誤次數過多..." (FR-021) / 登入: "Email 或密碼錯誤" (FR-024)
- [X] **狀態管理需求**: ✅ 全域認證狀態 (Riverpod AsyncNotifierProvider) / 4 種狀態 (Initial, Loading, Authenticated(user, token), Unauthenticated) / 自動會話檢查 (APP 啟動) / Token 自動刷新 (過期前 5 分鐘) / 登出清理 / 錯誤狀態處理 / 實作指引: research.md Part A

## Validation Summary

**Total Checks**: 31  
**Category Breakdown**:
- Content Quality: 7 checks
- Requirement Completeness: 8 checks
- Feature Readiness: 8 checks
- Implementation Details: 6 checks

**Review Instructions**:
1. 逐項檢查每個項目是否完成
2. 標記未完成的項目並註記原因
3. 對於未完成的項目，決定是否需要更新規格書或可以在實作階段處理
4. 確保所有 P1 需求相關的檢查項目都已通過

**Acceptance Criteria**:
- 所有「Content Quality Checks」必須通過
- 所有「Requirement Completeness Checks」必須通過
- 至少 75% 的「Feature Readiness Checks」必須通過
- 至少 80% 的「Implementation Details Checks」必須通過
