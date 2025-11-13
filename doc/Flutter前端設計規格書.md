# 家庭記帳 APP - Flutter 前端設計規格書

> **Figma 設計檔連結**: https://www.figma.com/design/Mfp1UVqT4L2TrkEmhhXkol/%E5%AE%B6%E5%BA%AD%E8%A8%98%E5%B8%B3APP  
> **版本**: v1.0.0  
> **最後更新**: 2025-11-13  
> **設計系統**: Material Design 3 + Custom Theme

---

## 📋 目錄

1. [設計系統](#設計系統)
2. [頁面規格](#頁面規格)
3. [元件規格](#元件規格)
4. [設計資源](#設計資源)
5. [開發注意事項](#開發注意事項)

---

## 🎨 設計系統

### 色彩規範 (Color Palette)

#### 主色調 (Primary Colors)
```dart
// lib/theme/colors.dart
class AppColors {
  // Primary - 品牌主色 (淺綠色)
  static const Color primary = Color(0xFF86EFCC);
  static const Color primaryLight = Color(0xFFF0FCF8);
  static const Color primaryDark = Color(0xFF01A362);
  
  // Secondary - 輔助色
  static const Color secondary = Color(0xFFF9FAFB);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0A0A0A);
  static const Color textSecondary = Color(0xFF4A5465);
  static const Color textTertiary = Color(0xFF6C7483);
  static const Color textPlaceholder = Color(0xFF717682);
  
  // Background Colors
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF3F4F6);
  
  // Border Colors
  static const Color border = Color(0xFFD1D5DC);
  static const Color borderLight = Color(0xFFE5E7EB);
  
  // Status Colors
  static const Color success = Color(0xFF01A362);
  static const Color successLight = Color(0xFFF0FCF8);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFF3B82F6);
  
  // Shadow Colors
  static const Color shadow = Color(0x1A000000); // 10% opacity
}
```

### 字體規範 (Typography)

```dart
// lib/theme/typography.dart
class AppTypography {
  static const String fontFamily = 'Inter';
  
  // Heading Styles
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500, // Medium
    height: 1.4, // 140%
    letterSpacing: -0.44922,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500, // Medium
    height: 1.333, // 133.33%
    letterSpacing: 0.07031,
    color: AppColors.textPrimary,
  );
  
  // Body Text Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500, // Medium
    height: 1.5, // 150%
    letterSpacing: -0.3125,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5, // 150%
    letterSpacing: -0.3125,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 1.4286, // 142.86%
    letterSpacing: -0.15039,
    color: AppColors.textSecondary,
  );
  
  // Label Styles
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    height: 1.4286, // 142.86%
    letterSpacing: -0.15039,
    color: AppColors.textSecondary,
  );
  
  // Button Text Styles
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    height: 1.4286, // 142.86%
    letterSpacing: 0.19961,
    textBaseline: TextBaseline.alphabetic,
  );
  
  // Input Text Styles
  static const TextStyle input = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    height: 1.209, // 120.9%
    letterSpacing: -0.3125,
    color: AppColors.textPlaceholder,
  );
  
  // Verification Code Style
  static const TextStyle verificationCode = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w400, // Regular
    height: 1.21, // 121%
    letterSpacing: 15.0,
    color: AppColors.textPlaceholder,
  );
}
```

### 間距規範 (Spacing)

```dart
// lib/theme/spacing.dart
class AppSpacing {
  // Base spacing unit: 8px
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  
  // Specific spacing from design
  static const double padding = 15.989; // Standard padding
  static const double itemSpacing = 7.986; // Gap between items
  static const double buttonSpacing = 23.993; // Space between major sections
  static const double formSpacing = 7.986; // Space between form fields
}
```

### 圓角規範 (Border Radius)

```dart
// lib/theme/radius.dart
class AppRadius {
  static const double none = 0.0;
  static const double sm = 8.0;
  static const double md = 10.0;
  static const double lg = 16.0;
  static const double full = 9999.0; // Circular
}
```

### 陰影規範 (Shadows)

```dart
// lib/theme/shadows.dart
class AppShadows {
  // Card Shadow (登入卡片、首頁卡片)
  static List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
  ];
  
  // Button Shadow (主要按鈕)
  static List<BoxShadow> button = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
  ];
}
```

---

## 📱 頁面規格

### 1. 登入頁 (Login Page)

**檔案路徑**: `lib/pages/auth/login_page.dart`  
**Figma Node ID**: `1:88`

#### 螢幕規格
- 寬度: 392px
- 高度: 852px
- 背景色: `#F9FAFB`

#### 頁面結構

```
LoginPage
├── Header (品牌標題)
│   └── "登入" (Heading 1)
├── Welcome Card (歡迎卡片)
│   ├── User Icon (圓形背景圖示)
│   ├── "歡迎回來" (Heading 2)
│   └── "登入您的帳戶以繼續使用" (Body Text)
└── Login Form Card (登入表單卡片)
    ├── Email Input Field
    │   ├── Label: "Email"
    │   └── Placeholder: "example@email.com"
    ├── Password Input Field
    │   ├── Label: "密碼"
    │   ├── Placeholder: "請輸入密碼"
    │   └── Toggle Icon (顯示/隱藏密碼)
    ├── Login Button
    │   └── Text: "登入" (全大寫)
    └── Register Link
        └── Text: "還沒有帳戶？註冊"
```

#### 元件規格

##### Header
```dart
Container(
  color: AppColors.primary,
  padding: EdgeInsets.symmetric(
    horizontal: 15.989,
    vertical: 15.989,
  ),
  child: Text('登入', style: AppTypography.heading1),
)
```

##### Welcome Card
```dart
Container(
  margin: EdgeInsets.all(15.989),
  padding: EdgeInsets.symmetric(
    horizontal: 31.996,
    vertical: 31.996,
  ),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(10),
    boxShadow: AppShadows.card,
  ),
  child: Column(
    children: [
      // User Icon with circular background
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          'assets/icons/login-user-icon.svg',
          width: 48,
          height: 48,
        ),
      ),
      SizedBox(height: 23.993),
      Text('歡迎回來', style: AppTypography.heading2),
      SizedBox(height: 11.996),
      Text(
        '登入您的帳戶以繼續使用',
        style: AppTypography.bodySmall,
      ),
    ],
  ),
)
```

##### Email Input Field
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Email', style: AppTypography.label),
    SizedBox(height: 7.986),
    TextField(
      decoration: InputDecoration(
        hintText: 'example@email.com',
        hintStyle: AppTypography.input,
        filled: true,
        fillColor: Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Color(0xFFD1D5DC),
            width: 1.14081,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
      ),
    ),
  ],
)
```

##### Password Input Field
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('密碼', style: AppTypography.label),
    SizedBox(height: 7.986),
    TextField(
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: '請輸入密碼',
        hintStyle: AppTypography.input,
        filled: true,
        fillColor: Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Color(0xFFD1D5DC),
            width: 1.14081,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        suffixIcon: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/password-toggle-icon.svg',
            width: 20,
            height: 20,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    ),
  ],
)
```

##### Login Button
```dart
Container(
  width: double.infinity,
  height: 55.989,
  decoration: BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(8),
    boxShadow: AppShadows.button,
  ),
  child: ElevatedButton(
    onPressed: _handleLogin,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.black,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    child: Text(
      '登入',
      style: AppTypography.button.copyWith(
        color: Colors.black,
      ),
    ),
  ),
)
```

##### Register Link
```dart
TextButton(
  onPressed: _navigateToRegister,
  child: Text(
    '還沒有帳戶？註冊',
    style: AppTypography.button.copyWith(
      color: AppColors.primary,
    ),
  ),
)
```

#### 設計資源
- **圖示**: `design-assets/icons/login-user-icon.svg`
- **切換密碼圖示**: `design-assets/icons/password-toggle-icon.svg`

---

### 2. 首頁 (Dashboard/Home Page)

**檔案路徑**: `lib/pages/home/home_page.dart`  
**Figma Node ID**: `1:125`

#### 螢幕規格
- 寬度: 392px
- 高度: 852px
- 背景色: `#F9FAFB`

#### 頁面結構

```
HomePage
├── Header (應用程式標題欄)
│   ├── Menu Icon (漢堡選單)
│   ├── "記帳App" (Heading 1)
│   └── Notification Icon (通知鈴鐺)
└── Content Card (內容卡片)
    ├── Feature Icon (日曆圖示 - 圓形背景)
    ├── "功能開發中" (Heading 2)
    └── "記帳功能即將上線，敬請期待！" (Body Text)
```

#### 元件規格

##### Header
```dart
Container(
  color: AppColors.primary,
  padding: EdgeInsets.symmetric(
    horizontal: 15.989,
  ),
  height: 63.957,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/menu-icon.svg',
              width: 24,
              height: 24,
            ),
            onPressed: _openDrawer,
          ),
          SizedBox(width: 11.996),
          Text('記帳App', style: AppTypography.heading1),
        ],
      ),
      IconButton(
        icon: SvgPicture.asset(
          'assets/icons/notification-bell-icon.svg',
          width: 20,
          height: 20,
        ),
        onPressed: _openNotifications,
      ),
    ],
  ),
)
```

##### Content Card (功能開發中)
```dart
Container(
  margin: EdgeInsets.all(15.989),
  padding: EdgeInsets.symmetric(
    horizontal: 31.996,
    vertical: 31.996,
  ),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(10),
    boxShadow: AppShadows.card,
  ),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Calendar Icon with circular background (15% opacity)
      Container(
        width: 175.988,
        height: 175.988,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/home-calendar-icon.svg',
            width: 96,
            height: 96,
          ),
        ),
      ),
      SizedBox(height: 23.993),
      Text(
        '功能開發中',
        style: AppTypography.heading2,
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 11.996),
      Text(
        '記帳功能即將上線，敬請期待！',
        style: AppTypography.bodyMedium,
        textAlign: TextAlign.center,
      ),
    ],
  ),
)
```

#### 設計資源
- **日曆圖示**: `design-assets/icons/home-calendar-icon.svg`
- **選單圖示**: `design-assets/icons/menu-icon.svg`
- **通知圖示**: `design-assets/icons/notification-bell-icon.svg`

---

### 3. Email 驗證頁 (Email Verification Page)

**檔案路徑**: `lib/pages/auth/email_verification_page.dart`  
**Figma Node ID**: `2:503`

#### 螢幕規格
- 寬度: 392px
- 高度: 852px
- 背景色: `#F9FAFB`

#### 頁面結構

```
EmailVerificationPage
├── Header
│   ├── Back Button (返回箭頭)
│   └── "Email驗證" (Heading 1)
├── Instruction Card (說明卡片)
│   ├── Email Icon (圓形背景圖示)
│   ├── "驗證您的 Email" (Heading 2)
│   ├── "我們已發送 6 位數驗證碼至" (Body Text)
│   └── Email Address (顯示使用者 Email)
└── Verification Form Card (驗證表單卡片)
    ├── Verification Code Input
    │   ├── Label: "驗證碼"
    │   └── 6-digit Input Field
    ├── Timer Warning (倒數計時提示)
    │   ├── Info Icon
    │   └── "驗證碼將於 4:52 後過期"
    ├── Verify Button (驗證按鈕 - 50% opacity when disabled)
    └── Resend Button (重新發送按鈕)
```

#### 元件規格

##### Header
```dart
Container(
  color: AppColors.primary,
  padding: EdgeInsets.symmetric(horizontal: 8.004),
  height: 63.957,
  child: Row(
    children: [
      IconButton(
        icon: SvgPicture.asset(
          'assets/icons/back-arrow-icon.svg',
          width: 24,
          height: 24,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      SizedBox(width: 15.989),
      Text('Email驗證', style: AppTypography.heading1),
    ],
  ),
)
```

##### Instruction Card
```dart
Container(
  margin: EdgeInsets.all(15.989),
  padding: EdgeInsets.symmetric(
    horizontal: 31.996,
    vertical: 31.996,
  ),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(10),
    boxShadow: AppShadows.card,
  ),
  child: Column(
    children: [
      // Email Icon with circular background
      Container(
        width: 103.992,
        height: 103.992,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          'assets/icons/email-verification-icon.svg',
          width: 64,
          height: 64,
        ),
      ),
      SizedBox(height: 23.993),
      Text('驗證您的 Email', style: AppTypography.heading2),
      SizedBox(height: 11.996),
      Text(
        '我們已發送 6 位數驗證碼至',
        style: AppTypography.bodySmall,
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 7.986),
      Text(
        'jesse751213@gmail.com', // Dynamic email
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.primary,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  ),
)
```

##### Verification Code Input
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('驗證碼', style: AppTypography.label),
    SizedBox(height: 7.986),
    TextField(
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: AppTypography.verificationCode,
      decoration: InputDecoration(
        hintText: '000000',
        hintStyle: AppTypography.verificationCode,
        filled: true,
        fillColor: Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Color(0xFFD1D5DC),
            width: 1.14081,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        counterText: '', // Hide character counter
      ),
      onChanged: _onCodeChanged,
    ),
  ],
)
```

##### Timer Warning
```dart
Container(
  padding: EdgeInsets.all(17.130),
  decoration: BoxDecoration(
    color: Color(0xFFF9FAFB),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Row(
    children: [
      SvgPicture.asset(
        'assets/icons/info-icon.svg',
        width: 20,
        height: 20,
      ),
      SizedBox(width: 7.986),
      Text(
        '驗證碼將於',
        style: AppTypography.bodySmall,
      ),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          '4:52', // Dynamic timer
          style: AppTypography.label.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
      Text(
        '後過期',
        style: AppTypography.bodySmall,
      ),
    ],
  ),
)
```

##### Verify Button (Disabled State)
```dart
Container(
  width: double.infinity,
  height: 55.989,
  decoration: BoxDecoration(
    color: AppColors.primary.withOpacity(0.5), // 50% opacity
    borderRadius: BorderRadius.circular(8),
    boxShadow: AppShadows.button,
  ),
  child: ElevatedButton(
    onPressed: _isCodeComplete ? _handleVerify : null,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary.withOpacity(0.5),
      foregroundColor: Colors.black,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    child: Text(
      '驗證',
      style: AppTypography.button.copyWith(
        color: Colors.black,
      ),
    ),
  ),
)
```

##### Resend Button
```dart
Container(
  width: double.infinity,
  height: 47.985,
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: Color(0xFFE5E7EB),
      width: 1.14081,
    ),
  ),
  child: TextButton(
    onPressed: _canResend ? _handleResend : null,
    child: Text(
      '重新發送驗證碼',
      style: AppTypography.button.copyWith(
        color: AppColors.primary,
      ),
    ),
  ),
)
```

#### 設計資源
- **郵件圖示**: `design-assets/icons/email-verification-icon.svg`
- **返回箭頭**: `design-assets/icons/back-arrow-icon.svg`
- **資訊圖示**: `design-assets/icons/info-icon.svg`

---

### 4. Email 驗證重新發送頁 (Email Verification Resent Page)

**檔案路徑**: `lib/pages/auth/email_verification_resent_page.dart`  
**Figma Node ID**: `7:2`

#### 頁面結構

與 Email 驗證頁相同，但增加成功提示訊息：

```
EmailVerificationResentPage
├── Header (同上)
├── Instruction Card (同上)
└── Verification Form Card
    ├── Verification Code Input (同上)
    ├── Timer Warning (更新時間: 1:40)
    ├── Success Message (新增)
    │   ├── "驗證碼已重新發送至您的Email"
    │   └── 淡綠色背景 + 綠色邊框
    ├── Verify Button (同上)
    └── Resend Button (同上)
