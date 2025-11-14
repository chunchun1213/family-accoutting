# 快速開始指南：會員註冊與登入系統

**功能分支**: `1-auth-home` | **更新日期**: 2025-11-14

---

## 目錄

1. [概述](#概述)
2. [環境需求](#環境需求)
3. [專案結構](#專案結構)
4. [設定步驟](#設定步驟)
5. [開發工作流程](#開發工作流程)
6. [測試指南](#測試指南)
7. [部署流程](#部署流程)
8. [常見問題](#常見問題)

---

## 概述

本專案實作**家庭記帳 App** 的會員註冊與登入系統，包含以下核心功能：

- ✅ **會員註冊**: Email + 密碼 + 姓名，發送 6 位數驗證碼
- ✅ **Email 驗證**: 5 分鐘有效期，5 次嘗試上限，60 秒重發冷卻
- ✅ **登入/登出**: JWT token 認證，30 天 refresh token
- ✅ **自動登入**: 使用 `flutter_secure_storage` 儲存 session
- ✅ **記帳主頁**: 登入後顯示（目前為佔位符）

**技術棧**:
- **前端**: Flutter 3.16+, Riverpod 2.4+, Material 3
- **後端**: Supabase Auth, Supabase Edge Functions (Deno + Hono)
- **資料庫**: PostgreSQL (Supabase)
- **Email 服務**: Resend API

---

## 環境需求

### 1. 前端（Flutter）

| 工具 | 版本 | 安裝連結 |
|------|------|---------|
| Flutter SDK | 3.16+ | https://flutter.dev/docs/get-started/install |
| Dart | 3.2+ | (隨 Flutter SDK 安裝) |
| Android Studio | 最新 | https://developer.android.com/studio |
| Xcode | 14+ (macOS only) | https://developer.apple.com/xcode/ |

**驗證安裝**:
```bash
flutter --version
dart --version
flutter doctor  # 檢查環境設定
```

---

### 2. 後端（Supabase）

| 工具 | 版本 | 安裝連結 |
|------|------|---------|
| Supabase CLI | 1.120+ | https://supabase.com/docs/guides/cli |
| Deno | 1.40+ | https://deno.land/manual/getting_started/installation |
| Node.js | 18+ (用於開發工具) | https://nodejs.org/ |

**安裝 Supabase CLI** (macOS):
```bash
brew install supabase/tap/supabase
supabase --version
```

**安裝 Deno** (macOS):
```bash
brew install deno
deno --version
```

---

### 3. 外部服務

#### Supabase 專案
1. 註冊帳號: https://supabase.com/
2. 建立新專案（選擇最近的 Region，建議 Singapore）
3. 取得以下金鑰（Settings → API）:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY` (公開，前端使用)
   - `SUPABASE_SERVICE_ROLE_KEY` (私密，後端使用)

#### Resend Email 服務
1. 註冊帳號: https://resend.com/
2. 驗證寄件網域（Domain Verification）
3. 取得 API Key: https://resend.com/api-keys
4. 免費方案限制: 100 封/天，3000 封/月

---

## 專案結構

```
family-accoutting/
├── lib/                              # Flutter 應用程式
│   ├── core/
│   │   ├── utils/
│   │   │   └── validators.dart       # Email/密碼驗證
│   │   ├── constants/
│   │   │   └── app_constants.dart    # 應用程式常數
│   │   └── config/
│   │       └── supabase_config.dart  # Supabase 初始化
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── auth_remote_datasource.dart  # API 呼叫
│   │   │   └── session_local_datasource.dart # 本地儲存
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── session_model.dart
│   │   │   └── api_response_model.dart
│   │   └── repositories/
│   │       └── auth_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── user.dart
│   │   │   └── session.dart
│   │   ├── repositories/
│   │   │   └── auth_repository.dart  # 介面定義
│   │   └── usecases/
│   │       ├── register_usecase.dart
│   │       ├── verify_code_usecase.dart
│   │       ├── login_usecase.dart
│   │       └── logout_usecase.dart
│   ├── presentation/
│   │   ├── providers/
│   │   │   ├── auth_provider.dart    # Riverpod 狀態管理
│   │   │   └── registration_provider.dart
│   │   ├── pages/
│   │   │   ├── login_page.dart
│   │   │   ├── registration_page.dart
│   │   │   ├── email_verification_page.dart
│   │   │   └── home_page.dart
│   │   └── widgets/
│   │       ├── custom_text_field.dart
│   │       └── loading_overlay.dart
│   └── main.dart
├── supabase/
│   ├── functions/
│   │   ├── auth/                     # 認證 Edge Function
│   │   │   └── index.ts
│   │   └── _shared/                  # 共用模組
│   │       ├── validators.ts
│   │       ├── email-service.ts
│   │       ├── db-helpers.ts
│   │       └── types.ts
│   ├── migrations/
│   │   └── 20251114000001_create_auth_tables.sql
│   └── config.toml
├── .specify/
│   └── specs/
│       └── 1-auth-home/
│           ├── spec.md               # 功能規格
│           ├── plan.md               # 實作計畫
│           ├── research.md           # 技術研究
│           ├── data-model.md         # 資料模型
│           ├── contracts/
│           │   ├── auth-api.yaml     # OpenAPI 規格
│           │   └── types.ts          # TypeScript 型別定義
│           └── quickstart.md         # 本檔案
├── design-assets/
│   └── icons/                        # SVG 圖示資源
├── doc/
│   ├── Flutter前端設計規格書.md
│   └── 1-使用者原始需求.md
├── pubspec.yaml                      # Flutter 相依套件
└── README.md
```

---

## 設定步驟

### 步驟 1: Clone 專案並切換分支

```bash
# Clone 專案（如果尚未 clone）
git clone https://github.com/chunchun1213/family-accoutting.git
cd family-accoutting

# 切換到功能分支
git checkout 1-auth-home

# 檢查當前分支
git branch  # 應顯示 * 1-auth-home
```

---

### 步驟 2: 設定 Flutter 環境

#### 2.1 安裝相依套件

在專案根目錄執行：

```bash
flutter pub get
```

#### 2.2 建立環境變數檔案

建立 `lib/core/config/.env` (不提交到 Git):

```env
# Supabase 設定
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# API 端點（Supabase Edge Functions）
API_BASE_URL=https://your-project-id.supabase.co/functions/v1
```

**安全提示**: 將 `.env` 加入 `.gitignore`:

```bash
echo "lib/core/config/.env" >> .gitignore
```

#### 2.3 載入環境變數（使用 flutter_dotenv）

在 `pubspec.yaml` 確認已安裝:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

在 `lib/main.dart` 載入:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 載入環境變數
  await dotenv.load(fileName: "lib/core/config/.env");
  
  runApp(const MyApp());
}
```

---

### 步驟 3: 設定 Supabase 後端

#### 3.1 連結本地專案到 Supabase

```bash
# 登入 Supabase CLI
supabase login

# 連結到遠端專案
supabase link --project-ref your-project-id
```

**取得 Project ID**: 前往 Supabase Dashboard → Settings → General → Reference ID

#### 3.2 執行資料庫遷移

```bash
# 推送 migrations 到遠端資料庫
supabase db push

# 驗證資料表是否建立成功
supabase db pull  # 應顯示 user_profiles, registration_requests, verification_codes
```

**手動驗證** (透過 Supabase Dashboard):
1. 前往 Dashboard → Table Editor
2. 確認以下資料表存在:
   - `public.user_profiles`
   - `public.registration_requests`
   - `public.verification_codes`

#### 3.3 部署 Edge Functions

```bash
# 部署認證 Edge Function
supabase functions deploy auth

# 設定環境變數（Resend API Key）
supabase secrets set RESEND_API_KEY=re_your_api_key_here

# 驗證部署
supabase functions list
```

---

### 步驟 4: 設定 Resend Email 服務

#### 4.1 驗證網域

1. 前往 https://resend.com/domains
2. 點擊 "Add Domain"
3. 輸入你的網域（如 `yourdomain.com`）
4. 依照指示新增 DNS 記錄:
   - **SPF 記錄**: TXT, `v=spf1 include:_spf.resend.com ~all`
   - **DKIM 記錄**: TXT, 複製 Resend 提供的 DKIM 值
   - **MX 記錄**: 依 Resend 指示設定

5. 等待驗證完成（通常 5-15 分鐘）

**開發替代方案**: 使用 Resend 提供的測試網域 `@resend.dev`（僅能寄到已驗證的 Email）

#### 4.2 更新 Email 模板設定

編輯 `supabase/functions/_shared/email-service.ts`:

```typescript
const EMAIL_CONFIG = {
  from: 'Family Accounting <noreply@yourdomain.com>', // 改為你的驗證網域
  brandColor: '#00A86B',
};
```

---

## 開發工作流程

### 1. 啟動本地開發環境

#### 1.1 啟動 Supabase 本地服務

```bash
# 啟動本地 Supabase（包含 PostgreSQL, Edge Functions, Studio）
supabase start

# 取得本地服務資訊
supabase status
```

**預設端點**:
- Studio (管理介面): http://localhost:54323
- API: http://localhost:54321
- PostgreSQL: postgresql://postgres:postgres@localhost:54322/postgres

#### 1.2 啟動 Flutter 應用程式

```bash
# iOS 模擬器
flutter run -d ios

# Android 模擬器
flutter run -d android

# Chrome 瀏覽器（開發測試用）
flutter run -d chrome
```

**開發模式切換**:

在 `lib/core/config/supabase_config.dart` 設定:

```dart
class SupabaseConfig {
  static const bool isDevelopment = true; // 本地開發
  
  static String get supabaseUrl => isDevelopment
      ? 'http://localhost:54321'
      : dotenv.env['SUPABASE_URL']!;
}
```

---

### 2. 功能開發範例

#### 2.1 新增 API 端點

**新增 `/auth/check-email` 端點**:

1. 編輯 `supabase/functions/auth/index.ts`:

```typescript
import { Hono } from 'hono';
import { checkEmailExists } from '../_shared/db-helpers.ts';

const app = new Hono();

app.post('/check-email', async (c) => {
  const { email } = await c.req.json();
  const exists = await checkEmailExists(email);
  
  return c.json({
    success: true,
    data: { exists },
  });
});

export default app;
```

2. 本地測試:

```bash
# 啟動 Edge Function 本地開發伺服器
supabase functions serve auth --env-file supabase/.env.local

# 測試端點
curl -X POST http://localhost:54321/functions/v1/auth/check-email \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

3. 部署到遠端:

```bash
supabase functions deploy auth
```

#### 2.2 新增 Flutter UI 元件

**新增註冊表單驗證**:

1. 編輯 `lib/presentation/pages/registration_page.dart`:

```dart
class RegistrationPage extends ConsumerWidget {
  final _formKey = GlobalKey<FormState>();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email'),
            validator: Validators.email,
            onSaved: (value) => _email = value,
          ),
          // ... 其他欄位
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                ref.read(authProvider.notifier).register(
                  email: _email,
                  name: _name,
                  password: _password,
                );
              }
            },
            child: const Text('註冊'),
          ),
        ],
      ),
    );
  }
}
```

2. 測試 UI:

```bash
flutter run -d ios  # 重新載入 app 查看變更
```

---

### 3. Hot Reload 與 Hot Restart

| 快捷鍵 | 功能 | 用途 |
|--------|------|------|
| `r` | Hot Reload | 更新 UI 變更（不重啟 app） |
| `R` | Hot Restart | 完全重啟 app |
| `q` | 結束 | 停止執行 |

---

## 測試指南

### 1. 單元測試（Unit Tests）

#### 1.1 測試驗證函式

建立 `test/core/utils/validators_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:family_accounting/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email validator accepts valid email', () {
      expect(Validators.email('test@example.com'), isNull);
    });

    test('email validator rejects invalid email', () {
      expect(Validators.email('invalid-email'), isNotNull);
    });

    test('password validator checks length', () {
      expect(Validators.password('Pass1'), isNotNull);
      expect(Validators.password('Password123'), isNull);
    });
  });
}
```

**執行測試**:

```bash
flutter test
```

---

#### 1.2 測試 Riverpod Provider

建立 `test/presentation/providers/auth_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_accounting/presentation/providers/auth_provider.dart';

