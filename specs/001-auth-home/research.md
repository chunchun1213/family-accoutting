# Research: Flutter Riverpod 認證狀態管理與 Resend Email API 整合

**分支**: `1-auth-home` | **日期**: 2025-11-14  
**研究目標**: 
1. Flutter Riverpod 與 Supabase 認證系統的狀態管理模式
2. 在 Supabase Edge Functions 環境中整合 Resend Email API 發送驗證碼的最佳實踐
3. flutter_secure_storage 儲存驗證會話 token 的最佳實踐

---

## 目錄

1. [Part A: Flutter Riverpod 認證狀態管理](#part-a-flutter-riverpod-認證狀態管理)
2. [Part B: Resend Email API 整合](#part-b-resend-email-api-整合)
3. [Part C: flutter_secure_storage 最佳實踐](#part-c-flutter_secure_storage-最佳實踐)

---

# Part A: Flutter Riverpod 認證狀態管理

## 執行摘要

**決策**: 使用 Riverpod 2.4+ 的 `AsyncNotifierProvider` 搭配 `flutter_secure_storage` 實作全域認證狀態管理

**理由**:
1. **型別安全與編譯時檢查**: Riverpod 2.0+ 使用程式碼生成器，提供完整的型別安全
2. **自動依賴管理**: Provider 之間的依賴關係自動追蹤，避免手動管理生命週期
3. **測試友善**: Provider 可以輕鬆 override，單元測試不需要複雜的 mock 設定
4. **狀態一致性**: AsyncNotifier 提供統一的非同步狀態處理模式（loading/data/error）
5. **記憶體效率**: 自動處理 provider 的建立與銷毀，未使用的 provider 會自動清理

**替代方案評估**:
- **Provider (舊版)**: 較簡單但缺乏型別安全，需手動管理狀態更新
- **Bloc**: 功能完整但樣板程式碼較多，對小型專案過度工程
- **GetX**: API 簡單但使用全域狀態，測試困難且與 Flutter 框架耦合度低

---

## 1. 認證狀態架構設計

### 1.1 核心狀態模型

```dart
// lib/features/auth/domain/models/auth_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

/// 認證狀態
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.authenticated(User user, String sessionToken) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.loading() = _Loading;
}

/// 使用者模型
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String name,
    required DateTime createdAt,
  }) = _User;
  
  factory User.fromJson(Map<String, dynamic> json) => _User(
    id: json['id'] as String,
    email: json['email'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
```

**設計決策**:
- 使用 `freezed` 生成不可變（immutable）的狀態類別，確保狀態變更可追蹤
- 四種狀態明確區分：初始化 → 載入中 → 已認證 / 未認證
- 儲存 `sessionToken` 於狀態中，避免頻繁讀取安全儲存

### 1.2 認證 Notifier 實作

```dart
// lib/features/auth/presentation/providers/auth_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'auth_provider.g.dart';

/// 認證狀態 Provider
@riverpod
class AuthNotifier extends _$AuthNotifier {
  static const _sessionTokenKey = 'session_token';
  static const _userDataKey = 'user_data';
  
  late final FlutterSecureStorage _storage;
  late final AuthRepository _authRepository;

  @override
  Future<AuthState> build() async {
    // 初始化依賴項
    _storage = ref.read(secureStorageProvider);
    _authRepository = ref.read(authRepositoryProvider);
    
    // 應用程式啟動時檢查已儲存的會話
    return await _checkStoredSession();
  }

  /// 檢查已儲存的會話（自動登入）
  Future<AuthState> _checkStoredSession() async {
    try {
      final sessionToken = await _storage.read(key: _sessionTokenKey);
      final userDataJson = await _storage.read(key: _userDataKey);
      
      if (sessionToken == null || userDataJson == null) {
        return const AuthState.unauthenticated();
      }
      
      // 驗證 token 有效性（呼叫後端 /auth/verify-session）
      final isValid = await _authRepository.verifySession(sessionToken);
      
      if (!isValid) {
        // Token 過期或無效，清除儲存
        await _clearStorage();
        return const AuthState.unauthenticated();
      }
      
      // 解析使用者資料
      final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
      final user = User.fromJson(userData);
      
      return AuthState.authenticated(user, sessionToken);
    } catch (e) {
      // 錯誤處理：清除損壞的資料
      await _clearStorage();
      return const AuthState.unauthenticated();
    }
  }

  /// 登入
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      // 呼叫後端登入 API
      final response = await _authRepository.login(
        email: email,
        password: password,
      );
      
      // 儲存會話資料到安全儲存
      await _storage.write(key: _sessionTokenKey, value: response.sessionToken);
      await _storage.write(key: _userDataKey, value: jsonEncode(response.user.toJson()));
      
      return AuthState.authenticated(response.user, response.sessionToken);
    });
  }

  /// 註冊（完成 Email 驗證後呼叫）
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String verificationCode,
  }) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final response = await _authRepository.register(
        email: email,
        password: password,
        name: name,
        verificationCode: verificationCode,
      );
      
      await _storage.write(key: _sessionTokenKey, value: response.sessionToken);
      await _storage.write(key: _userDataKey, value: jsonEncode(response.user.toJson()));
      
      return AuthState.authenticated(response.user, response.sessionToken);
    });
  }

  /// 登出
  Future<void> logout() async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final currentState = state.value;
      
      if (currentState is _Authenticated) {
        // 呼叫後端登出 API（撤銷 token）
        await _authRepository.logout(currentState.sessionToken);
      }
      
      // 清除本地儲存
      await _clearStorage();
      
      // 清除其他相關 provider（例如：使用者偏好設定）
      ref.invalidate(userPreferencesProvider);
      
      return const AuthState.unauthenticated();
    });
  }

  /// 清除安全儲存
  Future<void> _clearStorage() async {
    await _storage.delete(key: _sessionTokenKey);
    await _storage.delete(key: _userDataKey);
  }
}

/// 安全儲存 Provider
@riverpod
FlutterSecureStorage secureStorage(SecureStorageRef ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
}
```

**設計決策說明**:

1. **`build()` 方法自動執行**: 
   - 應用程式啟動時自動呼叫 `_checkStoredSession()`
   - 無需手動初始化，符合 Riverpod 的宣告式風格

2. **狀態更新使用 `AsyncValue.guard()`**:
   - 自動捕捉錯誤並包裝為 `AsyncError` 狀態
   - UI 可以統一處理 loading/error/data 狀態

3. **儲存策略**:
   - `sessionToken`: 用於 API 請求的 Bearer token
   - `userData`: JSON 格式的使用者資料（避免重複 API 請求）
   - 使用 `flutter_secure_storage` 而非 `shared_preferences`，確保敏感資料加密

4. **登出清理**:
   - 使用 `ref.invalidate()` 清除相關 provider（例如快取的使用者資料）
   - 避免記憶體洩漏與狀態殘留

### 1.3 認證狀態監聽與路由控制

```dart
// lib/app/router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // 等待認證狀態載入
      if (authState.isLoading) {
        return '/splash';
      }
      
      final isAuthenticated = authState.value is _Authenticated;
      final isOnAuthPage = state.matchedLocation.startsWith('/auth');
      
      // 未認證但不在登入頁 → 導向登入頁
      if (!isAuthenticated && !isOnAuthPage) {
        return '/auth/login';
      }
      
      // 已認證但在登入頁 → 導向主頁
      if (isAuthenticated && isOnAuthPage) {
        return '/home';
      }
      
      return null; // 不重新導向
    },
    refreshListenable: GoRouterRefreshStream(
      authState.asStream(),
    ),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
});

/// 將 Stream 包裝為 Listenable（用於 GoRouter 自動刷新）
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

**設計決策**:
- 使用 `GoRouter` 的 `redirect` 與 `refreshListenable` 自動處理路由控制
- 認證狀態變更時自動重新執行 `redirect` 邏輯
- Splash Screen 作為過渡頁面（避免白屏）

---

## 2. 自動登入流程實作

### 2.1 流程圖

```
應用程式啟動
    ↓
AuthNotifier.build() 執行
    ↓
讀取 flutter_secure_storage
    ↓
    ├─→ 無 token → AuthState.unauthenticated()
    │                 ↓
    │          重新導向至登入頁
    │
    └─→ 有 token → 呼叫 /auth/verify-session API
                    ↓
                    ├─→ Token 有效 → AuthState.authenticated()
                    │                      ↓
                    │                 重新導向至主頁
                    │
                    └─→ Token 無效 → 清除儲存 → AuthState.unauthenticated()
                                                    ↓
                                               重新導向至登入頁
```

### 2.2 後端 Session 驗證 API

```typescript
// supabase/functions/verify-session/index.ts

import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req: Request) => {
  try {
    const authHeader = req.headers.get('Authorization');
    
    if (!authHeader?.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ valid: false, error: 'Missing token' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    const token = authHeader.substring(7);
    
    // 初始化 Supabase 客戶端（使用 service role key）
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );
    
    // 驗證 token（查詢 Supabase Auth）
    const { data: { user }, error } = await supabase.auth.getUser(token);
    
    if (error || !user) {
      return new Response(
        JSON.stringify({ valid: false, error: 'Invalid or expired token' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }
    
    // Token 有效
    return new Response(
      JSON.stringify({ 
        valid: true,
        user: {
          id: user.id,
          email: user.email,
          name: user.user_metadata?.name,
        }
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Session verification error:', error);
    return new Response(
      JSON.stringify({ valid: false, error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
```

### 2.3 快取策略（減少 API 請求）

```dart
// lib/features/auth/presentation/providers/auth_provider.dart

@riverpod
class AuthNotifier extends _$AuthNotifier {
  DateTime? _lastVerificationTime;
  static const _verificationCacheDuration = Duration(minutes: 5);

  Future<AuthState> _checkStoredSession() async {
    // ... (前面的程式碼)
    
    // 檢查是否需要重新驗證（快取 5 分鐘）
    if (_lastVerificationTime != null &&
        DateTime.now().difference(_lastVerificationTime!) < _verificationCacheDuration) {
      // 使用快取的使用者資料，跳過 API 驗證
      final userData = jsonDecode(userDataJson!) as Map<String, dynamic>;
      final user = User.fromJson(userData);
      return AuthState.authenticated(user, sessionToken!);
    }
    
    // 超過快取時間，重新驗證
    final isValid = await _authRepository.verifySession(sessionToken!);
    
    if (!isValid) {
      await _clearStorage();
      return const AuthState.unauthenticated();
    }
    
    _lastVerificationTime = DateTime.now();
    
    final userData = jsonDecode(userDataJson!) as Map<String, dynamic>;
    final user = User.fromJson(userData);
    
    return AuthState.authenticated(user, sessionToken!);
  }
}
```

**設計決策**:
- 應用程式啟動時如果快取有效（5 分鐘內），直接使用本地資料
- 避免每次 app resume 都呼叫 API（改善使用者體驗與降低成本）
- 敏感操作（例如修改密碼）可以強制重新驗證

---

## 3. 狀態同步與清理策略

### 3.1 Supabase Auth 狀態監聽

```dart
// lib/features/auth/data/repositories/auth_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;
  
  AuthRepository(this._supabase) {
    // 監聽 Supabase Auth 狀態變更
    _supabase.auth.onAuthStateChange.listen((event) {
      switch (event.event) {
        case AuthChangeEvent.signedOut:
          // 使用者在其他裝置登出，同步本地狀態
          _handleRemoteLogout();
          break;
        case AuthChangeEvent.tokenRefreshed:
          // Token 自動刷新，更新本地儲存
          _handleTokenRefresh(event.session?.accessToken);
          break;
        case AuthChangeEvent.userDeleted:
          // 帳號被刪除
          _handleAccountDeleted();
          break;
      }
    });
  }
  
  void _handleRemoteLogout() {
    // 觸發 Riverpod provider 的 logout
    // 使用事件匯流排或直接呼叫 ref.read(authNotifierProvider.notifier).logout()
  }
  
  void _handleTokenRefresh(String? newToken) async {
    if (newToken != null) {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'session_token', value: newToken);
    }
  }
  
  void _handleAccountDeleted() {
    // 清除所有本地資料
    _handleRemoteLogout();
  }
}
```

### 3.2 登出時的 Provider 清理

```dart
// lib/features/auth/presentation/providers/auth_provider.dart

Future<void> logout() async {
  state = const AsyncValue.loading();
  
  state = await AsyncValue.guard(() async {
    final currentState = state.value;
    
    if (currentState is _Authenticated) {
      await _authRepository.logout(currentState.sessionToken);
    }
    
    // 清除安全儲存
    await _clearStorage();
    
    // 清除相關 provider（使用 invalidate）
    ref.invalidate(userPreferencesProvider);
    ref.invalidate(accountingRecordsProvider);
    ref.invalidate(familyMembersProvider);
    
    // 清除 HTTP 客戶端的快取（如果有）
    ref.read(httpClientProvider).clearCache();
    
    return const AuthState.unauthenticated();
  });
}
```

**設計決策**:
- 使用 `ref.invalidate()` 而非手動重設狀態，確保 provider 重新初始化
- 清除 HTTP 快取避免敏感資料殘留
- 登出後所有相依 provider 會自動清理（Riverpod 的依賴追蹤機制）

---

## 4. 巢狀路由與認證狀態處理

### 4.1 受保護路由的實作

```dart
// lib/app/router.dart

GoRoute(
  path: '/home',
  builder: (context, state) => const HomePage(),
  routes: [
    GoRoute(
      path: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: 'profile',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
),

// 全域 redirect 處理（在 GoRouter 建構子中）
redirect: (context, state) {
  final authState = ref.read(authNotifierProvider).value;
  
  // 受保護的路由列表
  const protectedRoutes = ['/home', '/settings', '/profile'];
  
  final isProtectedRoute = protectedRoutes.any(
    (route) => state.matchedLocation.startsWith(route),
  );
  
  if (isProtectedRoute && authState is! _Authenticated) {
    // 儲存原始 URL（登入後重新導向）
    return '/auth/login?redirect=${Uri.encodeComponent(state.matchedLocation)}';
  }
  
  return null;
},
```

### 4.2 深層連結與認證狀態

```dart
// lib/main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      routerConfig: router,
      theme: ThemeData.light(),
    );
  }
}
```

**設計決策**:
- 使用 query parameter 儲存原始 URL（`?redirect=...`）
- 登入成功後從 query parameter 讀取並重新導向
- 深層連結（例如：`myapp://home/settings`）會先導向登入頁，登入後自動回到原始頁面

---

## 5. 測試策略

### 5.1 單元測試（Provider 層）

```dart
// test/features/auth/presentation/providers/auth_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockSecureStorage mockStorage;
  
  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockStorage = MockSecureStorage();
  });

  group('AuthNotifier', () {
    test('初始狀態應為 unauthenticated（無已儲存 token）', () async {
      // Arrange
      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);
      
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      
      // Act
      final state = await container.read(authNotifierProvider.future);
      
      // Assert
      expect(state, isA<_Unauthenticated>());
    });

    test('login 成功應更新狀態為 authenticated', () async {
      // Arrange
      final mockUser = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );
      final mockToken = 'mock_session_token';
      
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => LoginResponse(
        user: mockUser,
        sessionToken: mockToken,
      ));
      
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});
      
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      
      // Act
      await container.read(authNotifierProvider.notifier).login(
        email: 'test@example.com',
        password: 'password123',
      );
      
      final state = container.read(authNotifierProvider).value;
      
      // Assert
      expect(state, isA<_Authenticated>());
      expect((state as _Authenticated).user.email, 'test@example.com');
      expect(state.sessionToken, mockToken);
      
      // 驗證儲存操作
      verify(mockStorage.write(key: 'session_token', value: mockToken)).called(1);
      verify(mockStorage.write(key: 'user_data', value: anyNamed('value'))).called(1);
    });

    test('logout 應清除狀態與儲存', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      
      when(mockAuthRepository.logout(any)).thenAnswer((_) async {});
      when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
      
      // 先設定為已認證狀態
      container.read(authNotifierProvider.notifier).state = AsyncValue.data(
        AuthState.authenticated(
          User(id: '123', email: 'test@example.com', name: 'Test', createdAt: DateTime.now()),
          'token',
        ),
      );
      
      // Act
      await container.read(authNotifierProvider.notifier).logout();
      
      final state = container.read(authNotifierProvider).value;
      
      // Assert
      expect(state, isA<_Unauthenticated>());
      verify(mockStorage.delete(key: 'session_token')).called(1);
      verify(mockStorage.delete(key: 'user_data')).called(1);
    });
  });
}
```

### 5.2 整合測試（完整流程）

```dart
// test/integration/auth_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('認證流程整合測試', () {
    testWidgets('完整註冊與登入流程', (tester) async {
      // 1. 啟動應用程式
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      
      // 2. 應該顯示登入頁（未認證狀態）
      expect(find.text('登入'), findsOneWidget);
      
      // 3. 導航至註冊頁
      await tester.tap(find.text('註冊帳號'));
      await tester.pumpAndSettle();
      
      // 4. 填寫註冊表單
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'Password123!');
      await tester.enterText(find.byKey(Key('name_field')), 'Test User');
      
      // 5. 送出註冊（會發送驗證碼）
      await tester.tap(find.text('送出'));
      await tester.pumpAndSettle();
      
      // 6. 應該導航至驗證碼頁面
      expect(find.text('Email 驗證'), findsOneWidget);
      
      // 7. 輸入驗證碼（假設為 123456）
      await tester.enterText(find.byKey(Key('verification_code_field')), '123456');
      await tester.tap(find.text('驗證'));
      await tester.pump(Duration(seconds: 2)); // 等待 API 回應
      
      // 8. 驗證成功後應該導航至主頁（已認證狀態）
      expect(find.text('家庭記帳主頁'), findsOneWidget);
      
      // 9. 測試登出
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      
      // 10. 應該返回登入頁
      expect(find.text('登入'), findsOneWidget);
      
      // 11. 測試自動登入（重新啟動應用程式）
      // 注意：整合測試中無法真正重啟應用程式，需使用其他方式模擬
      // 例如：清除 ProviderScope 並重新建立
    });

    testWidgets('自動登入流程（已儲存有效 token）', (tester) async {
      // 預先儲存 token 到 secure storage（使用 mock）
      final mockStorage = MockSecureStorage();
      when(mockStorage.read(key: 'session_token'))
          .thenAnswer((_) async => 'valid_token');
      when(mockStorage.read(key: 'user_data'))
          .thenAnswer((_) async => '{"id":"123","email":"test@example.com","name":"Test","created_at":"2025-01-01T00:00:00Z"}');
      
      // 啟動應用程式
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(mockStorage),
          ],
          child: MyApp(),
        ),
      );
      await tester.pump(Duration(seconds: 1)); // 等待認證狀態載入
      
      // 應該直接導航至主頁（跳過登入頁）
      expect(find.text('家庭記帳主頁'), findsOneWidget);
      expect(find.text('登入'), findsNothing);
    });
  });
}
```

---

## 6. 效能最佳化建議

### 6.1 減少不必要的重建

```dart
// 使用 select 只監聽特定欄位
final userName = ref.watch(
  authNotifierProvider.select((state) {
    return state.when(
      data: (authState) => authState is _Authenticated ? authState.user.name : null,
      loading: () => null,
      error: (_, __) => null,
    );
  }),
);

// 避免整個 widget 因認證狀態變更而重建
```

### 6.2 Provider 作用域控制

```dart
// 對於不需要全域共用的狀態，使用 autoDispose
@riverpod
class VerificationCodeNotifier extends _$VerificationCodeNotifier {
  @override
  Future<String?> build() async => null;
  
  // 這個 provider 會在不使用時自動清理
}
```

### 6.3 批次狀態更新

```dart
// 避免連續多次呼叫 state = ...
// 使用單一非同步操作包裝所有變更
Future<void> updateProfile({
  required String name,
  required String avatar,
}) async {
  state = const AsyncValue.loading();
  
  state = await AsyncValue.guard(() async {
    final currentState = state.requireValue as _Authenticated;
    
    // 一次性更新所有欄位
    final updatedUser = currentState.user.copyWith(
      name: name,
      avatar: avatar,
    );
    
    // 呼叫 API 並更新儲存
    await _authRepository.updateProfile(updatedUser);
    await _storage.write(key: _userDataKey, value: jsonEncode(updatedUser.toJson()));
    
    return AuthState.authenticated(updatedUser, currentState.sessionToken);
  });
}
```

---

## 7. 安全性考量

### 7.1 flutter_secure_storage 配置

```dart
// lib/core/storage/secure_storage_config.dart

const secureStorageConfig = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
    // 使用 Android Keystore 加密
    keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  ),
  iOptions: IOSOptions(
    // 使用 iOS Keychain
    accessibility: KeychainAccessibility.first_unlock,
    // 僅在裝置解鎖時可存取
    synchronizable: false, // 不同步至 iCloud
  ),
  wOptions: WindowsOptions(
    // Windows 使用 DPAPI 加密
  ),
  lOptions: LinuxOptions(
    // Linux 使用 Secret Service API
  ),
);
```

### 7.2 敏感資料不記錄到日誌

```dart
// lib/core/logging/secure_logger.dart

void logAuthEvent(String event, {Map<String, dynamic>? data}) {
  // 過濾敏感欄位
  final sanitizedData = data?.map((key, value) {
    const sensitiveKeys = ['password', 'token', 'sessionToken', 'verificationCode'];
    
    if (sensitiveKeys.contains(key)) {
      return MapEntry(key, '***REDACTED***');
    }
    
    return MapEntry(key, value);
  });
  
  print('Auth Event: $event | Data: $sanitizedData');
}
```

### 7.3 Token 刷新機制

```dart
// lib/features/auth/data/repositories/auth_repository.dart

class AuthRepository {
  // 監聽 Supabase Auth 的 token 刷新事件
  Future<void> setupTokenRefresh() async {
    _supabase.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.tokenRefreshed) {
        final newToken = event.session?.accessToken;
        
        if (newToken != null) {
          // 更新儲存的 token
          _storage.write(key: 'session_token', value: newToken);
          
          // 更新 HTTP 客戶端的 Authorization header
          _httpClient.updateAuthToken(newToken);
        }
      }
    });
  }
}
```

---

## 8. 實作檢查清單（認證狀態管理）

- [ ] 安裝必要套件 (`riverpod_annotation`, `flutter_secure_storage`, `freezed`)
- [ ] 產生 freezed 模型 (`auth_state.dart`, `user.dart`)
- [ ] 實作 `AuthNotifier` (login, register, logout, auto-login)
- [ ] 實作 `secureStorageProvider` 與安全配置
- [ ] 實作 `AuthRepository` (API 呼叫與 Supabase Auth 整合)
- [ ] 設定 GoRouter 的認證導向邏輯
- [ ] 實作 Splash Screen (載入認證狀態時顯示)
- [ ] 實作 Session 驗證 API (`/auth/verify-session`)
- [ ] 實作 Token 刷新監聽
- [ ] 撰寫單元測試 (`auth_provider_test.dart`)
- [ ] 撰寫整合測試 (`auth_flow_test.dart`)
- [ ] 實作敏感資料過濾的 Logger
- [ ] 測試自動登入流程（應用程式重啟）
- [ ] 測試登出後的狀態清理（provider invalidation）
- [ ] 測試多裝置登出同步（Supabase Auth state change）

---

# Part B: Resend Email API 整合

## 執行摘要

**決策**: 使用 Resend Email API 搭配自訂 HTML 模板在 Supabase Edge Functions 中發送 6 位數驗證碼

**理由**:
1. **開發者體驗優異**: Resend 提供現代化的 API 設計，與 Deno runtime 完美相容
2. **免費方案充足**: 每月 3,000 封信，日限 100 封，足夠初期使用（預期 ~100 並發註冊）
3. **高可靠性**: 企業級的送達率（SOC 2, GDPR 認證）與自動 bounce 管理
4. **簡單整合**: 無需額外 SDK，使用原生 fetch API 即可（Deno 環境友善）
5. **可觀測性**: 內建 webhook 支援追蹤 email 送達狀態

**替代方案評估**:
- **SendGrid**: 功能更完整但 API 較複雜，對小型專案過度工程
- **AWS SES**: 成本最低但需要額外的 AWS 基礎設施與複雜的 IAM 設定
- **Supabase Email (magic link)**: 不支援自訂驗證碼格式，僅限魔法連結

---

## 1. Resend API 在 Deno/TypeScript (Supabase Edge Functions) 的整合

### 1.1 基本設定

**Edge Function 環境**: Supabase Edge Functions 使用 Deno runtime，支援原生 ES modules

```typescript
// supabase/functions/send-verification-code/index.ts
import { serve } from "https://deno.land/std@0.190.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');

serve(async (req: Request) => {
  // 處理請求邏輯
});
```

### 1.2 發送驗證碼範例

```typescript
// supabase/functions/_shared/email-service.ts

interface SendVerificationCodeParams {
  email: string;
  code: string;
  userName: string;
  expiresInMinutes: number;
}

export async function sendVerificationCode({
  email,
  code,
  userName,
  expiresInMinutes
}: SendVerificationCodeParams) {
  const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
  
  if (!RESEND_API_KEY) {
    throw new Error('RESEND_API_KEY not configured');
  }

  const html = generateVerificationEmailHTML({ code, userName, expiresInMinutes });
  const text = generateVerificationEmailText({ code, userName, expiresInMinutes });

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${RESEND_API_KEY}`,
      // 使用 idempotency key 防止重複發送
      'Idempotency-Key': `verification-${email}-${Date.now()}`
    },
    body: JSON.stringify({
      from: 'Family Accounting <noreply@yourdomain.com>',
      to: [email],
      subject: '您的 Email 驗證碼',
      html,
      text,
      // 使用 tags 追蹤郵件類型
      tags: [
        { name: 'category', value: 'verification' },
        { name: 'environment', value: Deno.env.get('ENVIRONMENT') || 'development' }
      ]
    })
  });

  if (!response.ok) {
    const errorData = await response.json();
    throw new ResendAPIError(response.status, errorData);
  }

  const data = await response.json();
  return {
    emailId: data.id,
    success: true
  };
}

class ResendAPIError extends Error {
  constructor(
    public statusCode: number,
    public errorData: any
  ) {
    super(`Resend API Error: ${errorData.message || 'Unknown error'}`);
    this.name = 'ResendAPIError';
  }
}
```

### 1.3 環境變數配置

在 Supabase Dashboard 或使用 CLI 設定：

```bash
# 使用 Supabase CLI
supabase secrets set RESEND_API_KEY=re_your_api_key_here
supabase secrets set VERIFICATION_EMAIL_FROM="Family Accounting <noreply@yourdomain.com>"
```

---

## 2. Email 模板設計最佳實踐

### 2.1 HTML vs Plain Text

**決策**: 同時提供 HTML 和純文字版本

**理由**:
- HTML 提供更好的使用者體驗（品牌識別、視覺層次）
- Plain text 作為備援（某些郵件客戶端不支援 HTML）
- Resend 會自動生成 plain text，但建議手動提供以確保格式正確

### 2.2 HTML 模板範例

```typescript
// supabase/functions/_shared/email-templates.ts

interface VerificationEmailData {
  code: string;
  userName: string;
  expiresInMinutes: number;
}

export function generateVerificationEmailHTML({
  code,
  userName,
  expiresInMinutes
}: VerificationEmailData): string {
  return `
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Email 驗證碼</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', sans-serif;
      line-height: 1.6;
      color: #333;
      background-color: #f4f4f4;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 600px;
      margin: 40px auto;
      background: #ffffff;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .header {
      background: #00A86B; /* Primary color from design spec */
      color: #ffffff;
      padding: 32px;
      text-align: center;
    }
    .content {
      padding: 32px;
    }
    .code-box {
      background: #F0FCF8;
      border: 2px solid #B9F8E3;
      border-radius: 8px;
      padding: 24px;
      text-align: center;
      margin: 24px 0;
    }
    .code {
      font-size: 36px;
      font-weight: 700;
      letter-spacing: 8px;
      color: #00A86B;
      font-family: 'Courier New', monospace;
    }
    .warning {
      background: #FFF4E6;
      border-left: 4px solid #FFB020;
      padding: 16px;
      margin: 24px 0;
      border-radius: 4px;
    }
    .footer {
      background: #f8f9fa;
      padding: 24px;
      text-align: center;
      font-size: 14px;
      color: #6c757d;
    }
    .button {
      display: inline-block;
      padding: 12px 32px;
      background: #00A86B;
      color: #ffffff !important;
      text-decoration: none;
      border-radius: 6px;
      margin-top: 16px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 style="margin: 0;">📧 Email 驗證</h1>
    </div>
    <div class="content">
      <h2>嗨，${userName}！</h2>
      <p>感謝您註冊家庭記帳應用程式。請使用以下驗證碼完成註冊：</p>
      
      <div class="code-box">
        <div class="code">${code}</div>
      </div>
      
      <div class="warning">
        <strong>⏰ 注意</strong>
        <p style="margin: 8px 0 0 0;">此驗證碼將於 ${expiresInMinutes} 分鐘後過期。</p>
      </div>
      
      <p>如果您沒有要求此驗證碼，請忽略此郵件。</p>
      
      <p style="margin-top: 32px;">
        祝您使用愉快！<br>
        <strong>家庭記帳團隊</strong>
      </p>
    </div>
    <div class="footer">
      <p>此為系統自動發送郵件，請勿直接回覆。</p>
      <p>&copy; 2025 Family Accounting. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
  `.trim();
}

export function generateVerificationEmailText({
  code,
  userName,
  expiresInMinutes
}: VerificationEmailData): string {
  return `
嗨，${userName}！

感謝您註冊家庭記帳應用程式。

您的驗證碼是：${code}

此驗證碼將於 ${expiresInMinutes} 分鐘後過期。

如果您沒有要求此驗證碼，請忽略此郵件。

祝您使用愉快！
家庭記帳團隊

---
此為系統自動發送郵件，請勿直接回覆。
© 2025 Family Accounting. All rights reserved.
  `.trim();
}
```

### 2.3 品牌識別要點

1. **使用設計規格書中的顏色**:
   - Primary: `#00A86B` (AppColors.primary)
   - Surface: `#FFFFFF`
   - Success: `#F0FCF8` (背景), `#B9F8E3` (邊框)

2. **字型選擇**:
   - 系統字型堆疊 (確保跨平台一致性)
   - 驗證碼使用等寬字體 (`Courier New`) 提高可讀性

3. **響應式設計**:
   - 最大寬度 600px (郵件客戶端標準)
   - 使用 `viewport` meta tag

---

## 3. 錯誤處理策略

### 3.1 API 錯誤分類與處理

```typescript
// supabase/functions/_shared/error-handler.ts

export class EmailServiceError extends Error {
  constructor(
    public code: string,
    public statusCode: number,
    message: string,
    public isRetriable: boolean = false
  ) {
    super(message);
    this.name = 'EmailServiceError';
  }
}

export async function handleResendAPIError(response: Response) {
  const errorData = await response.json();
  const statusCode = response.status;

  // 根據 Resend 錯誤碼分類處理
  switch (statusCode) {
    case 400:
      // 驗證錯誤 (validation_error, invalid_from_address)
      throw new EmailServiceError(
        'VALIDATION_ERROR',
        400,
        `輸入驗證失敗: ${errorData.message}`,
        false // 不可重試
      );

    case 401:
    case 403:
      // API 金鑰問題 (missing_api_key, invalid_api_key)
      throw new EmailServiceError(
        'AUTH_ERROR',
        statusCode,
        'API 金鑰無效或缺失',
        false
      );

    case 422:
      // 參數錯誤 (missing_required_field, invalid_from_address)
      throw new EmailServiceError(
        'INVALID_PARAMETER',
        422,
        errorData.message || '無效的請求參數',
        false
      );

    case 429:
      // 速率限制或配額超限
      if (errorData.message?.includes('daily_quota')) {
        throw new EmailServiceError(
          'DAILY_QUOTA_EXCEEDED',
          429,
          '已達每日發送上限',
          false
        );
      } else if (errorData.message?.includes('monthly_quota')) {
        throw new EmailServiceError(
          'MONTHLY_QUOTA_EXCEEDED',
          429,
          '已達每月發送上限',
          false
        );
      } else {
        throw new EmailServiceError(
          'RATE_LIMIT_EXCEEDED',
          429,
          '請求過於頻繁，請稍後再試',
          true // 可重試
        );
      }

    case 500:
    case 503:
      // 伺服器錯誤 (internal_server_error, application_error)
      throw new EmailServiceError(
        'SERVER_ERROR',
        statusCode,
        'Email 服務暫時無法使用',
        true // 可重試
      );

    default:
      throw new EmailServiceError(
        'UNKNOWN_ERROR',
        statusCode,
        `未知錯誤: ${errorData.message || '請稍後再試'}`,
        true
      );
  }
}
```

### 3.2 重試策略

```typescript
// supabase/functions/_shared/retry-helper.ts

interface RetryOptions {
  maxRetries: number;
  initialDelayMs: number;
  maxDelayMs: number;
  backoffMultiplier: number;
}

const DEFAULT_RETRY_OPTIONS: RetryOptions = {
  maxRetries: 3,
  initialDelayMs: 1000,
  maxDelayMs: 10000,
  backoffMultiplier: 2
};

export async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  options: Partial<RetryOptions> = {}
): Promise<T> {
  const config = { ...DEFAULT_RETRY_OPTIONS, ...options };
  let lastError: Error;

  for (let attempt = 0; attempt <= config.maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;

      // 檢查是否可重試
      if (error instanceof EmailServiceError && !error.isRetriable) {
        throw error;
      }

      // 最後一次嘗試後拋出錯誤
      if (attempt === config.maxRetries) {
        break;
      }

      // 計算延遲時間 (exponential backoff)
      const delay = Math.min(
        config.initialDelayMs * Math.pow(config.backoffMultiplier, attempt),
        config.maxDelayMs
      );

      console.warn(`Email sending failed (attempt ${attempt + 1}/${config.maxRetries + 1}), retrying in ${delay}ms...`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw lastError!;
}
```

### 3.3 無效 Email 地址處理

```typescript
// supabase/functions/_shared/validators.ts

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function validateEmail(email: string): { valid: boolean; error?: string } {
  if (!email || typeof email !== 'string') {
    return { valid: false, error: 'Email 不可為空' };
  }

  if (!EMAIL_REGEX.test(email)) {
    return { valid: false, error: 'Email 格式無效' };
  }

  if (email.length > 254) { // RFC 5321
    return { valid: false, error: 'Email 長度過長' };
  }

  return { valid: true };
}

// 在發送前驗證
export function validateSendVerificationCodeRequest(body: any) {
  const { email } = body;
  
  const emailValidation = validateEmail(email);
  if (!emailValidation.valid) {
    throw new EmailServiceError(
      'INVALID_EMAIL',
      400,
      emailValidation.error!,
      false
    );
  }

  return { email };
}
```

---

## 4. Webhook 設定 (追蹤發送狀態)

### 4.1 Webhook 事件類型

Resend 支援以下事件：
- `email.sent` - Email 成功發送到收件伺服器
- `email.delivered` - Email 成功送達收件匣
- `email.bounced` - Email 被退回 (無效地址、信箱滿等)
- `email.opened` - Email 被開啟 (需啟用 open tracking)
- `email.clicked` - Email 中的連結被點擊 (需啟用 link tracking)

### 4.2 Webhook 端點實作

```typescript
// supabase/functions/resend-webhook/index.ts

import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface WebhookPayload {
  type: string;
  created_at: string;
  data: {
    email_id: string;
    from: string;
    to: string[];
    subject: string;
    created_at: string;
  };
}

serve(async (req: Request) => {
  try {
    // 驗證 webhook 簽章 (建議在生產環境啟用)
    // const signature = req.headers.get('resend-signature');
    // if (!verifyWebhookSignature(req.body, signature)) {
    //   return new Response('Unauthorized', { status: 401 });
    // }

    const payload: WebhookPayload = await req.json();
    
    // 初始化 Supabase 客戶端
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // 記錄 webhook 事件到資料庫
    await supabase
      .from('email_delivery_events')
      .insert({
        email_id: payload.data.email_id,
        event_type: payload.type,
        recipient: payload.data.to[0],
        created_at: payload.created_at,
        payload: payload
      });

    // 處理特定事件
    switch (payload.type) {
      case 'email.bounced':
        // 標記 Email 為無效
        await handleEmailBounced(supabase, payload.data.to[0]);
        break;
      
      case 'email.delivered':
        // 更新驗證碼狀態為已送達
        await updateVerificationCodeStatus(supabase, payload.data.email_id, 'delivered');
        break;
    }

    return new Response('OK', { status: 200 });
  } catch (error) {
    console.error('Webhook processing error:', error);
    return new Response('Internal Server Error', { status: 500 });
  }
});

async function handleEmailBounced(supabase: any, email: string) {
  // 標記 Email 為無效，防止繼續發送
  await supabase
    .from('invalid_emails')
    .upsert({ email, bounced_at: new Date().toISOString() });
}

async function updateVerificationCodeStatus(
  supabase: any,
  emailId: string,
  status: string
) {
  await supabase
    .from('verification_codes')
    .update({ email_delivery_status: status })
    .eq('email_id', emailId);
}
```

### 4.3 Webhook 配置

**開發環境** (使用 ngrok 或 VS Code Port Forwarding):
```bash
# 使用 ngrok 建立本地隧道
ngrok http 54321

# Webhook URL 範例
https://abc123.ngrok.io/functions/v1/resend-webhook
```

**生產環境**:
```
https://your-project.supabase.co/functions/v1/resend-webhook
```

在 Resend Dashboard > Webhooks 中註冊此 URL，選擇需要的事件類型。

### 4.4 資料庫表格 (追蹤發送狀態)

```sql
-- migrations/20251113000003_create_email_delivery_events.sql

CREATE TABLE email_delivery_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  recipient TEXT NOT NULL,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_email_delivery_events_email_id ON email_delivery_events(email_id);
CREATE INDEX idx_email_delivery_events_recipient ON email_delivery_events(recipient);

-- 無效 Email 追蹤表格
CREATE TABLE invalid_emails (
  email TEXT PRIMARY KEY,
  bounced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reason TEXT
);
```

---

## 5. 測試策略

### 5.1 開發環境測試

**使用 Resend 測試模式**:
- 免費方案可以發送到任何 Email，但僅限驗證的網域
- 未驗證網域只能發送到帳號擁有者的 Email

**測試流程**:
```bash
# 1. 啟動本地 Supabase
supabase start

# 2. 部署 Edge Function 到本地
supabase functions deploy send-verification-code --no-verify-jwt

# 3. 測試發送驗證碼
curl -X POST \
  http://localhost:54321/functions/v1/send-verification-code \
  -H "Content-Type: application/json" \
  -d '{"email": "your-test-email@gmail.com"}'
```

### 5.2 單元測試範例

```typescript
// supabase/functions/_shared/email-service.test.ts

import { assertEquals, assertRejects } from "https://deno.land/std@0.190.0/testing/asserts.ts";
import { sendVerificationCode } from "./email-service.ts";

Deno.test("sendVerificationCode - should throw error for invalid email", async () => {
  await assertRejects(
    async () => {
      await sendVerificationCode({
        email: "invalid-email",
        code: "123456",
        userName: "Test User",
        expiresInMinutes: 5
      });
    },
    Error,
    "Email 格式無效"
  );
});

Deno.test("sendVerificationCode - should handle API errors gracefully", async () => {
  // Mock Resend API to return 429 (rate limit)
  // ... test implementation
});
```

### 5.3 整合測試

```typescript
// test/integration/email-flow.test.ts

Deno.test("Complete verification email flow", async () => {
  // 1. 發送驗證碼
  const { emailId } = await sendVerificationCode({
    email: "test@example.com",
    code: "123456",
    userName: "Test User",
    expiresInMinutes: 5
  });

  // 2. 驗證 email_id 已記錄到資料庫
  const { data } = await supabase
    .from('verification_codes')
    .select('*')
    .eq('email_id', emailId)
    .single();

  assertEquals(data.email, "test@example.com");
  assertEquals(data.code, "123456");
});
```

---

## 6. 成本考量與免費方案限制

### 6.1 Resend 定價分析

| 方案 | 月費 | 每月郵件數 | 日限制 | 適用場景 |
|------|------|-----------|--------|---------|
| **Free** | $0 | 3,000 | 100 | 初期測試、小型專案 |
| **Pro** | $20 | 50,000 | 無 | 成長期專案 |
| **Scale** | $90 | 100,000 | 無 | 規模化應用 |

### 6.2 本專案成本預估

**初期階段** (使用 Free 方案):
- 預期使用者: < 1,000 個家庭
- 每月註冊: ~300 個新使用者
- 驗證碼郵件: ~600 封/月 (含重發)
- **結論**: 免費方案足夠使用

**成長期** (升級至 Pro):
- 預期使用者: 1,000 - 10,000 個家庭
- 每月註冊: ~1,500 個新使用者
- 驗證碼郵件: ~3,000 封/月
- **成本**: $20/月

### 6.3 避免超限策略

1. **速率限制**:
   ```typescript
   // 實作使用者級別的發送冷卻時間
   const RESEND_COOLDOWN_SECONDS = 60;
   
   async function checkResendCooldown(email: string): Promise<boolean> {
     const lastSent = await getLastVerificationCodeTime(email);
     const now = new Date();
     const diffSeconds = (now.getTime() - lastSent.getTime()) / 1000;
     
     return diffSeconds >= RESEND_COOLDOWN_SECONDS;
   }
   ```

2. **監控與告警**:
   ```typescript
   // 記錄每日發送量
   await supabase
     .from('daily_email_metrics')
     .upsert({
       date: new Date().toISOString().split('T')[0],
       count: dailyCount + 1
     });
   
   // 當接近 95% 配額時發送告警
   if (dailyCount >= 95) {
     await sendAdminAlert('接近每日郵件配額上限');
   }
   ```

3. **備援機制**:
   - 準備 SendGrid 作為備援（使用環境變數切換）
   - 當 Resend 達到配額時自動切換

---

## 7. 配置需求總結

### 7.1 必要環境變數

在 Supabase Dashboard 或 CLI 中設定：

```bash
# Resend API 金鑰
supabase secrets set RESEND_API_KEY="re_xxxxxxxxxxxxxxxxxxxxxxxxxx"

# 發件人地址 (需驗證網域)
supabase secrets set VERIFICATION_EMAIL_FROM="Family Accounting <noreply@yourdomain.com>"

# 環境標識
supabase secrets set ENVIRONMENT="production"
```

### 7.2 網域驗證步驟

1. 在 Resend Dashboard 新增網域 (例如: `yourdomain.com`)
2. 設定 DNS 記錄 (DKIM, SPF, DMARC):
   ```
   TXT  _dmarc   "v=DMARC1; p=none;"
   TXT  resend   "resend-verification-code"
   TXT  @        "v=spf1 include:resend.com ~all"
   ```
3. 等待驗證 (通常 5-30 分鐘)

### 7.3 Webhook 端點配置

1. 部署 webhook function:
   ```bash
   supabase functions deploy resend-webhook
   ```

2. 在 Resend Dashboard > Webhooks 註冊:
   - URL: `https://your-project.supabase.co/functions/v1/resend-webhook`
   - 事件: `email.sent`, `email.delivered`, `email.bounced`

---

## 8. 實作檢查清單

- [ ] 在 Resend 建立帳號並取得 API 金鑰
- [ ] 驗證發送網域 (設定 DNS 記錄)
- [ ] 實作 `email-service.ts` (發送驗證碼)
- [ ] 實作 `email-templates.ts` (HTML/Text 模板)
- [ ] 實作 `error-handler.ts` (錯誤分類與重試)
- [ ] 實作 `retry-helper.ts` (指數退避重試)
- [ ] 實作 `validators.ts` (Email 格式驗證)
- [ ] 建立 `resend-webhook` Edge Function
- [ ] 建立資料庫表格 `email_delivery_events`
- [ ] 設定環境變數 (RESEND_API_KEY, VERIFICATION_EMAIL_FROM)
- [ ] 撰寫單元測試 (email-service.test.ts)
- [ ] 撰寫整合測試 (email-flow.test.ts)
- [ ] 在 Resend Dashboard 註冊 webhook 端點
- [ ] 測試完整流程 (發送 → 接收 → webhook 觸發)
- [ ] 設定監控與告警 (配額追蹤)

---

## 9. 參考資料

- [Resend API 文件](https://resend.com/docs/introduction)
- [Resend Deno Deploy 範例](https://resend.com/docs/send-with-deno-deploy)
- [Resend Webhook 設定](https://resend.com/docs/dashboard/webhooks/introduction)
- [Resend 錯誤碼參考](https://resend.com/docs/api-reference/errors)
- [Resend Idempotency Keys](https://resend.com/docs/dashboard/emails/idempotency-keys)
- [Supabase Edge Functions 文件](https://supabase.com/docs/guides/functions)
- [RFC 5321 (SMTP)](https://datatracker.ietf.org/doc/html/rfc5321)

---

**研究完成日期**: 2025-11-14  
**下一步**: 
1. 根據 Part A 的認證狀態管理模式實作 Flutter Riverpod 架構
2. 根據 Part B 的 Resend Email API 研究進行 Phase 1 設計（資料模型與 API 合約）

---

# Part C: flutter_secure_storage 最佳實踐

## 執行摘要

**決策**: 使用 `flutter_secure_storage` 搭配平台特定配置儲存 Supabase Auth session token，支援 30 天自動登入

**理由**:
1. **原生加密整合**: iOS 使用 Keychain、Android 使用 EncryptedSharedPreferences + Keystore，無需額外加密層
2. **跨平台一致性**: 統一的 API 介面隱藏平台差異，降低維護成本
3. **安全性保證**: 硬體支援的加密 (iOS Secure Enclave、Android Hardware-backed Keystore)
4. **生命週期管理**: 支援裝置鎖定狀態訪問控制 (iOS accessibility options)
5. **零依賴加密**: 不需要管理加密金鑰，由作業系統負責

**替代方案評估**:
- **shared_preferences**: 純文字儲存，不適合敏感資料
- **Hive (加密模式)**: 需手動管理加密金鑰，增加安全風險
- **sqflite_sqlcipher**: 效能較差，過度工程（僅需 key-value 儲存）
- **encrypted_shared_preferences (僅 Android)**: 不支援 iOS，需額外實作

---

# Part D: PostgreSQL 驗證碼失敗嘗試追蹤實作

## 執行摘要

**決策**: 使用 PostgreSQL 行級鎖 (`SELECT FOR UPDATE`) + 觸發器 (Triggers) + 列舉型別 (ENUM) 實作驗證碼失敗嘗試追蹤，支援 5 次失敗後鎖定

**理由**:
1. **並發安全**: `SELECT FOR UPDATE` 提供行級鎖，防止競態條件 (race condition)
2. **原子性保證**: 單一交易中完成讀取 → 驗證 → 更新，符合 ACID 特性
3. **自動清理**: 使用 PostgreSQL `pg_cron` 或觸發器自動刪除過期驗證碼
4. **效能優化**: 複合索引 (`email`, `status`, `expires_at`) 支援快速查詢
5. **狀態明確**: ENUM 型別確保狀態一致性 (`pending`, `verified`, `locked`, `expired`)

**替代方案評估**:
- **Redis 計數器**: 效能最佳但無法保證持久性（適合純快取場景）
- **應用程式層鎖**: 無法處理多實例部署的並發問題
- **樂觀鎖 (version column)**: 需重試機制，增加程式碼複雜度
- **分散式鎖 (e.g., Redis SETNX)**: 過度工程，增加依賴與故障點

---

## 1. 資料庫表格結構設計

### 1.1 驗證碼表格 (verification_codes)

```sql
-- migrations/20251114000001_create_verification_codes_table.sql

-- 建立驗證碼狀態列舉
CREATE TYPE verification_status AS ENUM (
  'pending',    -- 等待驗證
  'verified',   -- 已驗證
  'locked',     -- 已鎖定 (失敗次數達上限)
  'expired'     -- 已過期
);

-- 建立驗證碼表格
CREATE TABLE verification_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  
  -- 嘗試追蹤欄位
  attempt_count INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 5,
  status verification_status NOT NULL DEFAULT 'pending',
  
  -- 時間戳記
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  locked_at TIMESTAMPTZ,
  verified_at TIMESTAMPTZ,
  
  -- Email 發送追蹤
  email_id TEXT, -- Resend Email ID
  email_delivery_status TEXT, -- 'sent', 'delivered', 'bounced'
  
  -- 元資料
  ip_address INET,
  user_agent TEXT,
  
  -- 約束條件
  CONSTRAINT valid_attempt_count CHECK (attempt_count >= 0 AND attempt_count <= max_attempts),
  CONSTRAINT valid_expires_at CHECK (expires_at > created_at)
);

-- 複合索引：支援查詢有效驗證碼
CREATE INDEX idx_verification_codes_email_status_expires 
ON verification_codes(email, status, expires_at) 
WHERE status IN ('pending', 'locked');

-- 單一欄位索引：支援清理過期記錄
CREATE INDEX idx_verification_codes_expires_at 
ON verification_codes(expires_at) 
WHERE status = 'pending';

-- Email 發送追蹤索引
CREATE INDEX idx_verification_codes_email_id 
ON verification_codes(email_id) 
WHERE email_id IS NOT NULL;

-- 新增註解
COMMENT ON TABLE verification_codes IS 'Email 驗證碼表格，支援失敗嘗試追蹤與自動鎖定';
COMMENT ON COLUMN verification_codes.attempt_count IS '當前失敗嘗試次數（成功後重設為 0）';
COMMENT ON COLUMN verification_codes.max_attempts IS '最大嘗試次數（預設 5 次）';
COMMENT ON COLUMN verification_codes.status IS '驗證碼狀態：pending（待驗證）、verified（已驗證）、locked（已鎖定）、expired（已過期）';
```

### 1.2 表格欄位說明

| 欄位名稱 | 型別 | 說明 | 預設值 | 索引 |
|---------|------|------|--------|------|
| `id` | UUID | 主鍵 | `gen_random_uuid()` | PK |
| `email` | TEXT | 接收驗證碼的 Email | - | ✅ (複合) |
| `code` | TEXT | 6 位數驗證碼（雜湊儲存） | - | - |
| `attempt_count` | INTEGER | 失敗嘗試次數 | 0 | - |
| `max_attempts` | INTEGER | 最大嘗試次數 | 5 | - |
| `status` | ENUM | 驗證碼狀態 | `'pending'` | ✅ (複合) |
| `created_at` | TIMESTAMPTZ | 建立時間 | `NOW()` | - |
| `expires_at` | TIMESTAMPTZ | 過期時間 | - | ✅ (單一 + 複合) |
| `locked_at` | TIMESTAMPTZ | 鎖定時間 | `NULL` | - |
| `verified_at` | TIMESTAMPTZ | 驗證成功時間 | `NULL` | - |
| `email_id` | TEXT | Resend Email ID | `NULL` | ✅ |
| `email_delivery_status` | TEXT | Email 發送狀態 | `NULL` | - |
| `ip_address` | INET | 請求來源 IP | `NULL` | - |
| `user_agent` | TEXT | 瀏覽器 User-Agent | `NULL` | - |

---

## 2. 並發安全的原子操作

### 2.1 核心查詢模式：SELECT FOR UPDATE

**問題**: 同一使用者可能在短時間內多次提交驗證碼（例如：連點按鈕），導致競態條件：

```
時間  | 交易 A                 | 交易 B
------|----------------------|----------------------
T1    | SELECT (count=3)     | -
T2    | -                    | SELECT (count=3)
T3    | UPDATE (count=4)     | -
T4    | -                    | UPDATE (count=4) ❌ 應為 5
T5    | COMMIT               | -
T6    | -                    | COMMIT
```

**解決方案**: 使用 `FOR UPDATE` 鎖定行，確保交易依序執行：

```sql
-- 查詢並鎖定驗證碼記錄
BEGIN;

SELECT 
  id,
  code,
  attempt_count,
  max_attempts,
  status,
  expires_at
FROM verification_codes
WHERE email = $1
  AND status = 'pending'
  AND expires_at > NOW()
ORDER BY created_at DESC
LIMIT 1
FOR UPDATE; -- 🔒 行級鎖，其他交易需等待此交易完成

-- 驗證程式碼（在應用程式層執行）

-- 更新嘗試次數或狀態
UPDATE verification_codes
SET 
  attempt_count = attempt_count + 1,
  status = CASE 
    WHEN attempt_count + 1 >= max_attempts THEN 'locked'::verification_status
    ELSE status
  END,
  locked_at = CASE 
    WHEN attempt_count + 1 >= max_attempts THEN NOW()
    ELSE locked_at
  END
WHERE id = $2;

COMMIT;
```

### 2.2 Edge Function 實作範例

```typescript
// supabase/functions/_shared/verification-service.ts

import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { createHash } from 'https://deno.land/std@0.190.0/node/crypto.ts';

interface VerifyCodeResult {
  success: boolean;
  error?: string;
  attemptsRemaining?: number;
  isLocked?: boolean;
}

export async function verifyCode(
  supabase: SupabaseClient,
  email: string,
  inputCode: string
): Promise<VerifyCodeResult> {
  try {
    // 🔒 開啟交易並鎖定記錄
    const { data: record, error: selectError } = await supabase
      .rpc('get_and_lock_verification_code', { 
        p_email: email 
      })
      .single();

    if (selectError || !record) {
      return {
        success: false,
        error: '驗證碼不存在或已過期',
      };
    }

    // 檢查狀態
    if (record.status === 'locked') {
      return {
        success: false,
        error: '驗證碼已鎖定，請重新發送驗證碼',
        isLocked: true,
      };
    }

    if (record.status === 'expired') {
      return {
        success: false,
        error: '驗證碼已過期',
      };
    }

    // 驗證程式碼（使用 bcrypt 比對雜湊值）
    const isValid = await compareCode(inputCode, record.code);

    if (isValid) {
      // ✅ 驗證成功
      await supabase
        .from('verification_codes')
        .update({
          status: 'verified',
          verified_at: new Date().toISOString(),
          attempt_count: 0, // 重設計數器
        })
        .eq('id', record.id);

      return { success: true };
    } else {
      // ❌ 驗證失敗，增加計數器
      const newAttemptCount = record.attempt_count + 1;
      const isNowLocked = newAttemptCount >= record.max_attempts;

      await supabase
        .from('verification_codes')
        .update({
          attempt_count: newAttemptCount,
          status: isNowLocked ? 'locked' : 'pending',
          locked_at: isNowLocked ? new Date().toISOString() : null,
        })
        .eq('id', record.id);

      return {
        success: false,
        error: isNowLocked 
          ? '驗證碼已鎖定，請重新發送驗證碼'
          : '驗證碼錯誤',
        attemptsRemaining: record.max_attempts - newAttemptCount,
        isLocked: isNowLocked,
      };
    }
  } catch (error) {
    console.error('Verification error:', error);
    return {
      success: false,
      error: '系統錯誤，請稍後再試',
    };
  }
}

async function compareCode(input: string, hashedCode: string): Promise<boolean> {
  // 實作 bcrypt 比對或直接比對（開發環境）
  // 生產環境建議使用 bcrypt
  return input === hashedCode; // 簡化範例
}
```

### 2.3 PostgreSQL 函式：原子查詢與鎖定

```sql
-- migrations/20251114000002_create_verification_functions.sql

-- 函式：查詢並鎖定驗證碼記錄
CREATE OR REPLACE FUNCTION get_and_lock_verification_code(
  p_email TEXT
)
RETURNS TABLE (
  id UUID,
  code TEXT,
  attempt_count INTEGER,
  max_attempts INTEGER,
  status verification_status,
  expires_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    vc.id,
    vc.code,
    vc.attempt_count,
    vc.max_attempts,
    vc.status,
    vc.expires_at
  FROM verification_codes vc
  WHERE vc.email = p_email
    AND vc.status IN ('pending', 'locked')
    AND vc.expires_at > NOW()
  ORDER BY vc.created_at DESC
  LIMIT 1
  FOR UPDATE; -- 🔒 行級鎖
END;
$$;

-- 函式：產生新驗證碼（重設嘗試計數器）
CREATE OR REPLACE FUNCTION create_verification_code(
  p_email TEXT,
  p_code TEXT,
  p_expires_in_minutes INTEGER DEFAULT 5,
  p_email_id TEXT DEFAULT NULL,
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  v_id UUID;
BEGIN
  -- 將該 Email 的所有待驗證碼標記為過期
  UPDATE verification_codes
  SET status = 'expired'
  WHERE email = p_email
    AND status = 'pending';

  -- 插入新驗證碼
  INSERT INTO verification_codes (
    email,
    code,
    expires_at,
    email_id,
    ip_address,
    user_agent
  ) VALUES (
    p_email,
    p_code,
    NOW() + (p_expires_in_minutes || ' minutes')::INTERVAL,
    p_email_id,
    p_ip_address,
    p_user_agent
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;
```

---

## 3. 重發驗證碼策略（60 秒冷卻時間）

### 3.1 檢查冷卻時間

```sql
-- 函式：檢查是否可重發驗證碼
CREATE OR REPLACE FUNCTION can_resend_verification_code(
  p_email TEXT,
  p_cooldown_seconds INTEGER DEFAULT 60
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  v_last_created_at TIMESTAMPTZ;
BEGIN
  -- 查詢最近一次建立時間
  SELECT created_at INTO v_last_created_at
  FROM verification_codes
  WHERE email = p_email
  ORDER BY created_at DESC
  LIMIT 1;

  -- 無記錄或超過冷卻時間
  IF v_last_created_at IS NULL OR 
     NOW() - v_last_created_at > (p_cooldown_seconds || ' seconds')::INTERVAL THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$;
```

### 3.2 Edge Function 實作

```typescript
// supabase/functions/resend-verification-code/index.ts

export async function resendVerificationCode(
  supabase: SupabaseClient,
  email: string,
  ipAddress?: string,
  userAgent?: string
): Promise<{ success: boolean; error?: string; cooldownRemaining?: number }> {
  // 1. 檢查冷卻時間
  const { data: canResend } = await supabase
    .rpc('can_resend_verification_code', { 
      p_email: email,
      p_cooldown_seconds: 60 
    })
    .single();

  if (!canResend) {
    // 計算剩餘冷卻時間
    const { data: lastCode } = await supabase
      .from('verification_codes')
      .select('created_at')
      .eq('email', email)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    const elapsedSeconds = Math.floor(
      (Date.now() - new Date(lastCode.created_at).getTime()) / 1000
    );
    const remainingSeconds = 60 - elapsedSeconds;

    return {
      success: false,
      error: `請等待 ${remainingSeconds} 秒後再重新發送`,
      cooldownRemaining: remainingSeconds,
    };
  }

  // 2. 產生新驗證碼
  const newCode = generateSixDigitCode();
  const hashedCode = await hashCode(newCode); // 使用 bcrypt

  // 3. 發送 Email
  const { emailId } = await sendVerificationCode({
    email,
    code: newCode,
    userName: email.split('@')[0],
    expiresInMinutes: 5,
  });

  // 4. 儲存到資料庫（自動將舊驗證碼標記為過期）
  const { data: codeId } = await supabase
    .rpc('create_verification_code', {
      p_email: email,
      p_code: hashedCode,
      p_expires_in_minutes: 5,
      p_email_id: emailId,
      p_ip_address: ipAddress,
      p_user_agent: userAgent,
    })
    .single();

  return { success: true };
}

function generateSixDigitCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

async function hashCode(code: string): Promise<string> {
  // 生產環境使用 bcrypt
  // 開發環境可直接儲存明文（僅測試用）
  return code; // 簡化範例
}
```

---

## 4. 自動清理過期驗證碼

### 4.1 使用 PostgreSQL 觸發器

```sql
-- migrations/20251114000003_create_cleanup_trigger.sql

-- 函式：自動標記過期驗證碼
CREATE OR REPLACE FUNCTION mark_expired_verification_codes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE verification_codes
  SET status = 'expired'
  WHERE status = 'pending'
    AND expires_at < NOW();

  RETURN NULL;
END;
$$;

-- 觸發器：每次查詢時檢查過期記錄
CREATE TRIGGER trigger_mark_expired_codes
AFTER INSERT OR UPDATE ON verification_codes
FOR EACH STATEMENT
EXECUTE FUNCTION mark_expired_verification_codes();
```

### 4.2 使用 Supabase Cron Jobs (推薦)

```sql
-- 啟用 pg_cron 擴展
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 每 5 分鐘清理過期驗證碼
SELECT cron.schedule(
  'cleanup-expired-verification-codes',
  '*/5 * * * *', -- 每 5 分鐘
  $$
    UPDATE verification_codes
    SET status = 'expired'
    WHERE status = 'pending'
      AND expires_at < NOW();
  $$
);

-- 每日刪除 7 天前的已驗證/已過期記錄
SELECT cron.schedule(
  'delete-old-verification-codes',
  '0 2 * * *', -- 每天凌晨 2 點
  $$
    DELETE FROM verification_codes
    WHERE status IN ('verified', 'expired')
      AND created_at < NOW() - INTERVAL '7 days';
  $$
);
```

---

## 5. 查詢模式與效能優化

### 5.1 常見查詢模式

```sql
-- 查詢 1：檢查驗證碼狀態（驗證前）
SELECT 
  id,
  status,
  attempt_count,
  max_attempts,
  expires_at
FROM verification_codes
WHERE email = 'user@example.com'
  AND status IN ('pending', 'locked')
  AND expires_at > NOW()
ORDER BY created_at DESC
LIMIT 1;

-- 查詢 2：驗證碼統計（管理後台）
SELECT 
  status,
  COUNT(*) as count,
  AVG(attempt_count) as avg_attempts
FROM verification_codes
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY status;

-- 查詢 3：異常偵測（頻繁失敗的 Email）
SELECT 
  email,
  COUNT(*) as locked_count,
  MAX(created_at) as last_locked_at
FROM verification_codes
WHERE status = 'locked'
  AND created_at > NOW() - INTERVAL '1 hour'
GROUP BY email
HAVING COUNT(*) > 3
ORDER BY locked_count DESC;
```

### 5.2 索引策略說明

| 索引名稱 | 欄位 | 使用場景 | 過濾條件 |
|---------|------|---------|---------|
| `idx_verification_codes_email_status_expires` | `(email, status, expires_at)` | 查詢有效驗證碼 | `status IN ('pending', 'locked')` |
| `idx_verification_codes_expires_at` | `(expires_at)` | 清理過期記錄 | `status = 'pending'` |
| `idx_verification_codes_email_id` | `(email_id)` | Webhook 追蹤 | `email_id IS NOT NULL` |

**索引大小評估** (假設 10 萬筆資料):
- 複合索引: ~8 MB (partial index with WHERE clause)
- 單一索引: ~2 MB
- 總計: ~10 MB (可忽略不計)

### 5.3 EXPLAIN ANALYZE 範例

```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT id, code, attempt_count, status
FROM verification_codes
WHERE email = 'test@example.com'
  AND status = 'pending'
  AND expires_at > NOW()
ORDER BY created_at DESC
LIMIT 1;

-- 預期結果：
-- Index Scan using idx_verification_codes_email_status_expires
-- Filter: (expires_at > now())
-- Rows: 1
-- Execution Time: 0.05 ms
```

---

## 6. 邊界情況處理

### 6.1 競態條件 (Race Condition)

**問題**: 兩個請求同時查詢驗證碼，都讀取到 `attempt_count = 4`，更新後變成 `5` 和 `5`（應為 `5` 和 `6`）

**解決方案**: `FOR UPDATE` 確保交易依序執行

```sql
-- 交易 A
BEGIN;
SELECT ... FOR UPDATE; -- 🔒 鎖定
UPDATE ... SET attempt_count = attempt_count + 1;
COMMIT; -- 🔓 釋放鎖

-- 交易 B（等待交易 A 完成）
BEGIN;
SELECT ... FOR UPDATE; -- ⏳ 等待鎖釋放
UPDATE ... SET attempt_count = attempt_count + 1;
COMMIT;
```

### 6.2 時鐘偏移 (Clock Skew)

**問題**: 應用程式伺服器時間與資料庫伺服器時間不一致

**解決方案**: 統一使用資料庫時間 (`NOW()`)

```sql
-- ❌ 錯誤：使用應用程式時間
INSERT INTO verification_codes (expires_at) 
VALUES ('2025-11-14 10:00:00'); -- 應用程式時間

-- ✅ 正確：使用資料庫時間
INSERT INTO verification_codes (expires_at) 
VALUES (NOW() + INTERVAL '5 minutes');
```

### 6.3 鎖等待逾時

**問題**: 交易等待鎖超過資料庫逾時時間

**解決方案**: 設定合理的鎖等待逾時

```sql
-- 設定交易級別的鎖等待逾時 (5 秒)
SET LOCAL lock_timeout = '5s';

BEGIN;
SELECT ... FOR UPDATE; -- 最多等待 5 秒
COMMIT;
```

```typescript
// Edge Function 中處理逾時
try {
  await supabase.rpc('get_and_lock_verification_code', { p_email: email });
} catch (error) {
  if (error.code === '55P03') { // lock_not_available
    return {
      success: false,
      error: '系統繁忙，請稍後再試',
    };
  }
  throw error;
}
```

### 6.4 驗證碼碰撞 (Code Collision)

**問題**: 不同使用者可能產生相同的 6 位數驗證碼

**解決方案**: 
1. **不需要處理**：驗證碼與 Email 綁定，碰撞不影響安全性
2. **選擇性增強**：使用 8 位數或英數混合 (機率降低至 1/36^8)

```typescript
// 產生 8 位數英數驗證碼
function generateAlphanumericCode(length = 8): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 排除易混淆字元 (0/O, 1/I)
  let code = '';
  for (let i = 0; i < length; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}
```

---

## 7. 安全性考量

### 7.1 驗證碼雜湊儲存

**理由**: 即使資料庫洩漏，攻擊者也無法直接取得驗證碼

```typescript
import * as bcrypt from "https://deno.land/x/bcrypt@v0.4.1/mod.ts";

// 產生雜湊
async function hashCode(code: string): Promise<string> {
  const salt = await bcrypt.genSalt(10);
  return await bcrypt.hash(code, salt);
}

// 驗證
async function compareCode(inputCode: string, hashedCode: string): Promise<boolean> {
  return await bcrypt.compare(inputCode, hashedCode);
}
```

**注意**: bcrypt 較慢（~100ms），適合低頻操作（驗證碼）

### 7.2 防止暴力破解

1. **5 次嘗試上限** + **60 秒重發冷卻**
2. **IP 速率限制** (Supabase Edge Functions + Cloudflare Rate Limiting)
3. **CAPTCHA** (鎖定後要求 reCAPTCHA v3)

```sql
-- 追蹤 IP 地址的驗證嘗試
CREATE TABLE verification_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ip_address INET NOT NULL,
  email TEXT NOT NULL,
  success BOOLEAN NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_verification_attempts_ip_created 
ON verification_attempts(ip_address, created_at);

-- 檢查 IP 是否超過速率限制 (10 次/小時)
SELECT COUNT(*) > 10 AS is_rate_limited
FROM verification_attempts
WHERE ip_address = $1
  AND created_at > NOW() - INTERVAL '1 hour';
```

### 7.3 防止列舉攻擊 (Email Enumeration)

**問題**: 攻擊者可透過「驗證碼不存在」回應判斷 Email 是否已註冊

**解決方案**: 統一錯誤訊息

```typescript
// ❌ 錯誤：洩漏資訊
if (!record) {
  return { error: '此 Email 未註冊' }; // 洩漏使用者是否存在
}

// ✅ 正確：統一回應
if (!record || record.status !== 'pending') {
  return { error: '驗證碼無效或已過期' }; // 不洩漏具體原因
}
```

---

## 8. 監控與告警

### 8.1 關鍵指標

```sql
-- 每小時鎖定次數（異常偵測）
SELECT 
  DATE_TRUNC('hour', locked_at) AS hour,
  COUNT(*) AS locked_count
FROM verification_codes
WHERE status = 'locked'
  AND locked_at > NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour DESC;

-- 平均驗證嘗試次數
SELECT 
  AVG(attempt_count) AS avg_attempts,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY attempt_count) AS median_attempts,
  MAX(attempt_count) AS max_attempts
FROM verification_codes
WHERE status = 'verified'
  AND verified_at > NOW() - INTERVAL '24 hours';

-- Email 送達率
SELECT 
  email_delivery_status,
  COUNT(*) AS count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM verification_codes
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY email_delivery_status;
```

### 8.2 告警設定 (Supabase Dashboard Webhooks)

```typescript
// supabase/functions/monitoring-alerts/index.ts

// 檢查異常鎖定率（每小時超過 50 次）
const { data: recentLocks } = await supabase
  .from('verification_codes')
  .select('id')
  .eq('status', 'locked')
  .gte('locked_at', new Date(Date.now() - 3600000).toISOString());

if (recentLocks.length > 50) {
  await sendAdminAlert({
    severity: 'high',
    message: `異常驗證碼鎖定率：過去 1 小時有 ${recentLocks.length} 次鎖定`,
  });
}
```

---

## 9. 完整實作範例

### 9.1 Edge Function: 發送驗證碼

```typescript
// supabase/functions/send-verification-code/index.ts

import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from '@supabase/supabase-js@2';

serve(async (req: Request) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  try {
    const { email } = await req.json();

    // 1. 驗證 Email 格式
    if (!isValidEmail(email)) {
      return new Response(
        JSON.stringify({ error: 'Email 格式無效' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // 2. 檢查冷卻時間
    const { data: canResend } = await supabase
      .rpc('can_resend_verification_code', { 
        p_email: email,
        p_cooldown_seconds: 60 
      })
      .single();

    if (!canResend) {
      return new Response(
        JSON.stringify({ error: '請稍後再重新發送驗證碼' }),
        { status: 429, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // 3. 產生驗證碼
    const code = generateSixDigitCode();

    // 4. 發送 Email
    const { emailId } = await sendVerificationEmail({
      email,
      code,
      userName: email.split('@')[0],
      expiresInMinutes: 5,
    });

    // 5. 儲存到資料庫
    await supabase.rpc('create_verification_code', {
      p_email: email,
      p_code: code, // 生產環境應雜湊
      p_expires_in_minutes: 5,
      p_email_id: emailId,
      p_ip_address: req.headers.get('x-forwarded-for'),
      p_user_agent: req.headers.get('user-agent'),
    });

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Send verification code error:', error);
    return new Response(
      JSON.stringify({ error: '系統錯誤' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
```

### 9.2 Edge Function: 驗證驗證碼

```typescript
// supabase/functions/verify-code/index.ts

serve(async (req: Request) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  try {
    const { email, code } = await req.json();

    // 1. 鎖定記錄（原子操作）
    const { data: record, error: lockError } = await supabase
      .rpc('get_and_lock_verification_code', { p_email: email })
      .single();

    if (lockError || !record) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: '驗證碼不存在或已過期' 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // 2. 檢查鎖定狀態
    if (record.status === 'locked') {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: '驗證碼已鎖定，請重新發送',
          isLocked: true 
        }),
        { status: 403, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // 3. 驗證程式碼
    const isValid = code === record.code; // 生產環境使用 bcrypt.compare

    if (isValid) {
      // 成功
      await supabase
        .from('verification_codes')
        .update({
          status: 'verified',
          verified_at: new Date().toISOString(),
        })
        .eq('id', record.id);

      return new Response(
        JSON.stringify({ success: true }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    } else {
      // 失敗
      const newAttemptCount = record.attempt_count + 1;
      const isNowLocked = newAttemptCount >= record.max_attempts;

      await supabase
        .from('verification_codes')
        .update({
          attempt_count: newAttemptCount,
          status: isNowLocked ? 'locked' : 'pending',
          locked_at: isNowLocked ? new Date().toISOString() : null,
        })
        .eq('id', record.id);

      return new Response(
        JSON.stringify({ 
          success: false, 
          error: isNowLocked ? '驗證碼已鎖定' : '驗證碼錯誤',
          attemptsRemaining: record.max_attempts - newAttemptCount,
          isLocked: isNowLocked,
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }
  } catch (error) {
    console.error('Verify code error:', error);
    return new Response(
      JSON.stringify({ error: '系統錯誤' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
```

---

## 10. 替代方案比較

| 方案 | 並發安全 | 實作複雜度 | 效能 | 持久性 | 適用場景 |
|------|---------|----------|------|--------|---------|
| **PostgreSQL `FOR UPDATE`** (本方案) | ✅ 強 | 中 | 高 | ✅ 強 | 生產環境 |
| Redis 計數器 (INCR) | ✅ 強 | 低 | 極高 | ⚠️ 中 (需持久化) | 高並發純快取 |
| 應用程式層鎖 | ❌ 弱 (單實例) | 高 | 中 | ✅ 強 | 單體應用 |
| 樂觀鎖 (version column) | ⚠️ 中 (需重試) | 高 | 高 | ✅ 強 | 低衝突場景 |
| 分散式鎖 (Redis SETNX) | ✅ 強 | 極高 | 高 | ⚠️ 中 | 微服務架構 |

**選擇 PostgreSQL `FOR UPDATE` 的理由**:
1. ✅ 無額外依賴（已使用 Supabase PostgreSQL）
2. ✅ 強一致性保證（ACID 交易）
3. ✅ 實作簡單（單一 SQL 查詢）
4. ✅ 效能充足（驗證碼驗證屬低頻操作）

---

## 11. 實作檢查清單

- [ ] 建立 `verification_codes` 表格與索引
- [ ] 建立 `verification_status` ENUM 型別
- [ ] 實作 `get_and_lock_verification_code` 函式
- [ ] 實作 `create_verification_code` 函式
- [ ] 實作 `can_resend_verification_code` 函式
- [ ] 實作 `send-verification-code` Edge Function
- [ ] 實作 `verify-code` Edge Function
- [ ] 設定 pg_cron 自動清理過期記錄
- [ ] 實作驗證碼雜湊儲存 (bcrypt)
- [ ] 實作 IP 速率限制
- [ ] 撰寫單元測試（並發安全性）
- [ ] 撰寫整合測試（完整流程）
- [ ] 設定監控告警（鎖定率、送達率）
- [ ] 壓力測試（模擬並發請求）
- [ ] 文件化錯誤碼與回應格式

---

## 12. 效能評估

### 12.1 預期指標

| 指標 | 目標值 | 說明 |
|------|--------|------|
| 驗證碼驗證延遲 | < 100ms (P95) | `FOR UPDATE` + bcrypt 比對 |
| 並發處理能力 | 100 req/s | Supabase Edge Functions 限制 |
| 資料庫連線使用 | < 10% | 使用連線池 |
| 索引命中率 | > 99% | 複合索引優化 |

### 12.2 壓力測試腳本

```typescript
// test/load-test/verify-code-concurrent.ts

import { delay } from "https://deno.land/std@0.190.0/async/delay.ts";

async function concurrentVerifyTest(email: string, code: string, concurrency: number) {
  const results = await Promise.all(
    Array(concurrency).fill(null).map(() => 
      fetch('http://localhost:54321/functions/v1/verify-code', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, code }),
      })
    )
  );

  const statuses = results.map(r => r.status);
  console.log('Status distribution:', statuses);
  
  // 驗證：只有 1 個請求應該成功（假設程式碼正確）
  const successCount = statuses.filter(s => s === 200).length;
  console.assert(successCount === 1, `Expected 1 success, got ${successCount}`);
}

// 執行測試
await concurrentVerifyTest('test@example.com', '123456', 10);
```

---

**研究完成日期**: 2025-11-14  
**下一步**: 
1. 實作 `verification_codes` 表格與相關函式
2. 整合 Resend Email API (Part B) 與驗證碼發送流程
3. 撰寫單元測試驗證並發安全性

## 執行摘要

**決策**: 使用 `flutter_secure_storage` 搭配平台特定配置儲存 Supabase Auth session token，支援 30 天自動登入

**理由**:
1. **原生加密整合**: iOS 使用 Keychain、Android 使用 EncryptedSharedPreferences + Keystore，無需額外加密層
2. **跨平台一致性**: 統一的 API 介面隱藏平台差異，降低維護成本
3. **安全性保證**: 硬體支援的加密 (iOS Secure Enclave、Android Hardware-backed Keystore)
4. **生命週期管理**: 支援裝置鎖定狀態訪問控制 (iOS accessibility options)
5. **零依賴加密**: 不需要管理加密金鑰，由作業系統負責

**替代方案評估**:
- **shared_preferences**: 純文字儲存，不適合敏感資料
- **Hive (加密模式)**: 需手動管理加密金鑰，增加安全風險
- **sqflite_sqlcipher**: 效能較差，過度工程（僅需 key-value 儲存）
- **encrypted_shared_preferences (僅 Android)**: 不支援 iOS，需額外實作

---

## 1. iOS Keychain 與 Android Keystore 配置需求

### 1.1 iOS Keychain 配置

**核心概念**: iOS Keychain 是作業系統層級的加密儲存容器，資料由 iOS 管理加密金鑰

**配置選項**:

```dart
// lib/core/storage/secure_storage_config.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const iosOptions = IOSOptions(
  // 🔐 Accessibility 控制資料訪問時機
  accessibility: KeychainAccessibility.first_unlock,
  
  // 🚫 禁止 iCloud Keychain 同步（避免跨裝置共享會話）
  synchronizable: false,
  
  // 📦 設定存取群組（用於 App Extensions 共享資料，例如 Widget）
  // accountName: 'com.yourcompany.familyaccounting',
  
  // 🔑 群組名稱（iOS Keychain Access Group）
  // groupId: 'group.com.yourcompany.familyaccounting',
);
```

**Accessibility 選項詳解**:

| 選項 | 說明 | 適用場景 | 風險 |
|------|------|---------|------|
| `unlocked` | 僅裝置解鎖時可存取 | 高安全性應用 | 背景任務無法存取 |
| **`first_unlock`** (推薦) | 裝置首次解鎖後可存取，直到重開機 | **會話 token (平衡安全性與可用性)** | 裝置未重開機時背景可存取 |
| `always` | 隨時可存取（即使鎖定） | 背景推播 token | 安全性最低 |
| `unlocked_this_device_only` | 僅解鎖時 + 不可遷移 | 生物辨識綁定 | 同 `unlocked` |
| `first_unlock_this_device_only` | 首次解鎖後 + 不可遷移 | 裝置特定會話 | 無法備份還原 |

**本專案選擇**: `first_unlock`
- ✅ 應用程式啟動時可讀取 token（即使鎖屏）
- ✅ 允許背景刷新 token（Supabase Auth 自動刷新）
- ✅ 裝置重開機後需重新解鎖才能存取（安全性保證）
- ⚠️ 不使用 `always`：避免裝置遺失時會話仍有效

**iOS 專案配置**:

1. 在 `ios/Runner/Runner.entitlements` 啟用 Keychain Sharing (如需 App Extensions):
```xml
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.yourcompany.familyaccounting</string>
</array>
```

2. 驗證 Xcode 專案設定:
   - Signing & Capabilities > Keychain Sharing (如需)
   - 確保 Team ID 正確設定

### 1.2 Android Keystore 配置

**核心概念**: Android 6.0+ 使用 Hardware-backed Keystore，加密金鑰儲存於安全硬體 (TEE/Secure Element)

**配置選項**:

```dart
const androidOptions = AndroidOptions(
  // 🔐 使用 EncryptedSharedPreferences (Android Jetpack Security)
  encryptedSharedPreferences: true,
  
  // 🔑 金鑰加密演算法 (RSA for API < 23, AES for API >= 23)
  keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
  
  // 🔐 儲存加密演算法 (推薦 AES-GCM)
  storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  
  // 📝 SharedPreferences 檔案名稱（預設：FlutterSecureStorage）
  // sharedPreferencesName: 'FamilyAccountingSecure',
  
  // 🔓 Android 11+ 未設定裝置鎖時是否重設 Keystore（預設：false）
  // resetOnError: true,
);
```

**加密演算法詳解**:

| 演算法 | 安全性 | 效能 | 支援版本 | 說明 |
|--------|--------|------|---------|------|
| **AES_GCM_NoPadding** (推薦) | 高 | 高 | API 23+ | 現代 AEAD 加密，防篡改 |
| AES_CBC_PKCS7Padding | 中 | 高 | API 18+ | 傳統對稱加密 |
| RSA_ECB_PKCS1Padding | 中 | 低 | All | 用於金鑰包裝 (key wrapping) |

**本專案選擇**:
- `encryptedSharedPreferences: true`：使用 Android Jetpack Security 函式庫
- `AES_GCM_NoPadding`：提供加密 + 認證 (authenticated encryption)
- `RSA_ECB_PKCS1Padding`：用於 API < 23 的金鑰包裝

**Android 專案配置**:

1. 確保 `android/app/build.gradle` 的 minSdkVersion >= 23:
```gradle
android {
    defaultConfig {
        minSdkVersion 23  // Android 6.0 (Marshmallow)
        targetSdkVersion 34
    }
}
```

2. 驗證 ProGuard 規則 (如果啟用混淆):
```proguard
# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
```

### 1.3 統一配置範例

```dart
// lib/core/storage/secure_storage_provider.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 安全儲存 Provider（全域單例）
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );
});
```

---

## 2. Session Token 儲存格式建議

### 2.1 儲存格式決策

**決策**: 分別儲存 JSON 格式的 Session 物件與使用者資料

**格式選項評估**:

| 格式 | 優點 | 缺點 | 適用場景 |
|------|------|------|---------|
| **JSON 物件** (推薦) | 結構化、易擴充、支援版本控制 | 需序列化/反序列化 | **Session 完整資料** |
| Plain String | 簡單、無序列化開銷 | 難以擴充、無結構驗證 | 單一 token 字串 |
| Encrypted Object (自訂) | 雙重加密 | 過度工程、金鑰管理複雜 | ❌ 不必要（OS 已加密） |

### 2.2 推薦儲存結構

```dart
// lib/features/auth/domain/models/session_data.dart

import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_data.freezed.dart';
part 'session_data.g.dart';

/// 儲存於 flutter_secure_storage 的 Session 資料
@freezed
class SessionData with _$SessionData {
  const factory SessionData({
    /// Access Token (JWT)
    required String accessToken,
    
    /// Refresh Token (用於自動刷新)
    required String refreshToken,
    
    /// Token 過期時間 (Unix timestamp)
    required int expiresAt,
    
    /// 使用者 ID
    required String userId,
    
    /// Token 類型（預設：Bearer）
    @Default('Bearer') String tokenType,
    
    /// 儲存版本（用於遷移）
    @Default(1) int version,
  }) = _SessionData;
  
  factory SessionData.fromJson(Map<String, dynamic> json) =>
      _$SessionDataFromJson(json);
}

/// Session 儲存服務
class SessionStorageService {
  static const _sessionKey = 'auth_session_v1';
  static const _userKey = 'auth_user_v1';
  
  final FlutterSecureStorage _storage;
  
  SessionStorageService(this._storage);
  
  /// 儲存 Session
  Future<void> saveSession(SessionData session, User user) async {
    await Future.wait([
      _storage.write(key: _sessionKey, value: jsonEncode(session.toJson())),
      _storage.write(key: _userKey, value: jsonEncode(user.toJson())),
    ]);
  }
  
  /// 讀取 Session
  Future<SessionData?> getSession() async {
    try {
      final sessionJson = await _storage.read(key: _sessionKey);
      if (sessionJson == null) return null;
      
      final data = jsonDecode(sessionJson) as Map<String, dynamic>;
      return SessionData.fromJson(data);
    } catch (e) {
      // 解析失敗，清除損壞的資料
      await clearSession();
      return null;
    }
  }
  
  /// 讀取使用者資料
  Future<User?> getUser() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      if (userJson == null) return null;
      
      final data = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(data);
    } catch (e) {
      return null;
    }
  }
  
  /// 檢查 Session 是否過期
  Future<bool> isSessionExpired() async {
    final session = await getSession();
    if (session == null) return true;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= session.expiresAt;
  }
  
  /// 清除 Session
  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _sessionKey),
      _storage.delete(key: _userKey),
    ]);
  }
  
  /// 清除所有儲存（登出或重設）
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

### 2.3 金鑰命名規範

**規範**:
- 使用前綴區分功能模組：`auth_`, `user_`, `app_`
- 使用版本後綴支援遷移：`_v1`, `_v2`
- 使用底線分隔：`auth_session_v1`

**範例**:
```dart
class StorageKeys {
  // 認證相關
  static const authSessionV1 = 'auth_session_v1';
  static const authUserV1 = 'auth_user_v1';
  
  // 使用者偏好
  static const userThemeMode = 'user_theme_mode';
  static const userLanguage = 'user_language';
  
  // 應用程式狀態
  static const appFirstLaunch = 'app_first_launch';
}
```

---

## 3. 跨平台加密一致性考量

### 3.1 加密差異與解決方案

**問題**: iOS 與 Android 使用不同的加密機制

**解決策略**:

1. **不依賴跨平台遷移**: 會話 token 綁定裝置，不需要跨平台轉移
2. **統一序列化格式**: 使用 JSON 作為中間格式
3. **版本控制**: 實作遷移機制支援格式變更

```dart
class SessionMigrationService {
  Future<SessionData?> migrateSession(String oldJson) async {
    final data = jsonDecode(oldJson) as Map<String, dynamic>;
    final version = data['version'] as int? ?? 1;
    
    switch (version) {
      case 1:
        return SessionData.fromJson(data);
      default:
        throw UnsupportedError('Unknown session version: $version');
    }
  }
}
```

---

## 4. 錯誤處理：儲存失敗與裝置鎖定狀態

### 4.1 常見錯誤場景

| 錯誤類型 | iOS 原因 | Android 原因 | 處理策略 |
|---------|---------|-------------|---------|
| **裝置未設定鎖屏** | Keychain 無法使用 | Keystore 初始化失敗 | 提示使用者設定 PIN/密碼 |
| **資料損壞** | Keychain 資料損壞 | 加密金鑰遺失 | 清除並重新登入 |
| **背景存取限制** | Accessibility 設定錯誤 | N/A | 重新配置 Accessibility |

### 4.2 錯誤處理實作

```dart
// lib/core/storage/secure_storage_error_handler.dart

class SecureStorageException implements Exception {
  final String message;
  final SecureStorageErrorType type;
  final Object? originalError;
  
  SecureStorageException(this.message, this.type, [this.originalError]);
}

enum SecureStorageErrorType {
  deviceNotSecured,
  storageUnavailable,
  dataCorrupted,
  accessDenied,
  unknown,
}

class SafeSessionStorageService extends SessionStorageService {
  SafeSessionStorageService(super.storage);
  
  @override
  Future<void> saveSession(SessionData session, User user) async {
    try {
      await super.saveSession(session, user);
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('keystore')) {
        throw SecureStorageException(
          '請先設定裝置螢幕鎖定 (PIN/密碼/生物辨識)',
          SecureStorageErrorType.deviceNotSecured,
        );
      }
      
      if (errorMessage.contains('decryptionerror')) {
        await clearSession();
        throw SecureStorageException(
          '儲存資料損壞，請重新登入',
          SecureStorageErrorType.dataCorrupted,
        );
      }
      
      rethrow;
    }
  }
}
```

---

## 5. Token 遷移策略（版本變更）

### 5.1 版本控制機制

```dart
// lib/core/storage/storage_migration.dart

class StorageMigration {
  static const currentVersion = 1;
  
  final FlutterSecureStorage _storage;
  
  StorageMigration(this._storage);
  
  /// 檢查並執行遷移
  Future<void> migrateIfNeeded() async {
    final versionKey = 'storage_version';
    final storedVersion = await _storage.read(key: versionKey);
    
    if (storedVersion == null) {
      await _storage.write(key: versionKey, value: '$currentVersion');
      return;
    }
    
    final version = int.tryParse(storedVersion) ?? 1;
    
    if (version < currentVersion) {
      await _performMigration(version, currentVersion);
      await _storage.write(key: versionKey, value: '$currentVersion');
    }
  }
  
  Future<void> _performMigration(int fromVersion, int toVersion) async {
    // 實作遷移邏輯
  }
}
```

---

## 6. 測試安全儲存的方法

### 6.1 單元測試策略

```dart
// test/core/storage/mocks.dart

import 'package:mockito/mockito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {
  final Map<String, String> _storage = {};
  
  @override
  Future<void> write({required String key, required String? value}) async {
    if (value != null) {
      _storage[key] = value;
    }
  }
  
  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }
  
  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }
}
```

### 6.2 整合測試

```dart
// integration_test/secure_storage_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('應能儲存與讀取 Session', (tester) async {
    final storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    
    const testKey = 'test_session';
    const testValue = '{"token":"test123"}';
    
    await storage.write(key: testKey, value: testValue);
    final readValue = await storage.read(key: testKey);
    
    expect(readValue, equals(testValue));
    
    await storage.delete(key: testKey);
  });
}
```

---

## 7. 常見陷阱與最佳實踐

### 7.1 常見錯誤

| 陷阱 | 說明 | 後果 | 正確做法 |
|------|------|------|---------|
| **使用 `synchronizable: true`** | 會話 token 同步至 iCloud | 跨裝置共享會話 | ❌ 禁用同步 |
| **未處理裝置未鎖定錯誤** | Android Keystore 需要裝置鎖定 | 應用程式崩潰 | ✅ 捕捉並提示使用者 |
| **儲存明文密碼** | 即使加密儲存也不應保留密碼 | 洩漏風險 | ✅ 僅儲存 token |
| **頻繁 deleteAll()** | 清除所有應用程式資料 | 使用者偏好遺失 | ✅ 僅刪除特定金鑰 |

### 7.2 最佳實踐清單

✅ **DO**:
- 使用 `first_unlock` (iOS) 平衡安全性與可用性
- 使用 `encryptedSharedPreferences: true` (Android)
- 實作版本控制與遷移機制
- 在 try-catch 中處理所有儲存操作
- 登出時清除所有認證資料

❌ **DON'T**:
- 不要儲存明文密碼
- 不要使用 `synchronizable: true`
- 不要忽略儲存錯誤
- 不要假設資料永遠存在

---

## 8. 安全性檢查清單

- [ ] iOS: `synchronizable: false`（禁用 iCloud 同步）
- [ ] iOS: `accessibility: first_unlock`（限制背景存取）
- [ ] Android: `encryptedSharedPreferences: true`（啟用加密）
- [ ] Android: `minSdkVersion >= 23`（確保 Keystore 支援）
- [ ] 實作 token 過期檢查機制
- [ ] 登出時清除所有認證資料
- [ ] 處理裝置未鎖定錯誤
- [ ] 處理資料損壞錯誤
- [ ] 不在日誌中記錄 token 內容

---

## 9. 完整範例：AuthRepository 整合

```dart
// lib/features/auth/data/repositories/auth_repository_impl.dart

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;
  final SafeSessionStorageService _sessionStorage;
  
  AuthRepositoryImpl(this._supabase, this._sessionStorage);
  
  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.session == null) {
        throw AuthException('登入失敗');
      }
      
      final sessionData = SessionData(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken ?? '',
        expiresAt: response.session!.expiresAt ?? 0,
        userId: response.user!.id,
      );
      
      final user = User.fromSupabaseUser(response.user!);
      await _sessionStorage.saveSession(sessionData, user);
      
      return user;
    } on SecureStorageException catch (e) {
      throw AuthException('無法儲存登入資訊: ${e.message}');
    } catch (e) {
      throw AuthException('登入失敗: $e');
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      await _sessionStorage.clearSession();
    } catch (e) {
      await _sessionStorage.clearSession();
      rethrow;
    }
  }
  
  @override
  Future<User?> getCurrentUser() async {
    try {
      if (await _sessionStorage.isSessionExpired()) {
        await _sessionStorage.clearSession();
        return null;
      }
      
      return await _sessionStorage.getUser();
    } catch (e) {
      await _sessionStorage.clearSession();
      return null;
    }
  }
}
```

---

## 10. 實作檢查清單

- [ ] 安裝 `flutter_secure_storage: ^9.0.0`
- [ ] 設定 iOS `KeychainAccessibility.first_unlock`
- [ ] 設定 Android `encryptedSharedPreferences: true`
- [ ] 實作 `SessionData` 模型（使用 freezed）
- [ ] 實作 `SessionStorageService`
- [ ] 實作 `SafeSessionStorageService`（錯誤處理）
- [ ] 實作 `StorageMigration`（版本控制）
- [ ] 整合至 `AuthRepository`
- [ ] 撰寫單元測試（使用 Mock）
- [ ] 撰寫整合測試（真實裝置）
- [ ] 測試裝置未鎖定情境
- [ ] 驗證 iOS Keychain 配置
- [ ] 驗證 Android ProGuard 規則
- [ ] 安全性檢查清單驗證

---

## 11. 參考資料

- [flutter_secure_storage 官方文件](https://pub.dev/packages/flutter_secure_storage)
- [iOS Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [Android Keystore System](https://developer.android.com/training/articles/keystore)
- [Android EncryptedSharedPreferences](https://developer.android.com/reference/androidx/security/crypto/EncryptedSharedPreferences)
- [OWASP Mobile Security Guide](https://owasp.org/www-project-mobile-security-testing-guide/)

---

**研究完成日期**: 2025-11-14  
**下一步**: 
1. 根據 Part A 的認證狀態管理模式實作 Flutter Riverpod 架構
2. 根據 Part B 的 Resend Email API 研究進行 Phase 1 設計（資料模型與 API 合約）
3. 根據 Part C 的 flutter_secure_storage 研究實作安全儲存服務

---

# Part E: Hono Web Framework 在 Supabase Edge Functions 的完整應用

## 執行摘要

**決策**: 使用 Hono v3+ 作為 Supabase Edge Functions 的 Web 框架，搭配中介軟體模式處理認證 API

**理由**:
1. **原生 Deno 支援**: 專為 Web Standards 設計，與 Deno Deploy/Supabase Edge Functions 完美相容
2. **輕量高效**: 零依賴，bundle size ~12KB，冷啟動時間 <100ms（比 Oak 快 3-5 倍）
3. **型別安全**: TypeScript first，完整的型別推導支援
4. **中介軟體生態系統**: 內建 CORS、Logger、Bearer Auth、Validator 等常用中介軟體
5. **開發體驗優異**: Express-like API 設計，學習曲線平緩，錯誤訊息友善

**替代方案評估**:

| 框架 | Bundle Size | 冷啟動 | 型別支援 | 中介軟體 | Deno 原生支援 | 評分 |
|-----|------------|--------|---------|---------|--------------|------|
| **Hono** | ~12KB | <100ms | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 5/5 |
| Oak | ~45KB | 200-300ms | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 3.5/5 |
| Native Deno HTTP | 0KB | <50ms | ⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐⭐ | 2.5/5 |
| Express.js (via esm.sh) | ~200KB | 500ms+ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ | 2/5 |

**決策依據**:
- Hono 在效能與開發體驗之間達到最佳平衡
- 冷啟動時間對 Edge Functions 至關重要（每次請求可能觸發冷啟動）
- 原生 Deno HTTP 雖然效能最佳，但缺乏中介軟體生態系統
- Oak 雖然成熟但效能不如 Hono
- Express.js 不適合 Deno 環境，bundle size 過大

---

## 1. Hono 完整架構範例

### 1.1 最小可行 Edge Function (MVP)

```typescript
// supabase/functions/auth-api/index.ts

import { Hono } from 'https://deno.land/x/hono@v3.11.7/mod.ts';
import { cors } from 'https://deno.land/x/hono@v3.11.7/middleware.ts';

const app = new Hono();

// CORS 設定 (必須在最前面)
app.use('*', cors({
  origin: ['http://localhost:3000', 'https://yourdomain.com'],
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 600,
}));

// Health Check
app.get('/health', (c) => c.json({ status: 'healthy' }));

// 啟動伺服器
Deno.serve(app.fetch);
```

### 1.2 生產級完整架構

請參考前面完整程式碼範例，包含：
- 型別定義
- 標準化回應格式
- 自訂中介軟體（Supabase 注入、認證、錯誤處理、日誌）
- 請求驗證
- 完整認證端點

---

## 2. 關鍵中介軟體模式

### 2.1 中介軟體執行順序

```
Request 
  → CORS (處理 preflight)
  → Error Handler (捕捉所有錯誤)
  → Logger (記錄請求)
  → Supabase Injection (注入客戶端)
  → Route-specific Middleware (驗證、速率限制)
  → Route Handler
  → Response
```

### 2.2 CORS 配置 (Supabase Edge Functions)

```typescript
app.use('*', cors({
  origin: (origin: string) => {
    const allowed = ['http://localhost:3000', 'https://yourdomain.com'];
    // 開發環境允許所有來源
    if (Deno.env.get('ENVIRONMENT') === 'development') return origin;
    return allowed.includes(origin) ? origin : '';
  },
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 600,
}));
```

**重點**:
- `credentials: true` 時，`origin` 不能為 `*`
- Preflight 請求 (OPTIONS) 自動處理
- 開發環境可動態調整 CORS 政策

### 2.3 請求驗證 (Zod 整合)

```typescript
import { z } from 'https://deno.land/x/zod@v3.22.4/mod.ts';
import { validator } from 'https://deno.land/x/hono@v3.11.7/middleware.ts';

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

app.post('/login',
  validator('json', (value, c) => {
    try {
      return loginSchema.parse(value);
    } catch (error) {
      return c.json({ success: false, error: error.errors }, 400);
    }
  }),
  async (c) => {
    const body = await c.req.json(); // 已驗證
    // ...
  }
);
```

### 2.4 速率限制

```typescript
const rateLimitStore = new Map();

function rateLimit({ windowMs, maxRequests }) {
  return async (c, next) => {
    const key = c.req.header('x-forwarded-for') || 'unknown';
    const now = Date.now();
    const record = rateLimitStore.get(key);

    if (record && record.resetAt < now) {
      rateLimitStore.delete(key);
    }

    if (record && record.count >= maxRequests) {
      const retryAfter = Math.ceil((record.resetAt - now) / 1000);
      return c.json({
        error: `Too many requests. Retry after ${retryAfter}s`
      }, 429);
    }

    if (record) {
      record.count++;
    } else {
      rateLimitStore.set(key, { count: 1, resetAt: now + windowMs });
    }

    await next();
  };
}

// 使用
app.post('/send-verification-code',
  rateLimit({ windowMs: 60000, maxRequests: 3 }),
  handler
);
```

---

## 3. 標準化回應格式

### 3.1 回應結構

**成功**:
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation successful",
  "timestamp": "2025-11-14T10:30:00.000Z"
}
```

**錯誤**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [ ... ]
  },
  "timestamp": "2025-11-14T10:30:00.000Z"
}
```

### 3.2 輔助函式

```typescript
function success<T>(data: T, message?: string) {
  return {
    success: true,
    data,
    message,
    timestamp: new Date().toISOString(),
  };
}

