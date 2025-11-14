// 共用型別定義
// 參考: .specify/specs/1-auth-home/contracts/types.ts

// ============================================
// API 回應格式
// ============================================

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: any;
  };
  timestamp?: string;
}

// ============================================
// 註冊相關
// ============================================

export interface RegisterRequest {
  email: string;
  name: string;
  password: string;
}

export interface RegisterResponse {
  email: string;
  expiresAt: string;
  message: string;
}

// ============================================
// 驗證碼相關
// ============================================

export interface VerifyCodeRequest {
  email: string;
  code: string;
}

export interface VerifyCodeResponse {
  user: {
    id: string;
    email: string;
    name: string;
  };
  session: {
    accessToken: string;
    refreshToken: string;
    expiresAt: number;
  };
}

export interface ResendCodeRequest {
  email: string;
}

// ============================================
// 登入相關
// ============================================

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  user: {
    id: string;
    email: string;
    name: string;
  };
  session: {
    accessToken: string;
    refreshToken: string;
    expiresAt: number;
  };
}

// ============================================
// 資料庫實體
// ============================================

export interface RegistrationRequest {
  id: string;
  email: string;
  name: string;
  passwordHash: string;
  createdAt: string;
  expiresAt: string;
}

export interface VerificationCode {
  id: string;
  email: string;
  codeHash: string;
  attemptCount: number;
  maxAttempts: number;
  status: 'pending' | 'verified' | 'locked' | 'expired';
  createdAt: string;
  expiresAt: string;
  lockedAt?: string;
  verifiedAt?: string;
  emailId?: string;
}

export interface UserProfile {
  id: string;
  name: string;
  email: string;
  createdAt: string;
  updatedAt: string;
}

// ============================================
// 常數
// ============================================

export const APP_CONSTANTS = {
  PASSWORD: {
    MIN_LENGTH: 8,
    MAX_LENGTH: 20,
    REQUIRE_UPPERCASE: true,
    REQUIRE_LOWERCASE: true,
    REQUIRE_NUMBER: true,
  },
  VERIFICATION_CODE: {
    LENGTH: 6,
    EXPIRES_IN_MINUTES: 5,
    MAX_ATTEMPTS: 5,
    RESEND_COOLDOWN_SECONDS: 60,
  },
  REGISTRATION: {
    EXPIRES_IN_MINUTES: 30,
  },
  SESSION: {
    EXPIRES_IN_DAYS: 30,
  },
} as const;

export const ERROR_CODES = {
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  INVALID_EMAIL: 'INVALID_EMAIL',
  INVALID_PASSWORD: 'INVALID_PASSWORD',
  EMAIL_ALREADY_EXISTS: 'EMAIL_ALREADY_EXISTS',
  EMAIL_EXISTS: 'EMAIL_EXISTS',
  INVALID_CREDENTIALS: 'INVALID_CREDENTIALS',
  CODE_INVALID: 'CODE_INVALID',
  CODE_EXPIRED: 'CODE_EXPIRED',
  CODE_LOCKED: 'CODE_LOCKED',
  CODE_NOT_FOUND: 'CODE_NOT_FOUND',
  RATE_LIMIT: 'RATE_LIMIT',
  EMAIL_SEND_FAILED: 'EMAIL_SEND_FAILED',
  SERVER_ERROR: 'SERVER_ERROR',
  UNAUTHORIZED: 'UNAUTHORIZED',
} as const;
