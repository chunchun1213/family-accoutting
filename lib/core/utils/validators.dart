class Validators {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '請輸入 Email';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return '請輸入有效的 Email 地址';
    }
    
    return null;
  }

  /// Validate password strength (8-20 chars, must include uppercase, lowercase, and number)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '請輸入密碼';
    }
    
    if (value.length < 8 || value.length > 20) {
      return '密碼長度需要 8-20 字元';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return '密碼需要包含大寫字母';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return '密碼需要包含小寫字母';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return '密碼需要包含數字';
    }
    
    return null;
  }

  /// Validate name (1-50 characters)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return '請輸入姓名';
    }
    
    if (value.length > 50) {
      return '姓名不能超過 50 字元';
    }
    
    return null;
  }

  /// Validate verification code (6 digits)
  static String? validateVerificationCode(String? value) {
    if (value == null || value.isEmpty) {
      return '請輸入驗證碼';
    }
    
    if (value.length != 6) {
      return '驗證碼應為 6 位數字';
    }
    
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
      return '驗證碼應只包含數字';
    }
    
    return null;
  }

  /// Check password strength and return detailed feedback
  static Map<String, bool> checkPasswordStrength(String password) {
    return {
      'hasMinLength': password.length >= 8,
      'hasMaxLength': password.length <= 20,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasNumber': password.contains(RegExp(r'[0-9]')),
    };
  }

  /// Check if password meets all requirements
  static bool isPasswordStrong(String password) {
    final strength = checkPasswordStrength(password);
    return strength.values.every((element) => element);
  }
}
