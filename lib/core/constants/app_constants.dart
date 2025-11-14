class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'https://your-project-id.supabase.co/functions/v1';

  // Authentication Rules
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 20;
  static const int nameMaxLength = 50;
  static const int verificationCodeLength = 6;

  // Verification Code Settings
  static const int verificationCodeValidityMinutes = 5;
  static const int verificationCodeMaxAttempts = 5;
  static const int verificationCodeResendCooldownSeconds = 60;

  // Session Settings
  static const int sessionValidityDays = 30;
  static const int tokenRefreshBeforeExpiryMinutes = 5;

  // Timeout Settings
  static const Duration defaultTimeoutDuration = Duration(seconds: 30);
  static const Duration registrationTimeoutDuration = Duration(seconds: 60);

  // API Endpoints
  static const String authRegisterEndpoint = '/auth/register';
  static const String authVerifyCodeEndpoint = '/auth/verify-code';
  static const String authLoginEndpoint = '/auth/login';
  static const String authLogoutEndpoint = '/auth/logout';
  static const String authResendCodeEndpoint = '/auth/resend-code';
  static const String authRefreshTokenEndpoint = '/auth/refresh-token';
  static const String authMeEndpoint = '/auth/me';

  // Error Messages
  static const Map<String, String> errorMessages = {
    'INVALID_EMAIL': '請輸入有效的 Email 地址',
    'EMAIL_EXISTS': '該 Email 已被使用',
    'INVALID_PASSWORD': '密碼需要 8-20 字元，包含大小寫字母和數字',
    'INVALID_NAME': '姓名需要 1-50 字元',
    'INVALID_CODE': '驗證碼無效',
    'CODE_EXPIRED': '驗證碼已過期',
    'CODE_LOCKED': '驗證碼已鎖定，請重新發送',
    'INVALID_CREDENTIALS': 'Email 或密碼錯誤',
    'EMAIL_NOT_VERIFIED': '請先驗證您的 Email',
    'RATE_LIMIT': '請求過於頻繁，請稍候後重試',
    'NETWORK_ERROR': '網路連線錯誤',
    'UNKNOWN_ERROR': '發生未知錯誤，請稍後重試',
  };
}