```

#### 元件規格

##### Success Message (驗證碼重新發送提示)
```dart
Container(
  padding: EdgeInsets.symmetric(
    horizontal: 17.130,
    vertical: 17.130,
  ),
  decoration: BoxDecoration(
    color: Color(0xFFF0FCF8), // Success light background
    borderRadius: BorderRadius.circular(10),
    border: Border.all(
      color: Color(0xFFB9F8E3), // Success border
      width: 1.14081,
    ),
  ),
  child: Text(
    '驗證碼已重新發送至您的Email',
    style: AppTypography.bodySmall.copyWith(
      color: Color(0xFF01A362), // Success text color
    ),
  ),
)
```

---

## 🧩 元件規格

### Button Component

#### Primary Button (主要按鈕)
```dart
// lib/widgets/buttons/primary_button.dart
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55.989,
      decoration: BoxDecoration(
        color: isDisabled 
          ? AppColors.primary.withOpacity(0.5)
          : AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppShadows.button,
      ),
      child: ElevatedButton(
        onPressed: isDisabled || isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled 
            ? AppColors.primary.withOpacity(0.5)
            : AppColors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : Text(
              text,
              style: AppTypography.button.copyWith(
                color: Colors.black,
              ),
            ),
      ),
    );
  }
}
```

#### Secondary Button (次要按鈕)
```dart
// lib/widgets/buttons/secondary_button.dart
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 47.985,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFFE5E7EB),
          width: 1.14081,
        ),
      ),
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            )
          : Text(
              text,
              style: AppTypography.button.copyWith(
                color: AppColors.primary,
              ),
            ),
      ),
    );
  }
}
```

### Input Field Component

```dart
// lib/widgets/inputs/text_input_field.dart
class TextInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLength;
  final TextAlign textAlign;
  final TextStyle? style;

  const TextInputField({
    Key? key,
    required this.label,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        SizedBox(height: 7.986),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          maxLength: maxLength,
          textAlign: textAlign,
          style: style ?? AppTypography.input.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.input,
            filled: true,
            fillColor: Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Color(0xFFD1D5DC),
                width: 1.14081,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Color(0xFFD1D5DC),
                width: 1.14081,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 1.14081,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.error,
                width: 1.14081,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            suffixIcon: suffixIcon,
            counterText: maxLength != null ? '' : null,
          ),
        ),
      ],
    );
  }
}
```

### Card Component

```dart
// lib/widgets/cards/app_card.dart
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AppCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.all(15.989),
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: 31.996,
        vertical: 31.996,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}
