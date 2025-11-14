# Edge Function 404 問題解決報告

## 問題總結

### 發現時間
2025-11-14

### 問題描述
在 Supabase Edge Functions 中使用 Hono 框架時,所有 API 端點都返回 `404 Not Found`,即使程式碼語法正確且本地 Deno 執行正常。

### 影響範圍
- 阻礙所有 API 端點測試
- 無法進行 Phase 1 開發
- 本地開發環境無法使用

---

## 根本原因分析

### 原因 1: 缺少 Hono basePath 設定 ⭐ 主要原因

**錯誤程式碼**:
```typescript
import { Hono } from "https://deno.land/x/hono@v3.11.7/mod.ts";
const app = new Hono();  // ❌ 缺少 basePath
```

**問題**: 
Supabase Edge Functions 的 URL 結構是 `/functions/v1/<function-name>/<path>`,當 Hono 沒有設定 basePath 時,無法正確匹配到 function 名稱,導致所有請求返回 404。

**解決方案**:
```typescript
const app = new Hono().basePath("/auth");  // ✅ 設定 basePath
```

### 原因 2: config.toml 缺少 verify_jwt 設定

**問題**:
Edge Functions 預設要求 JWT 驗證,但本地開發環境測試時沒有有效的 JWT token,導致 "Missing authorization header" 錯誤。

**解決方案**:
```toml
[functions.auth]
enabled = true
verify_jwt = false  # 本地開發關閉 JWT 驗證
```

### 原因 3: 執行方式誤解

**錯誤理解**:
需要執行 `supabase functions serve auth --no-verify-jwt` 才能啟動 Edge Function。

**正確理解**:
Edge Functions 透過 `supabase start` 就已經在 Docker 容器中執行,不需要額外啟動。

---

## 解決過程

### 階段 1: 初步診斷 (失敗)
嘗試的方法:
- ✅ 加入根路由 `/` 和 `/health` 端點
- ✅ 修正 `Deno.serve()` 呼叫方式
- ✅ 重啟 Supabase 服務多次
- ❌ 問題持續存在

### 階段 2: 深入調查 (失敗)
嘗試的方法:
- ✅ 建立最小化測試版本 (移除所有 imports)
- ✅ 測試官方範例 (原生 Deno.serve)
- ✅ 檢查 Docker logs
- ❌ Hono 版本仍返回 404

發現:
- 官方原生 Deno 範例可以正常運作
- Hono 框架版本始終返回 404
- 問題與 imports 或程式碼邏輯無關

### 階段 3: 框架整合問題 (成功) ⭐
根據使用者提供的關鍵資訊:
> "在 Supabase Edge Function 中使用 Hono 框架,有機會遇到 404 錯誤,尤其是在根路徑 (/) 匹配上。解法是要在 Hono 構造時指定 basePath。"

立即測試並驗證:
1. 修改 `const app = new Hono().basePath("/auth")`
2. 重啟 Supabase
3. 測試所有端點
4. ✅ 所有端點正常運作!

---

## 最終解決方案

### 1. 修改 auth/index.ts

```typescript
// 加入 edge-runtime 類型定義
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

// 升級到 Hono 3.11.7
import { Hono } from "https://deno.land/x/hono@v3.11.7/mod.ts";
import { cors } from "https://deno.land/x/hono@v3.11.7/middleware.ts";

// 🔧 關鍵修正: 設定 basePath
const app = new Hono().basePath("/auth");

// 其餘程式碼保持不變...
```

### 2. 設定 config.toml

```toml
[functions.auth]
enabled = true
verify_jwt = false  # 本地開發使用
```

### 3. 測試驗證

```bash
# 啟動 Supabase
supabase start

# 測試所有端點
curl http://127.0.0.1:54321/functions/v1/auth
curl http://127.0.0.1:54321/functions/v1/auth/health
curl -X POST http://127.0.0.1:54321/functions/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","password":"Test1234","name":"使用者"}'
```

---

## 測試結果

### ✅ 所有端點測試通過

| 端點 | 方法 | 狀態 | 回應 |
|------|------|------|------|
| `/auth` | GET | ✅ | API 資訊 JSON |
| `/auth/health` | GET | ✅ | Health check 正常 |
| `/auth/register` | POST | ✅ | 註冊邏輯執行,驗證通過 |
| `/auth/verify-code` | POST | ✅ | 驗證碼邏輯執行 |
| `/auth/login` | POST | ✅ | 登入邏輯執行 |
| `/auth/me` | GET | ✅ | 取得使用者資訊 |
| `/auth/logout` | POST | ✅ | 登出邏輯執行 |
| `/auth/resend-code` | POST | ✅ | 重送驗證碼 |
| `/auth/refresh-token` | POST | ✅ | Token 刷新 |

### 範例回應

**GET /auth**:
```json
{
  "service": "Family Accounting Auth API",
  "version": "1.0.0",
  "endpoints": {
    "register": "POST /auth/register",
    "verifyCode": "POST /auth/verify-code",
    "login": "POST /auth/login",
    "me": "GET /auth/me",
    "logout": "POST /auth/logout",
    "resendCode": "POST /auth/resend-code",
    "refreshToken": "POST /auth/refresh-token"
  },
  "status": "running"
}
```

**POST /auth/register**:
```json
{
  "success": true,
  "data": {
    "email": "test@example.com",
    "expiresAt": "2025-11-14T07:00:00.000Z",
    "message": "Verification code sent"
  }
}
```

---

## 經驗教訓

### 1. 框架整合需要額外配置
使用第三方框架 (如 Hono, Oak) 時,需要查閱框架在特定平台 (Supabase Edge Functions) 的整合文件,不能假設與本地 Deno 執行方式相同。

### 2. basePath 是關鍵
在任何基於路由的框架中,當部署到有 URL 前綴的環境時,必須正確設定 basePath 或類似配置。

### 3. 環境差異需要測試
本地 Deno 執行正常 ≠ Supabase Edge Runtime 正常。必須在目標環境中測試。

### 4. 官方範例很重要
當遇到框架整合問題時,先測試官方範例是否正常,可以快速判斷是平台問題還是框架問題。

---

## 後續行動

### 已完成
- [x] 修正所有 Edge Function 程式碼
- [x] 更新 config.toml
- [x] 測試所有 API 端點
- [x] 清理測試檔案
- [x] 更新 SETUP_STATUS.md
- [x] 建立技術文件

### 待完成
- [ ] Git commit 所有變更
- [ ] 開始 Phase 1 實作 (T003-T006)
- [ ] 實作實際的業務邏輯 (TODO 部分)

---

## 技術資訊

- **Supabase Edge Runtime**: 1.69.15 (compatible with Deno v2.1.4)
- **Hono 版本**: v3.11.7
- **Deno 版本**: 2.5.6
- **解決日期**: 2025-11-14
- **總耗時**: 約 2-3 小時 (包含多次嘗試)

---

## 相關文件

- [Supabase Edge Functions - Hono 整合指南](.specify/guides/supabase-edge-functions-hono-setup.md)
- [SETUP_STATUS.md](../../../SETUP_STATUS.md)
- [tasks.md](../../../tasks.md)

---

## 結論

透過設定 Hono 的 `basePath` 和 config.toml 的 `verify_jwt`,成功解決了 Edge Function 404 問題。所有 API 端點現在都可以正常運作,本地開發環境完全就緒,可以開始實作認證系統的業務邏輯。

**狀態**: ✅ 問題完全解決
**環境**: 🟢 本地開發環境 100% 就緒
