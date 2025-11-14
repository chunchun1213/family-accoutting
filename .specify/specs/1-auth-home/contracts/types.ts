/**
 * TypeScript Type Definitions - 會員註冊與登入系統
 * 
 * 此檔案定義前端（Flutter/Dart）與後端（Supabase Edge Functions/TypeScript）之間的資料型別
 * 
 * **使用方式**:
 * - 後端: 直接 import 使用
 * - 前端: 使用 `dart_mappable` 或 `freezed` 產生對應的 Dart 類別
 * 
 * **版本**: 1.0.0
 * **對應 API**: auth-api.yaml v1.0.0
 */

// ============================================================================
// 通用型別
// ============================================================================

/**
 * 標準 API 回應格式
 */
export interface ApiResponse<T = unknown> {
  /** 請求是否成功 */
  success: boolean;
  /** 成功訊息（選用） */
  message?: string;
  /** 回應資料 */
  data?: T;
  /** 錯誤資訊（僅當 success = false） */
  error?: ApiError;
}

/**
 * API 錯誤格式
 */
export interface ApiError {
  /** 錯誤代碼（大寫英文 + 底線） */
  code: ErrorCode;
  /** 錯誤訊息（繁體中文） */
  message: string;
  /** 額外錯誤資訊（選用） */
  details?: Record<string, unknown>;
}

/**
 * 錯誤代碼列舉
 */
export enum ErrorCode {
  // 400 Bad Request
  INVALID_EMAIL = 'INVALID_EMAIL',
  INVALID_PASSWORD = 'INVALID_PASSWORD',
  INVALID_NAME = 'INVALID_NAME',
  INVALID_CODE = 'INVALID_CODE',
  EMAIL_EXISTS = 'EMAIL_EXISTS',
  CODE_EXPIRED = 'CODE_EXPIRED',
  
  // 401 Unauthorized
  INVALID_CREDENTIALS = 'INVALID_CREDENTIALS',
  INVALID_TOKEN = 'INVALID_TOKEN',
  TOKEN_EXPIRED = 'TOKEN_EXPIRED',
  INVALID_REFRESH_TOKEN = 'INVALID_REFRESH_TOKEN',
  REFRESH_TOKEN_EXPIRED = 'REFRESH_TOKEN_EXPIRED',
  
  // 403 Forbidden
  CODE_LOCKED = 'CODE_LOCKED',
  EMAIL_NOT_VERIFIED = 'EMAIL_NOT_VERIFIED',
  ACCOUNT_LOCKED = 'ACCOUNT_LOCKED',
  
  // 404 Not Found
  CODE_NOT_FOUND = 'CODE_NOT_FOUND',
  EMAIL_NOT_FOUND = 'EMAIL_NOT_FOUND',
  USER_NOT_FOUND = 'USER_NOT_FOUND',
  
  // 429 Too Many Requests
  RATE_LIMIT = 'RATE_LIMIT',
  
  // 503 Service Unavailable
  EMAIL_SEND_FAILED = 'EMAIL_SEND_FAILED',
  DATABASE_ERROR = 'DATABASE_ERROR',
  SUPABASE_ERROR = 'SUPABASE_ERROR',
}

// ============================================================================
// 註冊相關型別
// ============================================================================

/**
 * 註冊請求
 */
export interface RegisterRequest {
  /** Email（會統一轉換為小寫） */
  email: string;
  /** 使用者姓名（1-50 字元） */
  name: string;
  /** 密碼（8-20 碼，包含大小寫字母與數字） */
  password: string;
}

/**
 * 註冊回應
 */
export interface RegisterResponse {
  /** 註冊的 Email */
  email: string;
  /** 驗證碼過期時間（ISO 8601 格式） */
  expires_at: string;
}

/**
 * 驗證碼驗證請求
 */
export interface VerifyCodeRequest {
  /** Email */
  email: string;
  /** 6 位數驗證碼 */
  code: string;
}

/**
 * 驗證碼驗證回應
 */
export interface VerifyCodeResponse {
  /** 新建立的使用者資訊 */
  user: User;
  /** JWT session */
  session: Session;
}

/**
 * 重新發送驗證碼請求
 */
export interface ResendCodeRequest {
  /** Email */
  email: string;
}

/**
 * 重新發送驗證碼回應
 */
export interface ResendCodeResponse {
  /** Email */
  email: string;
  /** 新驗證碼過期時間 */
  expires_at: string;
  /** 下次可重新發送時間（60 秒後） */
  can_resend_after: string;
}

// ============================================================================
// 登入/登出相關型別
// ============================================================================

