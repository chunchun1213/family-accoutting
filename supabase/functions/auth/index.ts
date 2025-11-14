import { Hono } from 'https://deno.land/x/hono@v3.11.7/mod.ts';
import { cors } from 'https://deno.land/x/hono@v3.11.7/middleware.ts';

const app = new Hono();

// CORS 設定
app.use('*', cors({
  origin: '*',  // 開發環境允許所有來源
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 600,
}));

// Root route
app.get('/', (c) => {
  return c.json({ 
    message: 'Auth API',
    version: '1.0.0',
  });
});

// Health Check
app.get('/health', (c) => {
  return c.json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
  });
});

// TODO: 實作認證端點
// POST /register - 會員註冊（發送驗證碼）
// POST /verify-code - 驗證 Email 驗證碼
// POST /resend-code - 重新發送驗證碼
// POST /login - 使用者登入
// POST /logout - 使用者登出
// POST /refresh-token - 刷新 Access Token
// GET /me - 取得當前使用者資訊

// Supabase Edge Functions 使用 Deno.serve
Deno.serve((req) => app.fetch(req));