void main() {
  test('initial auth state is unauthenticated', () {
    final container = ProviderContainer();
    final authState = container.read(authProvider);
    
    expect(authState.status, AuthStatus.unauthenticated);
    expect(authState.user, isNull);
  });
}
```

---

### 2. 整合測試（Integration Tests）

#### 2.1 測試註冊流程

建立 `integration_test/registration_flow_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:family_accounting/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete registration flow', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 點擊註冊按鈕
    await tester.tap(find.text('註冊'));
    await tester.pumpAndSettle();

    // 填寫表單
    await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(Key('name_field')), '測試使用者');
    await tester.enterText(find.byKey(Key('password_field')), 'Password123');

    // 提交註冊
    await tester.tap(find.text('送出'));
    await tester.pumpAndSettle();

    // 驗證導向驗證碼頁面
    expect(find.text('Email 驗證'), findsOneWidget);
  });
}
```

**執行整合測試**:

```bash
flutter test integration_test/registration_flow_test.dart
```

---

### 3. API 測試（使用 Postman 或 curl）

#### 3.1 測試註冊端點

```bash
curl -X POST https://your-project-id.supabase.co/functions/v1/auth/register \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{
    "email": "test@example.com",
    "name": "測試使用者",
    "password": "Password123"
  }'
```

**預期回應** (201 Created):

```json
{
  "success": true,
  "message": "驗證碼已發送至您的 Email，請於 5 分鐘內完成驗證",
  "data": {
    "email": "test@example.com",
    "expires_at": "2025-11-14T10:35:00Z"
  }
}
```

---

### 4. 測試工具推薦

| 工具 | 用途 | 連結 |
|------|------|------|
| Postman | API 測試與文件 | https://www.postman.com/ |
| Flutter DevTools | 效能分析與偵錯 | `flutter pub global activate devtools` |
| Supabase Studio | 資料庫查詢與管理 | http://localhost:54323 (本地) |

---

## 部署流程

### 1. 部署到 Supabase Production

#### 1.1 部署資料庫變更

```bash
# 推送 migrations
supabase db push

