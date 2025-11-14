# Supabase Edge Functions - Hono 框架整合指南

## 問題描述

在 Supabase Edge Functions 中使用 Hono 框架時,即使程式碼正確,也可能遇到 404 錯誤,特別是在根路徑 (`/`) 的匹配上。

## 根本原因

Supabase Edge Functions 的路由機制需要知道如何正確匹配 function 名稱。當使用 Hono 這類框架時,**必須明確設定 basePath** 來告訴框架請求的基礎路徑。

## 解決方案

### ❌ 錯誤寫法

```typescript
import { Hono } from "https://deno.land/x/hono@v3.11.7/mod.ts";

const app = new Hono();  // ❌ 缺少 basePath

app.get("/", (c) => {
  return c.json({ message: "Hello" });
});

Deno.serve(app.fetch);
```

### ✅ 正確寫法

```typescript
import { Hono } from "https://deno.land/x/hono@v3.11.7/mod.ts";

// ✅ 關鍵: basePath 必須與 Edge Function 名稱一致
const app = new Hono().basePath("/auth");

app.get("/", (c) => {
  return c.json({ message: "Hello" });
});

Deno.serve(app.fetch);
```

## 完整範例

```typescript
// supabase/functions/auth/index.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { Hono } from "https://deno.land/x/hono@v3.11.7/mod.ts";
import { cors } from "https://deno.land/x/hono@v3.11.7/middleware.ts";

// 🔧 basePath 設定為 Edge Function 名稱
const app = new Hono().basePath("/auth");

// CORS 設定
app.use("*", cors({
  origin: "*",
  allowMethods: ["GET", "POST"],
  allowHeaders: ["Content-Type", "Authorization"],
}));

// API 端點定義
app.get("/", (c) => {
  return c.json({
    service: "Auth API",
    version: "1.0.0",
    endpoints: {
      register: "POST /auth/register",
      login: "POST /auth/login",
    },
  });
});

app.post("/register", async (c) => {
  const body = await c.req.json();
  // 處理註冊邏輯
  return c.json({ success: true });
});

Deno.serve(app.fetch);
```

## 測試

### 本地測試設定

在 `supabase/config.toml` 中設定:

```toml
[functions.auth]
enabled = true
verify_jwt = false  # 本地開發使用
```

### 測試指令

```bash
# 啟動 Supabase
supabase start

# 測試根路徑
curl http://127.0.0.1:54321/functions/v1/auth

# 測試子路徑
curl -X POST http://127.0.0.1:54321/functions/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com"}'
```

## 注意事項

### 1. basePath 命名規則
- basePath 必須與 Edge Function 的資料夾名稱一致
- 例如: `supabase/functions/auth/` → `.basePath("/auth")`
- 例如: `supabase/functions/api/` → `.basePath("/api")`

### 2. 路由定義
設定 basePath 後,路由定義保持簡單:
```typescript
// ✅ 正確: 路由定義不包含 basePath
app.get("/", ...)          // 對應 GET /auth
app.post("/register", ...) // 對應 POST /auth/register

// ❌ 錯誤: 不要重複 basePath
app.get("/auth", ...)      // 會變成 GET /auth/auth
```

### 3. JWT 驗證設定

**本地開發環境**:
```toml
[functions.auth]
verify_jwt = false
```

**生產環境**:
```toml
[functions.auth]
verify_jwt = true
```

或在程式碼中手動驗證:
```typescript
app.get("/me", async (c) => {
  const authHeader = c.req.header("Authorization");
  if (!authHeader) {
    return c.json({ error: "Unauthorized" }, 401);
  }
  // 驗證 JWT token
});
```

## 相關資源

- [Hono 官方文件](https://hono.dev/)
- [Supabase Edge Functions 文件](https://supabase.com/docs/guides/functions)
- [Deno Deploy 文件](https://deno.com/deploy/docs)

## 問題排查

### 症狀: 404 Not Found

**可能原因 1**: 缺少 basePath
```typescript
// 修正
const app = new Hono().basePath("/auth");
```

**可能原因 2**: verify_jwt 設定錯誤
```bash
# 檢查 logs
docker logs supabase_edge_runtime_<project-name>

# 如果看到 "Missing authorization header"
# 修改 config.toml: verify_jwt = false
```

**可能原因 3**: Function 未重新載入
```bash
# 重啟 Supabase
supabase stop
supabase start
```

### 症狀: CORS 錯誤

```typescript
// 確保 CORS middleware 在所有路由之前
app.use("*", cors({
  origin: "*",  // 生產環境改為特定網域
  allowMethods: ["GET", "POST"],
  allowHeaders: ["Content-Type", "Authorization"],
}));
```

## 最佳實踐

1. **總是設定 basePath**: 即使只有一個 function,也要設定 basePath
2. **使用最新版本**: Hono 3.11.7+ 與 Supabase Edge Runtime 相容性最佳
3. **本地測試先關閉 JWT**: 開發階段設定 `verify_jwt = false`
4. **清理測試檔案**: 生產環境只保留必要檔案
5. **錯誤處理**: 每個端點都要有 try-catch

## 版本資訊

- Supabase Edge Runtime: 1.69.15 (compatible with Deno v2.1.4)
- Hono: v3.11.7
- Deno: 2.5.6
- 測試日期: 2025-11-14
- 狀態: ✅ 驗證通過
