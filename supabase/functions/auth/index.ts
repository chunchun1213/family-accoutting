// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { Hono } from "https://deno.land/x/hono@v3.11.7/mod.ts";
import { cors } from "https://deno.land/x/hono@v3.11.7/middleware.ts";
import { InputValidator } from "../_shared/validators.ts";
import { EmailService } from "../_shared/email-service.ts";
import { DbHelpers } from "../_shared/db-helpers.ts";
import { ERROR_CODES } from "../_shared/types.ts";

// 🔧 關鍵修正: 設定 basePath 為 Edge Function 名稱
const app = new Hono().basePath("/auth");

// Enable CORS
app.use("*", cors({
  origin: "*", // TODO: Change to specific domain in production
  allowMethods: ["GET", "POST"],
  allowHeaders: ["Content-Type", "Authorization"],
}));

// Root endpoint - API info
app.get("/", (c) => {
  return c.json({
    service: "Family Accounting Auth API",
    version: "1.0.0",
    endpoints: {
      register: "POST /auth/register",
      verifyCode: "POST /auth/verify-code",
      login: "POST /auth/login",
      me: "GET /auth/me",
      logout: "POST /auth/logout",
      resendCode: "POST /auth/resend-code",
      refreshToken: "POST /auth/refresh-token",
    },
    status: "running",
  });
});

// Health check endpoint
app.get("/health", (c) => {
  return c.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
  });
});

// Register endpoint
app.post("/register", async (c) => {
  try {
    const body = await c.req.json();
    const errors = InputValidator.validateRegistrationRequest(body);

    if (errors.length > 0) {
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.VALIDATION_ERROR,
          message: errors[0].message,
          details: errors,
        },
      }, 400);
    }

    // TODO: Implement actual registration logic
    // 1. Check if email exists
    // 2. Create registration request record
    // 3. Generate and send verification code

    return c.json({
      success: true,
      data: {
        email: body.email,
        expiresAt: DbHelpers.getExpirationTime(5),
        message: "Verification code sent",
      },
    });
  } catch (error) {
    console.error("Register error:", error);
    return c.json({
      success: false,
      error: {
        code: ERROR_CODES.SERVER_ERROR,
        message: "Internal server error",
      },
    }, 500);
  }
});

// Verify code endpoint
app.post("/verify-code", async (c) => {
  try {
    const body = await c.req.json();
    const errors = InputValidator.validateVerifyCodeRequest(body);

    if (errors.length > 0) {
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.VALIDATION_ERROR,
          message: errors[0].message,
          details: errors,
        },
      }, 400);
    }

    // TODO: Implement actual verification logic
    // 1. Verify the code
    // 2. Create Supabase Auth user
    // 3. Create user profile
    // 4. Return session tokens

    return c.json({
      success: true,
      data: {
        user: {
          id: "user_" + DbHelpers.generateUUID(),
          email: body.email,
          name: "User",
        },
        session: {
          accessToken: "access_token_placeholder",
          refreshToken: "refresh_token_placeholder",
          expiresAt: Date.now() + 3600000,
        },
      },
    });
  } catch (error) {
    console.error("Verify code error:", error);
    return c.json({
      success: false,
      error: {
        code: ERROR_CODES.SERVER_ERROR,
        message: "Internal server error",
      },
    }, 500);
  }
});

// Login endpoint
app.post("/login", async (c) => {
  try {
    const body = await c.req.json();
    const errors = InputValidator.validateLoginRequest(body);

    if (errors.length > 0) {
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.VALIDATION_ERROR,
          message: errors[0].message,
          details: errors,
        },
      }, 400);
    }

    // TODO: Implement actual login logic
    // 1. Authenticate with Supabase Auth
    // 2. Get user profile
    // 3. Return session tokens

    return c.json({
      success: true,
      data: {
        user: {
          id: "user_" + DbHelpers.generateUUID(),
          email: body.email,
          name: "User",
        },
        session: {
          accessToken: "access_token_placeholder",
          refreshToken: "refresh_token_placeholder",
          expiresAt: Date.now() + 3600000,
        },
      },
    });
  } catch (error) {
    console.error("Login error:", error);
    return c.json({
      success: false,
      error: {
        code: ERROR_CODES.SERVER_ERROR,
        message: "Internal server error",
      },
    }, 500);
  }
});

// Get current user endpoint
app.get("/me", async (c) => {
  try {
    const authHeader = c.req.header("Authorization");
    if (!authHeader) {
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.UNAUTHORIZED,
          message: "Missing authorization header",
        },
      }, 401);
    }

    // TODO: Verify JWT token and get user info

    return c.json({
      success: true,
      data: {
        id: "user_id",
        email: "user@example.com",
        name: "User Name",
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
    });
  } catch (error) {
    console.error("Get me error:", error);
    return c.json({
      success: false,
      error: {
        code: ERROR_CODES.SERVER_ERROR,
        message: "Internal server error",
      },
    }, 500);
  }
});

// Logout endpoint
app.post("/logout", async (c) => {
  try {
    const authHeader = c.req.header("Authorization");
    if (!authHeader) {
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.UNAUTHORIZED,
          message: "Missing authorization header",
        },
      }, 401);
    }

    // TODO: Implement logout logic (revoke token if needed)

    return c.json({
      success: true,
      data: { message: "Logged out successfully" },
    });
  } catch (error) {
    console.error("Logout error:", error);
    return c.json({
      success: false,
      error: {
        code: ERROR_CODES.SERVER_ERROR,
        message: "Internal server error",
      },
    }, 500);
  }
});

// Resend verification code endpoint
app.post("/resend-code", async (c) => {
  try {
    const body = await c.req.json();

    if (!body.email || typeof body.email !== "string") {
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.VALIDATION_ERROR,
          message: "Email is required",
        },
      }, 400);
    }

    // TODO: Implement resend logic
    // 1. Check cooldown
    // 2. Generate new code
    // 3. Send email

    return c.json({
      success: true,
      data: {
        message: "Verification code resent",
        expiresAt: DbHelpers.getExpirationTime(5),
      },
    });
  } catch (error) {
    console.error("Resend code error:", error);
    return c.json({
      success: false,
      error: {
        code: ERROR_CODES.SERVER_ERROR,
        message: "Internal server error",
      },
    }, 500);
  }
});

// Refresh token endpoint
app.post("/refresh-token", async (c) => {
  try {
    const body = await c.req.json();

    if (!body.refreshToken || typeof body.refreshToken !== "string") {
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.VALIDATION_ERROR,
          message: "Refresh token is required",
        },
      }, 400);
    }

    // TODO: Implement token refresh logic

    return c.json({
      success: true,
      data: {
        user: {
          id: "user_id",
          email: "user@example.com",
          name: "User Name",
        },
        session: {
          accessToken: "new_access_token",
          refreshToken: "refresh_token_placeholder",
          expiresAt: Date.now() + 3600000,
        },
      },
    });
  } catch (error) {
    console.error("Refresh token error:", error);
    return c.json({
      success: false,
      error: {
        code: ERROR_CODES.SERVER_ERROR,
        message: "Internal server error",
      },
    }, 500);
  }
});

Deno.serve(app.fetch);
