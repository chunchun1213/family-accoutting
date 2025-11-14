import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/api_response_model.dart';
import 'service_locator.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthNotifier extends StateNotifier<AuthUIState> {
  AuthNotifier(this.ref)
      : super(const AuthUIState(
          state: AuthState.initial,
          user: null,
          accessToken: null,
          refreshToken: null,
          errorMessage: '',
        ));

  final Ref ref;

  /// Initialize auth state by checking for existing session
  Future<void> initializeAuth() async {
    state = state.copyWith(state: AuthState.loading);
    try {
      final hasValidSessionUseCase = ref.read(hasValidSessionUseCaseProvider);
      final hasSession = await hasValidSessionUseCase();

      if (hasSession) {
        final getSessionUseCase = ref.read(getSessionUseCaseProvider);
        final sessionData = await getSessionUseCase();

        if (sessionData['accessToken'] != null) {
          // Try to get user info
          final getCurrentUserUseCase = ref.read(getCurrentUserUseCaseProvider);
          try {
            final userInfo = await getCurrentUserUseCase(
              accessToken: sessionData['accessToken']!,
            );

            state = state.copyWith(
              state: AuthState.authenticated,
              user: UserInfo(
                id: userInfo.id,
                email: userInfo.email,
                name: userInfo.name,
              ),
              accessToken: sessionData['accessToken'],
              refreshToken: sessionData['refreshToken'],
              errorMessage: '',
            );
            return;
          } catch (e) {
            // User info fetch failed, still mark as unauthenticated
            state = state.copyWith(state: AuthState.unauthenticated);
            return;
          }
        }
      }

      state = state.copyWith(state: AuthState.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        state: AuthState.error,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(state: AuthState.loading);
    try {
      final loginUseCase = ref.read(loginUseCaseProvider);
      final response = await loginUseCase(email: email, password: password);

      state = state.copyWith(
        state: AuthState.authenticated,
        user: response.user,
        accessToken: response.session.accessToken,
        refreshToken: response.session.refreshToken,
        errorMessage: '',
      );

      _startTokenRefreshTimer();
    } catch (e) {
      state = state.copyWith(
        state: AuthState.error,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<void> logoutUser() async {
    try {
      if (state.accessToken != null) {
        final logoutUseCase = ref.read(logoutUseCaseProvider);
        await logoutUseCase(accessToken: state.accessToken!);
      }
    } catch (e) {
      // Log error but still proceed to clear local session
      print('Logout error: $_getErrorMessage(e)');
    }

    final clearSessionUseCase = ref.read(clearSessionUseCaseProvider);
    await clearSessionUseCase();

    state = const AuthUIState(
      state: AuthState.unauthenticated,
      user: null,
      accessToken: null,
      refreshToken: null,
      errorMessage: '',
    );
  }

  Future<void> refreshAccessToken() async {
    if (state.refreshToken == null) {
      await logoutUser();
      return;
    }

    try {
      final refreshTokenUseCase = ref.read(refreshTokenUseCaseProvider);
      final response = await refreshTokenUseCase(refreshToken: state.refreshToken!);

      state = state.copyWith(
        accessToken: response.session.accessToken,
        refreshToken: response.session.refreshToken,
      );

      _startTokenRefreshTimer();
    } catch (e) {
      // Token refresh failed, logout user
      await logoutUser();
    }
  }

  void _startTokenRefreshTimer() {
    // Refresh token 5 minutes before expiration (typically 1 hour access token)
    Future.delayed(const Duration(minutes: 55), () {
      if (state.state == AuthState.authenticated) {
        refreshAccessToken();
      }
    });
  }

  String _getErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data as Map<String, dynamic>?;
      final errorCode = data?['error']?['code'];
      final errorMsg = data?['error']?['message'] ?? error.message;

      switch (errorCode) {
        case 'INVALID_CREDENTIALS':
          return 'Email 或密碼錯誤';
        case 'EMAIL_NOT_VERIFIED':
          return '請先驗證您的 Email';
        case 'ACCOUNT_LOCKED':
          return '帳戶已鎖定，請稍後重試';
        case 'RATE_LIMIT':
          return '請求過於頻繁，請稍候後重試';
        default:
          return errorMsg ?? '發生錯誤，請稍後重試';
      }
    }
    return error.toString();
  }
}

class AuthUIState {
  final AuthState state;
  final UserInfo? user;
  final String? accessToken;
  final String? refreshToken;
  final String errorMessage;

  const AuthUIState({
    required this.state,
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.errorMessage,
  });

  AuthUIState copyWith({
    AuthState? state,
    UserInfo? user,
    String? accessToken,
    String? refreshToken,
    String? errorMessage,
  }) {
    return AuthUIState(
      state: state ?? this.state,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthUIState>((ref) {
  return AuthNotifier(ref);
});