```

### App Bar Component

```dart
// lib/widgets/app_bars/custom_app_bar.dart
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? AppColors.primary,
      padding: EdgeInsets.symmetric(horizontal: 15.989),
      height: 63.957,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (leading != null) leading!,
              SizedBox(width: 11.996),
              Text(title, style: AppTypography.heading1),
            ],
          ),
          if (actions != null)
            Row(children: actions!),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(63.957);
}
```

---

## 📦 設計資源

### 圖示資源清單

所有圖示均已匯出至 `design-assets/icons/` 目錄：

| 圖示名稱 | 檔案路徑 | 用途 | 尺寸 |
|---------|---------|------|------|
| 登入使用者圖示 | `design-assets/icons/login-user-icon.svg` | 登入頁歡迎卡片 | 48×48 |
| 首頁日曆圖示 | `design-assets/icons/home-calendar-icon.svg` | 首頁功能開發中圖示 | 96×96 |
| Email 驗證圖示 | `design-assets/icons/email-verification-icon.svg` | Email 驗證頁說明圖示 | 64×64 |
| 密碼切換圖示 | `design-assets/icons/password-toggle-icon.svg` | 密碼輸入框顯示/隱藏 | 20×20 |
| 通知鈴鐺圖示 | `design-assets/icons/notification-bell-icon.svg` | 頁面標題欄通知按鈕 | 20×20 |
| 選單圖示 | `design-assets/icons/menu-icon.svg` | 頁面標題欄漢堡選單 | 24×24 |
| 返回箭頭圖示 | `design-assets/icons/back-arrow-icon.svg` | 返回上一頁按鈕 | 24×24 |
| 資訊圖示 | `design-assets/icons/info-icon.svg` | 驗證碼過期提示 | 20×20 |

### Flutter 資源配置

在 `pubspec.yaml` 中加入以下設定：

```yaml
flutter:
  assets:
    # Icons
    - assets/icons/login-user-icon.svg
    - assets/icons/home-calendar-icon.svg
    - assets/icons/email-verification-icon.svg
    - assets/icons/password-toggle-icon.svg
    - assets/icons/notification-bell-icon.svg
    - assets/icons/menu-icon.svg
    - assets/icons/back-arrow-icon.svg
    - assets/icons/info-icon.svg
    
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