function error(code: string, message: string, details?: any) {
  return {
    success: false,
    error: { code, message, details },
    timestamp: new Date().toISOString(),
  };
}

// 使用
app.get('/api', (c) => c.json(success({ data: 'value' })));
app.post('/api', (c) => c.json(error('INVALID_INPUT', 'Bad request'), 400));
```

---

## 4. 環境變數管理

### 4.1 環境變數存取

```typescript
// supabase/functions/_shared/env.ts

class Environment {
  get(key: string): string {
    const value = Deno.env.get(key);
    if (!value) throw new Error(`Missing env var: ${key}`);
    return value;
  }

  getOptional(key: string): string | undefined {
    return Deno.env.get(key);
  }
}

export const env = new Environment();

// 使用
const apiKey = env.get('RESEND_API_KEY');
const debug = env.getOptional('DEBUG_MODE');
```

### 4.2 設定環境變數

**本地開發**:
```bash
# supabase/.env
SUPABASE_URL=http://localhost:54321
SUPABASE_SERVICE_ROLE_KEY=eyJh...
RESEND_API_KEY=re_xxx
ENVIRONMENT=development
```

**生產環境**:
```bash
supabase secrets set RESEND_API_KEY="re_prod_key"
supabase secrets set ENVIRONMENT="production"
```

---

## 5. 本地開發工作流程

### 5.1 啟動開發環境

```bash
# 1. 啟動 Supabase
supabase start