# 驗證 Row Level Security (RLS) 政策
supabase db dump --data-only --schema public
```

#### 1.2 部署 Edge Functions

```bash
# 部署所有 functions
supabase functions deploy

# 僅部署特定 function
supabase functions deploy auth
```

#### 1.3 設定環境變數

```bash
# 設定 Resend API Key
supabase secrets set RESEND_API_KEY=re_your_production_key
supabase secrets set SENDER_EMAIL=noreply@yourdomain.com
```

---

### 2. 部署 Flutter App

#### 2.1 iOS 部署（TestFlight）

1. 更新 `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <false/>
</dict>
```

2. 建置 IPA:

```bash
flutter build ipa --release
```

3. 上傳到 App Store Connect:

```bash
open build/ios/archive/Runner.xcarchive
# 使用 Xcode Organizer 上傳
```

---

#### 2.2 Android 部署（Google Play）

1. 產生簽署金鑰（首次）:

```bash
keytool -genkey -v -keystore ~/android-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias family-accounting
```

2. 設定 `android/key.properties`:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=family-accounting
storeFile=/path/to/android-release-key.jks
```

3. 建置 AAB:

```bash
flutter build appbundle --release
```

4. 上傳到 Google Play Console:
   - 前往 https://play.google.com/console
   - Release → Production → Create new release
   - 上傳 `build/app/outputs/bundle/release/app-release.aab`

