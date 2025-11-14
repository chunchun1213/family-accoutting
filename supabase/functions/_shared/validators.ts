import { APP_CONSTANTS } from './types.ts';

export interface ValidationError {
  field: string;
  message: string;
}

export class InputValidator {
  /**
   * Validate email format
   */
  static validateEmail(email: string): ValidationError | null {
    if (!email || typeof email !== 'string') {
      return { field: 'email', message: 'Email is required' };
    }

    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    if (!emailRegex.test(email.trim())) {
      return { field: 'email', message: 'Invalid email format' };
    }

    return null;
  }

  /**
   * Validate password strength
   * Requirements: 8-20 chars, must include uppercase, lowercase, and number
   */
  static validatePassword(password: string): ValidationError | null {
    if (!password || typeof password !== 'string') {
      return { field: 'password', message: 'Password is required' };
    }

    const { MIN_LENGTH, MAX_LENGTH, REQUIRE_UPPERCASE, REQUIRE_LOWERCASE, REQUIRE_NUMBER } = APP_CONSTANTS.PASSWORD;

    if (password.length < MIN_LENGTH || password.length > MAX_LENGTH) {
      return {
        field: 'password',
        message: `Password must be between ${MIN_LENGTH} and ${MAX_LENGTH} characters`,
      };
    }

    if (REQUIRE_UPPERCASE && !/[A-Z]/.test(password)) {
      return { field: 'password', message: 'Password must contain at least one uppercase letter' };
    }

    if (REQUIRE_LOWERCASE && !/[a-z]/.test(password)) {
      return { field: 'password', message: 'Password must contain at least one lowercase letter' };
    }

    if (REQUIRE_NUMBER && !/[0-9]/.test(password)) {
      return { field: 'password', message: 'Password must contain at least one number' };
    }

    return null;
  }

  /**
   * Validate name (1-50 characters)
   */
  static validateName(name: string): ValidationError | null {
    if (!name || typeof name !== 'string') {
      return { field: 'name', message: 'Name is required' };
    }

    const trimmedName = name.trim();
    if (trimmedName.length === 0 || trimmedName.length > 50) {
      return { field: 'name', message: 'Name must be between 1 and 50 characters' };
    }

    return null;
  }

  /**
   * Validate verification code (6 digits)
   */
  static validateVerificationCode(code: string): ValidationError | null {
    if (!code || typeof code !== 'string') {
      return { field: 'code', message: 'Verification code is required' };
    }

    const { LENGTH } = APP_CONSTANTS.VERIFICATION_CODE;
    if (!/^\d{6}$/.test(code.trim())) {
      return { field: 'code', message: `Verification code must be ${LENGTH} digits` };
    }

    return null;
  }

  /**
   * Validate registration request
   */
  static validateRegistrationRequest(data: { email?: unknown; name?: unknown; password?: unknown }): ValidationError[] {
    const errors: ValidationError[] = [];

    if (typeof data.email === 'string') {
      const emailError = this.validateEmail(data.email);
      if (emailError) errors.push(emailError);
    } else {
      errors.push({ field: 'email', message: 'Email is required' });
    }

    if (typeof data.name === 'string') {
      const nameError = this.validateName(data.name);
      if (nameError) errors.push(nameError);
    } else {
      errors.push({ field: 'name', message: 'Name is required' });
    }

    if (typeof data.password === 'string') {
      const passwordError = this.validatePassword(data.password);
      if (passwordError) errors.push(passwordError);
    } else {
      errors.push({ field: 'password', message: 'Password is required' });
    }

    return errors;
  }

  /**
   * Validate login request
   */
  static validateLoginRequest(data: { email?: unknown; password?: unknown }): ValidationError[] {
    const errors: ValidationError[] = [];

    if (typeof data.email === 'string') {
      const emailError = this.validateEmail(data.email);
      if (emailError) errors.push(emailError);
    } else {
      errors.push({ field: 'email', message: 'Email is required' });
    }

    if (typeof data.password === 'string') {
      const passwordError = this.validatePassword(data.password);
      if (passwordError) errors.push(passwordError);
    } else {
      errors.push({ field: 'password', message: 'Password is required' });
    }

    return errors;
  }

  /**
   * Validate verify code request
   */
  static validateVerifyCodeRequest(data: { email?: unknown; code?: unknown }): ValidationError[] {
    const errors: ValidationError[] = [];

    if (typeof data.email === 'string') {
      const emailError = this.validateEmail(data.email);
      if (emailError) errors.push(emailError);
    } else {
      errors.push({ field: 'email', message: 'Email is required' });
    }

    if (typeof data.code === 'string') {
      const codeError = this.validateVerificationCode(data.code);
      if (codeError) errors.push(codeError);
    } else {
      errors.push({ field: 'code', message: 'Verification code is required' });
    }

    return errors;
  }
}
