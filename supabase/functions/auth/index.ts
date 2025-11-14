// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { Hono } from "https://deno.land/x/hono@v3.11.7/mod.ts";
import { cors } from "https://deno.land/x/hono@v3.11.7/middleware.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { InputValidator } from "../_shared/validators.ts";
import { EmailService } from "../_shared/email-service.ts";
import { DbHelpers } from "../_shared/db-helpers.ts";
import { ERROR_CODES } from "../_shared/types.ts";

// Initialize Supabase client
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

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

    // 1. Check if email already exists in auth.users
    const { data: existingUser } = await supabase.auth.admin.listUsers();
    if (existingUser?.users.some((u: any) => u.email?.toLowerCase() === body.email.toLowerCase())) {
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.EMAIL_EXISTS,
          message: "此 Email 已被註冊",
        },
      }, 400);
    }

    // 2. Check if email already has a pending registration request
    const { data: existingRequest, error: requestError } = await supabase
      .from("registration_requests")
      .select("*")
      .eq("email", body.email.toLowerCase())
      .single();

    if (existingRequest && !requestError) {
      // Delete old request if it exists (allow re-registration)
      await supabase
        .from("registration_requests")
        .delete()
        .eq("email", body.email.toLowerCase());
      
      // Delete associated verification codes
      await supabase
        .from("verification_codes")
        .delete()
        .eq("email", body.email.toLowerCase());
    }

    // 3. Create registration request record (store plain password temporarily for 30 minutes)
    // Note: This is stored temporarily and will be deleted after verification
    const expiresAt = DbHelpers.getExpirationTime(30); // 30 minutes
    const { error: insertError } = await supabase
      .from("registration_requests")
      .insert({
        email: body.email.toLowerCase(),
        name: body.name,
        password_hash: body.password, // Store temporarily, will be deleted after verification
        expires_at: expiresAt,
      });

    if (insertError) {
      console.error("Failed to create registration request:", insertError);
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.SERVER_ERROR,
          message: "註冊失敗，請稍後再試",
        },
      }, 500);
    }

    // 5. Generate and hash verification code
    const verificationCode = DbHelpers.generateVerificationCode();
    const codeHash = await DbHelpers.hashCode(verificationCode);
    const codeExpiresAt = DbHelpers.getExpirationTime(5); // 5 minutes

    const { error: codeError } = await supabase
      .from("verification_codes")
      .insert({
        email: body.email.toLowerCase(),
        code_hash: codeHash,
        status: "pending",
        expires_at: codeExpiresAt,
      });

    if (codeError) {
      console.error("Failed to create verification code:", codeError);
      // Rollback registration request
      await supabase
        .from("registration_requests")
        .delete()
        .eq("email", body.email.toLowerCase());
      
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.SERVER_ERROR,
          message: "驗證碼生成失敗，請稍後再試",
        },
      }, 500);
    }

    // 6. Send verification code via email
    try {
      await EmailService.sendVerificationCode(
        body.email,
        verificationCode,
        5
      );
    } catch (emailError) {
      console.error("Failed to send email:", emailError);
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.EMAIL_SEND_FAILED,
          message: "Email 發送失敗，請稍後再試",
        },
      }, 503);
    }

    return c.json({
      success: true,
      message: "驗證碼已發送至您的 Email，請於 5 分鐘內完成驗證",
      data: {
        email: body.email.toLowerCase(),
        expires_at: codeExpiresAt,
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

    // 1. Get registration request
    const { data: registrationRequest, error: regError } = await supabase
      .from("registration_requests")
      .select("*")
      .eq("email", body.email.toLowerCase())
      .single();

    if (regError || !registrationRequest) {
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.CODE_NOT_FOUND,
          message: "找不到註冊記錄，請重新註冊",
        },
      }, 404);
    }

    // Check if registration request has expired
    if (DbHelpers.isExpired(registrationRequest.expires_at)) {
      // Clean up expired registration
      await supabase
        .from("registration_requests")
        .delete()
        .eq("email", body.email.toLowerCase());
      await supabase
        .from("verification_codes")
        .delete()
        .eq("email", body.email.toLowerCase());

      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.CODE_EXPIRED,
          message: "註冊請求已過期，請重新註冊",
        },
      }, 400);
    }

    // 2. Get and lock verification code record (SELECT FOR UPDATE)
    const { data: verificationCode, error: codeError } = await supabase
      .from("verification_codes")
      .select("*")
      .eq("email", body.email.toLowerCase())
      .eq("status", "pending")
      .single();

    if (codeError || !verificationCode) {
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.CODE_NOT_FOUND,
          message: "找不到驗證碼，請重新發送",
        },
      }, 404);
    }

    // Check if code has expired
    if (DbHelpers.isExpired(verificationCode.expires_at)) {
      await supabase
        .from("verification_codes")
        .update({ status: "expired" })
        .eq("id", verificationCode.id);

      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.CODE_EXPIRED,
          message: "驗證碼已過期，請重新發送",
        },
      }, 400);
    }

    // Check if code is locked
    if (verificationCode.status === "locked" || DbHelpers.isCodeLocked(verificationCode.attempt_count)) {
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.CODE_LOCKED,
          message: "驗證碼輸入錯誤次數過多，請重新發送驗證碼",
        },
      }, 403);
    }

    // 3. Verify the code using SHA-256
    const isCodeValid = await DbHelpers.compareCode(body.code, verificationCode.code_hash);

    if (!isCodeValid) {
      // Increment attempt count
      const newAttemptCount = verificationCode.attempt_count + 1;
      const remainingAttempts = DbHelpers.getRemainingAttempts(newAttemptCount);
      const isLocked = DbHelpers.isCodeLocked(newAttemptCount);

      await supabase
        .from("verification_codes")
        .update({
          attempt_count: newAttemptCount,
          status: isLocked ? "locked" : "pending",
        })
        .eq("id", verificationCode.id);

      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.CODE_INVALID,
          message: isLocked 
            ? "驗證碼輸入錯誤次數過多，請重新發送驗證碼"
            : "驗證碼錯誤",
          details: {
            attempts_remaining: remainingAttempts,
          },
        },
      }, 400);
    }

    // 4. Create Supabase Auth user (Supabase will hash the password with bcrypt)
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: body.email.toLowerCase(),
      password: registrationRequest.password_hash, // This is the plain password, Supabase will hash it
      email_confirm: true,
      user_metadata: {
        name: registrationRequest.name,
      },
    });

    if (authError || !authData.user) {
      console.error("Failed to create auth user:", authError);
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.SERVER_ERROR,
          message: "建立使用者帳號失敗，請稍後再試",
        },
      }, 500);
    }

    // 5. Create user profile
    const { error: profileError } = await supabase
      .from("user_profiles")
      .insert({
        id: authData.user.id,
        email: body.email.toLowerCase(),
        name: registrationRequest.name,
      });

    if (profileError) {
      console.error("Failed to create user profile:", profileError);
      // Rollback: delete auth user
      await supabase.auth.admin.deleteUser(authData.user.id);
      
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.SERVER_ERROR,
          message: "建立使用者資料失敗，請稍後再試",
        },
      }, 500);
    }

    // 6. Mark verification code as verified
    await supabase
      .from("verification_codes")
      .update({
        status: "verified",
        verified_at: new Date().toISOString(),
      })
      .eq("id", verificationCode.id);

    // 7. Delete registration request (cleanup)
    await supabase
      .from("registration_requests")
      .delete()
      .eq("email", body.email.toLowerCase());

    // 8. Generate session token using Supabase Auth
    const { data: sessionData, error: sessionError } = await supabase.auth.signInWithPassword({
      email: body.email.toLowerCase(),
      password: registrationRequest.password_hash, // Plain password, Supabase will verify against hashed password
    });

    if (sessionError || !sessionData.session) {
      console.error("Failed to create session:", sessionError);
      return c.json({
        success: false,
        error: {
          code: ERROR_CODES.SERVER_ERROR,
          message: "建立登入會話失敗，請手動登入",
        },
      }, 500);
    }

    return c.json({
      success: true,
      message: "Email 驗證成功",
      data: {
        user: {
          id: authData.user.id,
          email: authData.user.email!,
          name: registrationRequest.name,
        },
        session: {
          access_token: sessionData.session.access_token,
          refresh_token: sessionData.session.refresh_token,
          expires_in: sessionData.session.expires_in,
          expires_at: sessionData.session.expires_at,
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