---

## 常見問題

### Q1: Flutter 建置失敗：找不到 `flutter_secure_storage`

**原因**: iOS Keychain 權限未設定

**解決方法**:

編輯 `ios/Runner/Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>我們需要使用 Face ID 保護您的登入資訊</string>
```

執行:

```bash
cd ios && pod install && cd ..
flutter clean && flutter pub get
```

---

### Q2: Supabase Edge Function 回傳 CORS 錯誤

**原因**: 未設定 CORS headers

**解決方法**:

確認 `supabase/functions/auth/index.ts` 包含:

```typescript
import { Hono } from 'hono';
import { cors } from 'hono/cors';

const app = new Hono();

app.use('/*', cors({
  origin: ['http://localhost:54321', 'https://your-app-domain.com'],
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowHeaders: ['Content-Type', 'Authorization'],
}));
```

---

### Q3: Email 無法發送（Resend API 錯誤）

**診斷步驟**:

1. 檢查 API Key 是否正確:

```bash
supabase secrets list  # 確認 RESEND_API_KEY 存在
```

2. 驗證寄件網域是否已驗證:
   - 前往 https://resend.com/domains
   - 確認狀態為 "Verified"

3. 檢查免費方案限制:
   - 每日上限: 100 封
   - 查看用量: https://resend.com/overview