/**
 * 登入請求
 */
export interface LoginRequest {
  /** Email */
  email: string;
  /** 密碼 */
  password: string;
}

/**
 * 登入回應
 */
export interface LoginResponse {
  /** 使用者資訊 */
  user: User;
  /** JWT session */
  session: Session;
}

/**
 * 登出回應
 */
export interface LogoutResponse {
  // 無額外資料，僅 success 與 message
}

// ============================================================================
// Session 管理相關型別
// ============================================================================

/**
 * 刷新 Token 請求
 */
export interface RefreshTokenRequest {
  /** Refresh token */
  refresh_token: string;
}

/**
 * 刷新 Token 回應
 */
export interface RefreshTokenResponse {
  /** 新的 session（包含新 access token） */
  session: Session;
}

/**
 * 取得當前使用者資訊回應
 */
export interface UserInfoResponse {
  /** 使用者詳細資訊 */
  user: UserDetail;
}

// ============================================================================
// 實體型別
// ============================================================================

/**
 * 使用者基本資訊（用於 API 回應）
 */
export interface User {
  /** 使用者 UUID */
  id: string;
  /** Email */
  email: string;
  /** 姓名 */
  name: string;
}

/**
 * 使用者詳細資訊（包含時間戳記）
 */
export interface UserDetail extends User {
  /** 帳號建立時間（ISO 8601 格式） */
  created_at: string;
  /** 最後登入時間（ISO 8601 格式，可為 null） */
  last_sign_in_at: string | null;
}

/**
 * JWT Session
 */
export interface Session {
  /** JWT access token（有效期 1 小時） */
  access_token: string;
  /** Refresh token（有效期 30 天） */
  refresh_token: string;
  /** Access token 有效秒數 */
  expires_in: number;
  /** Access token 過期時間戳記（Unix timestamp，秒） */
  expires_at: number;
}

/**
 * 本地儲存的 Session 資料（flutter_secure_storage）
 * 
 * **Flutter 對應類別** (使用 freezed):
 * ```dart
 * @freezed
 * class SessionData with _$SessionData {
 *   const factory SessionData({
 *     required String accessToken,
 *     required String refreshToken,
 *     required DateTime expiresAt,
 *     required String userId,
 *     @Default(1) int version,
 *   }) = _SessionData;
 * 
 *   factory SessionData.fromJson(Map<String, dynamic> json) =>
 *       _$SessionDataFromJson(json);
 * }
 * ```
 */
export interface SessionData {
  /** Access token */
  access_token: string;
  /** Refresh token */
  refresh_token: string;
  /** 過期時間（ISO 8601 格式） */
  expires_at: string;
  /** 使用者 ID */
  user_id: string;
  /** 資料格式版本（目前 1） */
  version: number;
}

// ============================================================================
// 資料庫實體型別（僅供後端使用）
// ============================================================================

/**
 * 註冊請求資料庫記錄
 */
export interface RegistrationRequest {
  /** UUID */
  id: string;
  /** Email（小寫） */
  email: string;
  /** 使用者姓名 */
  name: string;
  /** 密碼 bcrypt hash */
  password_hash: string;
  /** 建立時間 */
  created_at: Date;
  /** 過期時間（created_at + 30 分鐘） */
  expires_at: Date;
}

/**
 * 驗證碼狀態列舉
 */
export enum VerificationStatus {
  PENDING = 'pending',
  VERIFIED = 'verified',
  LOCKED = 'locked',
  EXPIRED = 'expired',
}

/**
 * 驗證碼資料庫記錄
 */
export interface VerificationCode {
  /** UUID */
  id: string;
  /** 關聯的 Email */
  email: string;
  /** 驗證碼 bcrypt hash */
  code: string;
  /** 錯誤嘗試次數（0-5） */
  attempt_count: number;
  /** 最大嘗試次數（固定 5） */
  max_attempts: number;
  /** 驗證碼狀態 */
  status: VerificationStatus;
  /** 建立時間 */
  created_at: Date;
  /** 過期時間（created_at + 5 分鐘） */
  expires_at: Date;
  /** 驗證成功時間（可為 null） */
  verified_at: Date | null;
  /** 最後嘗試時間（可為 null） */
  last_attempt_at: Date | null;
}

/**
 * 使用者擴充資料（public.user_profiles）
 */
export interface UserProfile {
  /** FK to auth.users.id */
  user_id: string;
  /** 使用者姓名 */
  name: string;
  /** 建立時間 */
  created_at: Date;
  /** 更新時間（觸發器自動維護） */
  updated_at: Date;
}

