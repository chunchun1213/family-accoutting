export interface EmailOptions {
  to: string;
  subject: string;
  html: string;
}

export class EmailService {
  private static readonly apiKey = Deno.env.get('RESEND_API_KEY');
  private static readonly apiUrl = 'https://api.resend.com/emails';
  private static readonly fromEmail = Deno.env.get('VERIFICATION_EMAIL_FROM') || 'noreply@example.com';
  private static readonly isLocal = Deno.env.get('SUPABASE_URL')?.includes('127.0.0.1') || Deno.env.get('SUPABASE_URL')?.includes('localhost');

  /**
   * Send verification code email using Resend API or Mailpit (local)
   */
  static async sendVerificationCode(email: string, code: string, expiresInMinutes: number): Promise<boolean> {
    const html = this.generateVerificationEmailTemplate(code, expiresInMinutes);

    // For local development, use Mailpit SMTP (just return true and log code)
    if (this.isLocal || !this.apiKey) {
      console.log('========== LOCAL EMAIL (Mailpit) ==========');
      console.log('TO:', email);
      console.log('SUBJECT: 家庭記帳系統 - Email 驗證碼');
      console.log('VERIFICATION CODE:', code);
      console.log('EXPIRES IN:', expiresInMinutes, 'minutes');
      console.log('==========================================');
      return true; // Simulate success for local testing
    }

    return this.sendEmail({
      to: email,
      subject: '家庭記帳系統 - Email 驗證碼',
      html,
    });
  }

  /**
   * Send email using Resend API
   */
  static async sendEmail(options: EmailOptions): Promise<boolean> {
    if (!this.apiKey) {
      console.error('RESEND_API_KEY environment variable not set');
      return false;
    }

    try {
      const response = await fetch(this.apiUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: this.fromEmail,
          to: options.to,
          subject: options.subject,
          html: options.html,
        }),
      });

      if (!response.ok) {
        const error = await response.text();
        console.error('Email send failed:', error);
        return false;
      }

      const result = await response.json();
      console.log('Email sent successfully:', result.id);
      return true;
    } catch (error) {
      console.error('Email send error:', error);
      return false;
    }
  }

  /**
   * Generate HTML template for verification code email
   */
  private static generateVerificationEmailTemplate(code: string, expiresInMinutes: number): string {
    return `
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      color: #333;
      line-height: 1.6;
      margin: 0;
      padding: 0;
      background-color: #f5f5f5;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #fff;
      padding: 40px 20px;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .header {
      text-align: center;
      margin-bottom: 30px;
    }
    .header h1 {
      margin: 0;
      font-size: 24px;
      color: #2c3e50;
    }
    .content {
      margin: 30px 0;
    }
    .code-box {
      background-color: #f8f9fa;
      border: 2px solid #e9ecef;
      border-radius: 4px;
      padding: 20px;
      text-align: center;
      margin: 20px 0;
    }
    .verification-code {
      font-size: 32px;
      font-weight: bold;
      letter-spacing: 2px;
      color: #2c3e50;
      font-family: 'Courier New', monospace;
    }
    .expiry-info {
      color: #666;
      font-size: 14px;
      margin-top: 10px;
    }
    .warning {
      background-color: #fff3cd;
      border-left: 4px solid #ffc107;
      padding: 12px 15px;
      margin: 20px 0;
      border-radius: 4px;
      color: #856404;
      font-size: 14px;
    }
    .footer {
      text-align: center;
      margin-top: 30px;
      padding-top: 20px;
      border-top: 1px solid #e9ecef;
      color: #666;
      font-size: 12px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>家庭記帳系統</h1>
      <p>Email 驗證</p>
    </div>

    <div class="content">
      <p>感謝您註冊家庭記帳系統！</p>
      <p>請使用以下驗證碼完成您的 Email 驗證：</p>

      <div class="code-box">
        <div class="verification-code">${code}</div>
        <div class="expiry-info">此驗證碼有效期為 ${expiresInMinutes} 分鐘</div>
      </div>

      <div class="warning">
        <strong>安全提示：</strong> 請勿與他人分享此驗證碼。我們的工作人員永遠不會要求您提供此代碼。
      </div>

      <p>如果您未要求此驗證碼，請忽略此電子郵件。</p>
    </div>

    <div class="footer">
      <p>© 2024 家庭記帳系統. All rights reserved.</p>
      <p>This is an automated email. Please do not reply to this message.</p>
    </div>
  </div>
</body>
</html>
    `;
  }
}

export default EmailService;