# 2. 建立函式
supabase functions new auth-api

# 3. 啟動本地伺服器
supabase functions serve auth-api --env-file supabase/.env

# 4. 測試
curl http://localhost:54321/functions/v1/auth-api/health
```

### 5.2 開發工具配置

```json
// supabase/functions/auth-api/deno.json
{
  "tasks": {
    "dev": "supabase functions serve auth-api --env-file ../.env",
    "test": "deno test --allow-net --allow-env",
    "deploy": "supabase functions deploy auth-api"
  },
  "imports": {
    "hono": "https://deno.land/x/hono@v3.11.7/mod.ts",
    "supabase": "https://esm.sh/@supabase/supabase-js@2"
  }
}
```

---

## 6. 測試策略

### 6.1 單元測試

```typescript
import { assertEquals } from 'https://deno.land/std@0.190.0/testing/asserts.ts';

Deno.test('Validation - valid email', () => {
  const result = validateEmail('test@example.com');
  assertEquals(result.valid, true);
});

Deno.test('Validation - invalid email', () => {
  const result = validateEmail('invalid');
  assertEquals(result.valid, false);
});
```

執行:
```bash
deno test --allow-net --allow-env
```

### 6.2 整合測試

```typescript
Deno.test('POST /login - success', async () => {
  const res = await fetch('http://localhost:54321/functions/v1/auth-api/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'test@example.com', password: 'password123' }),
  });

  const data = await res.json();
  assertEquals(res.status, 200);
  assertEquals(data.success, true);
});
```

---

## 7. 部署最佳實踐

### 7.1 部署流程

```bash
# 1. 設定生產環境變數
supabase secrets set RESEND_API_KEY="re_prod_key"

