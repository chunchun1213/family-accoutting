# 設計資源 (Design Assets)

本目錄包含所有從 Figma 設計檔匯出的圖示資源。

## 📦 圖示清單

| 檔案名稱 | 尺寸 | 用途 | 頁面 |
|---------|------|------|------|
| `login-user-icon.svg` | 80×80 (含圓形背景) | 使用者頭像圖示 | 登入頁 |
| `home-calendar-icon.svg` | 176×176 (含圓形背景) | 日曆圖示 | 首頁 |
| `email-verification-icon.svg` | 104×104 (含圓形背景) | 郵件圖示 | Email 驗證頁 |
| `password-toggle-icon.svg` | 36×36 | 密碼顯示/隱藏圖示 | 登入頁 |
| `notification-bell-icon.svg` | 20×20 | 通知鈴鐺圖示 | 首頁標題欄 |
| `menu-icon.svg` | 24×24 | 漢堡選單圖示 | 首頁標題欄 |
| `back-arrow-icon.svg` | 24×24 | 返回箭頭圖示 | Email 驗證頁 |
| `info-icon.svg` | 20×20 | 資訊提示圖示 | Email 驗證頁 |

## 🎨 圖示特性

### 主要圖示 (含圓形背景)
- `login-user-icon.svg`: 白色使用者輪廓，淺綠色 (#86EFCC) 圓形背景
- `home-calendar-icon.svg`: 淺綠色日曆圖示，15% 透明度圓形背景
- `email-verification-icon.svg`: 白色郵件圖示，淺綠色圓形背景

### UI 控制圖示
- `password-toggle-icon.svg`: 眼睛圖示，用於切換密碼可見性
- `notification-bell-icon.svg`: 鈴鐺圖示，黑色線條
- `menu-icon.svg`: 三條橫線選單圖示，黑色線條
- `back-arrow-icon.svg`: 左箭頭圖示，黑色線條
- `info-icon.svg`: 資訊圓圈圖示，灰色線條

## 📋 使用方式

### Flutter
```dart
import 'package:flutter_svg/flutter_svg.dart';

// 載入 SVG 圖示
SvgPicture.asset(
  'assets/icons/login-user-icon.svg',
  width: 48,
  height: 48,
)
```

### React Native
```javascript
import { SvgUri } from 'react-native-svg';

// 載入 SVG 圖示
<SvgUri
  uri="./assets/icons/login-user-icon.svg"
  width="48"
  height="48"
/>
```

## 🔄 更新記錄

- **2025-11-13**: 初始版本，匯出 8 個核心圖示
- 來源: Figma 設計檔 `Mfp1UVqT4L2TrkEmhhXkol`

## 📝 注意事項

1. 所有 SVG 檔案均為向量格式，可無損縮放
2. 圖示顏色可透過 CSS/Flutter ColorFilter 動態調整
3. 建議保留原始檔案名稱以便追蹤來源
4. 主要圖示已包含圓形背景，使用時無需額外容器

## 🔗 相關連結

- Figma 設計檔: https://www.figma.com/design/Mfp1UVqT4L2TrkEmhhXkol/%E5%AE%B6%E5%BA%AD%E8%A8%98%E5%B8%B3APP
- 設計規格書: ../doc/Flutter前端設計規格書.md