### 必要套件

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # SVG 支援
  flutter_svg: ^2.0.9
  
  # 狀態管理 (建議使用)
  provider: ^6.1.1
  # 或使用 Riverpod
  # flutter_riverpod: ^2.4.9
  
  # 路由管理
  go_router: ^13.0.0
  
  # HTTP 請求
  dio: ^5.4.0
  
  # 本地儲存
  shared_preferences: ^2.2.2
  
  # 表單驗證
  flutter_form_builder: ^9.1.1
  form_builder_validators: ^9.1.0
```

---

## 💡 開發注意事項

### 1. 響應式設計
- 設計基準寬度為 **392px**
- 建議使用 `MediaQuery` 或 `LayoutBuilder` 實現響應式佈局
- 考慮不同螢幕尺寸的適配 (小螢幕、平板等)

```dart
// 使用相對尺寸
double screenWidth = MediaQuery.of(context).size.width;
double cardWidth = screenWidth - (15.989 * 2); // 扣除左右邊距
```

### 2. 無障礙設計 (Accessibility)
- 所有可互動元件必須設定 `Semantics`
- 確保色彩對比度符合 WCAG 2.1 AA 標準
- 按鈕尺寸至少 44×44 pt (符合觸控標準)

```dart
Semantics(
  label: '登入按鈕',
  button: true,
  child: PrimaryButton(
    text: '登入',
    onPressed: _handleLogin,
  ),
)
```

### 3. 效能優化
- 使用 `const` 建構子減少重建
- SVG 圖示使用 `flutter_svg` 的快取機制
- 長列表使用 `ListView.builder` 而非 `ListView`

### 4. 狀態管理
建議的狀態管理方案：
- **簡單應用**: Provider
- **中大型應用**: Riverpod 或 Bloc
- **頁面狀態**: StatefulWidget 內部狀態

### 5. 錯誤處理
- 所有 API 請求必須包含錯誤處理
- 使用 `SnackBar` 或 `Dialog` 顯示錯誤訊息
- 表單驗證錯誤即時顯示在輸入框下方

```dart
// 錯誤提示範例
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('登入失敗，請檢查您的帳號密碼'),
    backgroundColor: AppColors.error,
    behavior: SnackBarBehavior.floating,
  ),
);
```

### 6. 表單驗證規則

#### Email 驗證
```dart
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return '請輸入 Email';
  }
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );
  if (!emailRegex.hasMatch(value)) {
    return '請輸入有效的 Email 格式';
  }
  return null;
}
```

#### 密碼驗證
```dart
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return '請輸入密碼';
  }
  if (value.length < 6) {
    return '密碼長度至少 6 個字元';
  }
  return null;
}
```

#### 驗證碼驗證
```dart
String? validateVerificationCode(String? value) {
  if (value == null || value.isEmpty) {
    return '請輸入驗證碼';
  }
  if (value.length != 6) {
    return '驗證碼必須為 6 位數字';
  }
  if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
    return '驗證碼只能包含數字';
  }
  return null;
}
```

### 7. 動畫效果
雖然設計檔未明確標註動畫，但建議加入以下過渡效果：

- **頁面切換**: `PageRouteBuilder` 搭配淡入淡出效果
- **按鈕點擊**: `InkWell` 或 `Material` 的漣漪效果
- **載入狀態**: `CircularProgressIndicator` 或骨架屏
- **表單錯誤**: 錯誤訊息淡入效果

```dart
// 頁面切換動畫範例
PageRouteBuilder(
  transitionDuration: Duration(milliseconds: 300),
  pageBuilder: (context, animation, secondaryAnimation) => NextPage(),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  },
)
```

### 8. 倒數計時器實作

Email 驗證頁的倒數計時器：

```dart
class _EmailVerificationPageState extends State<EmailVerificationPage> {
  Timer? _timer;
  int _remainingSeconds = 292; // 4:52 = 292 seconds

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _showExpiredDialog();
      }
    });
  }

  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