# 2. 部署
supabase functions deploy auth-api

# 3. 檢視日誌
supabase functions logs auth-api --tail

# 4. 測試
curl https://your-project.supabase.co/functions/v1/auth-api/health
```

### 7.2 效能優化

**冷啟動優化**:
```typescript
// ❌ 避免全域初始化
const client = createClient(...); // 冷啟動時執行

// ✅ 使用中介軟體延遲初始化
app.use('*', (c, next) => {
  if (!c.get('client')) {
    c.set('client', createClient(...));
  }
  return next();
});
```

**Bundle Size 優化**:
```typescript
// ✅ 使用具體路徑
import { Hono } from 'https://deno.land/x/hono@v3.11.7/mod.ts';
import { cors } from 'https://deno.land/x/hono@v3.11.7/middleware.ts';
```

---

## 8. 安全性最佳實踐

### 8.1 輸入驗證

```typescript
// 所有使用者輸入必須驗證
app.post('/api', validator('json', schema), handler);
```

### 8.2 敏感資料遮蔽

```typescript
function sanitizeLog(data: any) {
  const sensitive = ['password', 'token', 'api_key'];
  return JSON.parse(JSON.stringify(data, (key, value) => {
    if (sensitive.some(k => key.toLowerCase().includes(k))) {
      return '***REDACTED***';
    }
    return value;
  }));
}