4. 測試 Resend API（手動）:

```bash
curl -X POST https://api.resend.com/emails \
  -H "Authorization: Bearer re_your_api_key" \
  -H "Content-Type: application/json" \
  -d '{
    "from": "noreply@yourdomain.com",
    "to": "test@example.com",
    "subject": "Test Email",
    "text": "This is a test"
  }'
```

---

### Q4: 本地開發時 Supabase Auth 無法連線

**原因**: `supabase start` 未執行或埠口衝突

**解決方法**:

```bash
# 停止所有服務
supabase stop

# 清除暫存資料並重新啟動
supabase db reset
supabase start

# 檢查服務狀態
supabase status
```

**埠口衝突**:

如果埠口被佔用，可編輯 `supabase/config.toml`:

```toml
[api]
port = 54321  # 改為其他埠口，如 54322

[db]
port = 54322  # 改為其他埠口
```

---

### Q5: Flutter Riverpod 狀態未更新

**原因**: Provider 未正確監聽

**解決方法**:

確保使用 `ConsumerWidget` 或 `Consumer`:

```dart
class MyPage extends ConsumerWidget {  // 不是 StatelessWidget
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);  // watch, 不是 read
    
    return Text('User: ${authState.user?.name}');
  }
}
```

**偵錯提示**:

啟用 Riverpod 日誌:

```dart
void main() {
  runApp(
    ProviderScope(
      observers: [Logger()],  // 印出 provider 狀態變更
      child: MyApp(),
    ),
  );
}

class Logger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('Provider ${provider.name ?? provider.runtimeType} updated');
    print('  Previous: $previousValue');
    print('  New: $newValue');
  }
}
```

---

## 延伸閱讀

### 官方文件

- **Flutter**: https://flutter.dev/docs
- **Riverpod**: https://riverpod.dev/docs/introduction/getting_started
- **Supabase**: https://supabase.com/docs
- **Resend**: https://resend.com/docs
- **Hono**: https://hono.dev/

### 專案特定文件

- [spec.md](./spec.md) - 完整功能規格
- [plan.md](./plan.md) - 實作計畫與階段劃分
- [research.md](./research.md) - 技術研究與決策理由
- [data-model.md](./data-model.md) - 資料庫結構與 ERD
- [contracts/auth-api.yaml](./contracts/auth-api.yaml) - OpenAPI 3.0 規格
- [contracts/types.ts](./contracts/types.ts) - TypeScript 型別定義

---

## 取得協助

### 1. 查看日誌

**Flutter 日誌**:
```bash
flutter logs
```

**Supabase Edge Function 日誌**:
```bash
supabase functions logs auth
```

**Supabase Database 日誌**:
- 前往 Dashboard → Logs → Database

---

### 2. 社群支援

- **GitHub Issues**: https://github.com/chunchun1213/family-accoutting/issues
- **Supabase Discord**: https://discord.supabase.com/
- **Flutter Discord**: https://discord.gg/flutter

---

### 3. 聯絡方式

- **專案維護者**: GitHub Copilot
- **Email**: support@example.com

---

**祝開發順利！** 🚀
