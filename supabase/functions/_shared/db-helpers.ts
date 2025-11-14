import { compare, hash } from 'https://deno.land/x/bcrypt@v0.4.1/mod.ts';
import { APP_CONSTANTS } from './types.ts';

export class DbHelpers {
  /**
   * Generate a 6-digit verification code
   */
  static generateVerificationCode(): string {
    const code = Math.floor(Math.random() * 1000000);
    return code.toString().padStart(6, '0');
  }

  /**
   * Hash a string using bcrypt
   */
  static async hashPassword(password: string): Promise<string> {
    return await hash(password);
  }

  /**
   * Compare a plain text password with a bcrypt hash
   */
  static async comparePassword(password: string, hash: string): Promise<boolean> {
    return await compare(password, hash);
  }

  /**
   * Hash a verification code using bcrypt
   */
  static async hashCode(code: string): Promise<string> {
    return await hash(code);
  }

  /**
   * Compare a verification code with a bcrypt hash
   */
  static async compareCode(code: string, hash: string): Promise<boolean> {
    return await compare(code, hash);
  }

  /**
   * Generate expiration timestamp (minutes from now)
   */
  static getExpirationTime(minutes: number): string {
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + minutes);
    return expiresAt.toISOString();
  }

  /**
   * Check if a timestamp is expired
   */
  static isExpired(expiresAtISO: string): boolean {
    return new Date(expiresAtISO) < new Date();
  }

  /**
   * Calculate remaining attempts for verification code
   */
  static getRemainingAttempts(attemptCount: number): number {
    const remaining = APP_CONSTANTS.VERIFICATION_CODE.MAX_ATTEMPTS - attemptCount;
    return Math.max(0, remaining);
  }

  /**
   * Check if verification code is locked (max attempts exceeded)
   */
  static isCodeLocked(attemptCount: number): boolean {
    return attemptCount >= APP_CONSTANTS.VERIFICATION_CODE.MAX_ATTEMPTS;
  }

  /**
   * Format verification code expiration time in Chinese
   */
  static formatExpirationTime(expiresAtISO: string): string {
    const now = new Date();
    const expiresAt = new Date(expiresAtISO);
    const minutesRemaining = Math.floor((expiresAt.getTime() - now.getTime()) / (1000 * 60));

    if (minutesRemaining <= 0) {
      return '已過期';
    } else if (minutesRemaining < 1) {
      const secondsRemaining = Math.floor((expiresAt.getTime() - now.getTime()) / 1000);
      return `${secondsRemaining} 秒後過期`;
    } else if (minutesRemaining === 1) {
      return '1 分鐘後過期';
    } else {
      return `${minutesRemaining} 分鐘後過期`;
    }
  }

  /**
   * Generate UUID v4
   */
  static generateUUID(): string {
    return crypto.randomUUID();
  }
}

export default DbHelpers;