console.log(sanitizeLog({ password: '123', email: 'test@example.com' }));
// { password: '***REDACTED***', email: 'test@example.com' }
```

### 8.3 SQL 注入防護

```typescript
// ✅ 使用 Supabase 參數化查詢
const { data } = await supabase
  .from('users')
  .select('*')
  .eq('email', userInput); // 自動轉義

// ❌ 避免字串拼接
const query = `SELECT * FROM users WHERE email = '${userInput}'`; // 危險！
```

---

## 9. 錯誤處理模式

### 9.1 自訂錯誤類別

```typescript
class AppError extends Error {
  constructor(
    public code: string,
    message: string,
    public statusCode: number = 400
  ) {
    super(message);
  }
}

class ValidationError extends AppError {
  constructor(message: string) {
    super('VALIDATION_ERROR', message, 400);
  }
}

class AuthenticationError extends AppError {
  constructor(message: string) {
    super('AUTHENTICATION_ERROR', message, 401);
  }
}
```

### 9.2 全域錯誤處理

```typescript
app.use('*', async (c, next) => {
  try {
    await next();
  } catch (error) {
    console.error('Error:', error);

    if (error instanceof AppError) {
      return c.json({
        success: false,
        error: {
          code: error.code,
          message: error.message,
        },
      }, error.statusCode);
    }

    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'An unexpected error occurred',
      },
    }, 500);
  }
});
```

---

## 10. 監控與日誌

### 10.1 結構化日誌

```typescript
app.use('*', async (c, next) => {
  const start = Date.now();
  await next();
  
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    method: c.req.method,
    path: c.req.path,
    status: c.res.status,
    duration: `${Date.now() - start}ms`,
    ip: c.req.header('x-forwarded-for'),
  }));
});
```

### 10.2 效能追蹤

```typescript
async function trackMetric(name: string, value: number, tags?: Record<string, string>) {
  console.log(JSON.stringify({
    type: 'metric',
    name,
    value,
    tags,
    timestamp: new Date().toISOString(),
  }));
}