// ============================================================================
// Email 模板型別（Resend API）
// ============================================================================

/**
 * 驗證碼 Email 模板參數
 */
export interface VerificationEmailParams {
  /** 收件人 Email */
  to: string;
  /** 使用者姓名 */
  name: string;
  /** 6 位數驗證碼 */
  code: string;
  /** 驗證碼有效分鐘數（預設 5） */
  valid_minutes?: number;
}

/**
 * Resend API 發送請求
 */
export interface ResendSendEmailRequest {
  /** 寄件人（需經過 Resend 驗證） */
  from: string;
  /** 收件人 */
  to: string | string[];
  /** Email 主旨 */
  subject: string;
  /** HTML 內容 */
  html?: string;
  /** 純文字內容 */
  text?: string;
  /** 標籤（用於分類） */
  tags?: Array<{ name: string; value: string }>;
}

/**
 * Resend API 發送回應
 */
export interface ResendSendEmailResponse {
  /** Email ID */
  id: string;
}

/**
 * Resend API 錯誤回應
 */
export interface ResendErrorResponse {
  /** 錯誤訊息 */
  message: string;
  /** 錯誤名稱 */
  name: string;
}

// ============================================================================
// 驗證相關輔助型別
// ============================================================================

/**
 * 密碼強度驗證結果
 */
export interface PasswordValidation {
  /** 是否有效 */
  valid: boolean;
  /** 錯誤訊息（僅當 valid = false） */
  errors: string[];
  /** 強度評分（0-4，0=弱，4=強） */
  strength: number;
}

/**
 * Email 格式驗證結果
 */
export interface EmailValidation {
  /** 是否有效 */
  valid: boolean;
  /** 錯誤訊息（僅當 valid = false） */
  error?: string;
}

// ============================================================================
// 前端狀態管理型別（供 Flutter 參考）
// ============================================================================

/**
 * 認證狀態列舉（Flutter Riverpod 使用）
 * 
 * **Flutter 對應**:
 * ```dart
 * enum AuthStatus {
 *   initial,      // 初始狀態
 *   authenticated, // 已登入
 *   unauthenticated, // 未登入
 *   loading,      // 載入中
 * }
 * ```
 */
export enum AuthStatus {
  INITIAL = 'initial',
  AUTHENTICATED = 'authenticated',
  UNAUTHENTICATED = 'unauthenticated',
  LOADING = 'loading',
}

/**
 * 認證狀態資料（Flutter Riverpod 使用）
 * 
 * **Flutter 對應**:
 * ```dart
 * @freezed
 * class AuthState with _$AuthState {
 *   const factory AuthState({
 *     required AuthStatus status,
 *     User? user,
 *     Session? session,
 *     String? errorMessage,
 *   }) = _AuthState;
 * 
 *   factory AuthState.initial() => const AuthState(
 *     status: AuthStatus.initial,
 *   );
 * }
 * ```
 */
export interface AuthState {
  /** 認證狀態 */
  status: AuthStatus;
  /** 使用者資訊（已登入時） */
  user?: User;
  /** Session 資訊（已登入時） */
  session?: Session;
  /** 錯誤訊息（發生錯誤時） */
  error_message?: string;
}

// ============================================================================
// 常數定義
// ============================================================================

/**
 * 應用程式常數
 */
export const APP_CONSTANTS = {
  /** 密碼最小長度 */
  PASSWORD_MIN_LENGTH: 8,
  /** 密碼最大長度 */
  PASSWORD_MAX_LENGTH: 20,
  /** 姓名最大長度 */
  NAME_MAX_LENGTH: 50,
  /** 驗證碼長度 */
  VERIFICATION_CODE_LENGTH: 6,
  /** 驗證碼有效期（分鐘） */
  VERIFICATION_CODE_EXPIRY_MINUTES: 5,
  /** 驗證碼最大嘗試次數 */
  VERIFICATION_CODE_MAX_ATTEMPTS: 5,
  /** 驗證碼重新發送冷卻時間（秒） */
  VERIFICATION_CODE_RESEND_COOLDOWN_SECONDS: 60,
  /** 註冊請求過期時間（分鐘） */
  REGISTRATION_REQUEST_EXPIRY_MINUTES: 30,
  /** Access token 有效期（秒） */
  ACCESS_TOKEN_EXPIRY_SECONDS: 3600,
  /** Refresh token 有效期（天） */
  REFRESH_TOKEN_EXPIRY_DAYS: 30,
  /** Session 自動刷新提前時間（分鐘） */
  SESSION_REFRESH_BEFORE_EXPIRY_MINUTES: 5,
} as const;