```

### 9. 圖示使用方式

```dart
// 使用 SVG 圖示
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/icons/login-user-icon.svg',
  width: 48,
  height: 48,
  colorFilter: ColorFilter.mode(
    Colors.white,
    BlendMode.srcIn,
  ), // 可選：改變圖示顏色
)
```

### 10. 測試建議

#### 單元測試
- 表單驗證邏輯
- 狀態管理邏輯
- 工具函式 (如時間格式化)

#### Widget 測試
- 按鈕點擊行為
- 表單輸入與驗證
- 頁面導航

#### 整合測試
- 完整的登入流程
- Email 驗證流程

---

## 📊 專案結構建議

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── routes.dart
│   └── constants.dart
├── theme/
│   ├── colors.dart
│   ├── typography.dart
│   ├── spacing.dart
│   ├── radius.dart
│   ├── shadows.dart
│   └── theme.dart
├── pages/
│   ├── auth/
│   │   ├── login_page.dart
│   │   ├── email_verification_page.dart
│   │   └── email_verification_resent_page.dart
│   └── home/
│       └── home_page.dart
├── widgets/
│   ├── buttons/
│   │   ├── primary_button.dart
│   │   └── secondary_button.dart
│   ├── inputs/
│   │   └── text_input_field.dart
│   ├── cards/
│   │   └── app_card.dart
│   └── app_bars/
│       └── custom_app_bar.dart
├── models/
│   ├── user.dart
│   └── verification.dart
├── services/
│   ├── auth_service.dart
│   └── api_service.dart
├── providers/
│   ├── auth_provider.dart
│   └── verification_provider.dart
└── utils/
    ├── validators.dart
    └── helpers.dart

assets/
├── icons/
│   ├── login-user-icon.svg
│   ├── home-calendar-icon.svg
│   ├── email-verification-icon.svg
│   ├── password-toggle-icon.svg
│   ├── notification-bell-icon.svg
│   ├── menu-icon.svg
│   ├── back-arrow-icon.svg
│   └── info-icon.svg
└── fonts/
    ├── Inter-Regular.ttf
    ├── Inter-Medium.ttf
    └── Inter-Bold.ttf
```

---

## 🔗 相關資源

- **Figma 設計檔**: https://www.figma.com/design/Mfp1UVqT4L2TrkEmhhXkol/%E5%AE%B6%E5%BA%AD%E8%A8%98%E5%B8%B3APP
- **Flutter 官方文件**: https://docs.flutter.dev/
- **Material Design 3**: https://m3.material.io/
- **flutter_svg 套件**: https://pub.dev/packages/flutter_svg
- **專案 Git 儲存庫**: https://github.com/chunchun1213/family-accoutting

---

## 📝 版本記錄

| 版本 | 日期 | 異動說明 |
|-----|------|---------|
| v1.0.0 | 2025-11-13 | 初始版本 - 包含登入頁、首頁、Email驗證頁設計規格 |

---

**文件維護者**: 前端開發團隊  
**最後更新**: 2025-11-13  
**狀態**: ✅ 已完成