// 使用
await trackMetric('request_duration', 123, { path: '/login' });
```

---

## 11. 實作檢查清單

### Phase 1: 基礎設定
- [ ] 建立 Hono 應用程式
- [ ] 設定 CORS 中介軟體
- [ ] 實作全域錯誤處理
- [ ] 實作結構化日誌
- [ ] 設定環境變數管理

### Phase 2: 認證端點
- [ ] `/send-verification-code`
- [ ] `/verify-code`
- [ ] `/resend-code`
- [ ] `/register`
- [ ] `/login`
- [ ] `/logout`
- [ ] `/session-check`

### Phase 3: 中介軟體
- [ ] Supabase 客戶端注入
- [ ] Bearer Auth 認證
- [ ] 請求驗證 (Zod)
- [ ] 速率限制

### Phase 4: 測試
- [ ] 單元測試（驗證邏輯）
- [ ] 整合測試（API 端點）
- [ ] 效能測試（冷啟動、回應時間）

### Phase 5: 部署
- [ ] 設定生產環境變數
- [ ] 部署到 Supabase
- [ ] 設定監控
- [ ] 撰寫 API 文件

---

## 12. 參考資源

- **Hono 官方文件**: https://hono.dev/
- **Hono GitHub**: https://github.com/honojs/hono
- **Supabase Edge Functions**: https://supabase.com/docs/guides/functions
- **Deno Deploy**: https://deno.com/deploy/docs
- **Zod 驗證**: https://zod.dev/

---

**研究完成日期**: 2025-11-14  
**總結**: Hono 提供了在 Supabase Edge Functions 環境中建構高效能、型別安全的 REST API 的最佳解決方案。其輕量級設計、完整的中介軟體生態系統，以及原生 Deno 支援，使其成為認證 API 開發的理想選擇。

**下一步**: 
1. 根據此研究實作 `supabase/functions/auth-api/index.ts`
2. 整合 Part B (Resend Email) 與 Part D (PostgreSQL 驗證碼追蹤)
3. 建立完整測試套件
4. 部署到 Supabase 並進行端到端測試