/**
 * Email 模板常數
 */
export const EMAIL_CONSTANTS = {
  /** 寄件人名稱 */
  SENDER_NAME: 'Family Accounting',
  /** 寄件人 Email（需與 Resend 驗證網域一致） */
  SENDER_EMAIL: 'noreply@yourdomain.com',
  /** 驗證碼 Email 主旨 */
  VERIFICATION_SUBJECT: '【Family Accounting】Email 驗證碼',
  /** 品牌主色（綠色） */
  BRAND_COLOR: '#00A86B',
} as const;

/**
 * API 端點常數（相對路徑）
 */
export const API_ENDPOINTS = {
  REGISTER: '/auth/register',
  VERIFY_CODE: '/auth/verify-code',
  RESEND_CODE: '/auth/resend-code',
  LOGIN: '/auth/login',
  LOGOUT: '/auth/logout',
  REFRESH_TOKEN: '/auth/refresh-token',
  GET_CURRENT_USER: '/auth/me',
} as const;

// ============================================================================
// Type Guards（型別守衛函式）
// ============================================================================

/**
 * 檢查是否為有效的 API 回應
 */
export function isApiResponse(value: unknown): value is ApiResponse {
  return (
    typeof value === 'object' &&
    value !== null &&
    'success' in value &&
    typeof (value as ApiResponse).success === 'boolean'
  );
}

/**
 * 檢查是否為錯誤回應
 */
export function isErrorResponse(value: unknown): value is ApiResponse<never> {
  return (
    isApiResponse(value) &&
    value.success === false &&
    'error' in value &&
    typeof value.error === 'object'
  );
}

/**
 * 檢查是否為有效的 Session
 */
export function isValidSession(session: Session | null | undefined): session is Session {
  if (!session) return false;
  
  const now = Math.floor(Date.now() / 1000);
  return (
    typeof session.access_token === 'string' &&
    session.access_token.length > 0 &&
    typeof session.expires_at === 'number' &&
    session.expires_at > now
  );
}

/**
 * 檢查 Session 是否即將過期（5 分鐘內）
 */
export function isSessionNearExpiry(session: Session): boolean {
  const now = Math.floor(Date.now() / 1000);
  const buffer = APP_CONSTANTS.SESSION_REFRESH_BEFORE_EXPIRY_MINUTES * 60;
  return session.expires_at - now < buffer;
}

// ============================================================================
// 工具函式型別
// ============================================================================

/**
 * bcrypt hash 函式型別
 */
export type BcryptHashFunction = (
  plainText: string,
  costFactor?: number
) => Promise<string>;

/**
 * bcrypt compare 函式型別
 */
export type BcryptCompareFunction = (
  plainText: string,
  hash: string
) => Promise<boolean>;

/**
 * 產生隨機驗證碼函式型別
 */
export type GenerateVerificationCodeFunction = (length?: number) => string;

/**
 * Email 驗證函式型別
 */
export type ValidateEmailFunction = (email: string) => EmailValidation;

/**
 * 密碼驗證函式型別
 */
export type ValidatePasswordFunction = (password: string) => PasswordValidation;

// ============================================================================
// 匯出全部
// ============================================================================

export type {
  // API Response
  ApiResponse,
  ApiError,
  
  // Registration
  RegisterRequest,
  RegisterResponse,
  VerifyCodeRequest,
  VerifyCodeResponse,
  ResendCodeRequest,
  ResendCodeResponse,
  
  // Authentication
  LoginRequest,
  LoginResponse,
  LogoutResponse,
  
  // Session
  RefreshTokenRequest,
  RefreshTokenResponse,
  UserInfoResponse,
  Session,
  SessionData,
  
  // Entities
  User,
  UserDetail,
  RegistrationRequest,
  VerificationCode,
  UserProfile,
  
  // Email
  VerificationEmailParams,
  ResendSendEmailRequest,
  ResendSendEmailResponse,
  ResendErrorResponse,
  
  // Validation
  PasswordValidation,
  EmailValidation,
  
  // State
  AuthState,
  
  // Utility Functions
  BcryptHashFunction,
  BcryptCompareFunction,
  GenerateVerificationCodeFunction,
  ValidateEmailFunction,
  ValidatePasswordFunction,
};

export {
  ErrorCode,
  VerificationStatus,
  AuthStatus,
  APP_CONSTANTS,
  EMAIL_CONSTANTS,
  API_ENDPOINTS,
  isApiResponse,
  isErrorResponse,
  isValidSession,
  isSessionNearExpiry,
};
