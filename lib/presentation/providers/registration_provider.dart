import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/api_response_model.dart';
import 'service_locator.dart';

enum RegistrationState {
  idle,
  loading,
  verifyCodeSent,
  verifying,
  success,
  error,
}

class RegistrationNotifier extends StateNotifier<RegistrationUIState> {
  RegistrationNotifier(this.ref)
      : super(const RegistrationUIState(
          state: RegistrationState.idle,
          userEmail: '',
          userName: '',
          errorMessage: '',
          remainingAttempts: 5,
          canResendCode: false,
        ));

  final Ref ref;
  int _resendCooldownSeconds = 60;

  Future<void> registerUser({
    required String email,
    required String name,
    required String password,
  }) async {
    state = state.copyWith(state: RegistrationState.loading);
    try {
      final registerUseCase = ref.read(registerUseCaseProvider);
      await registerUseCase(
        email: email,
        name: name,
        password: password,
      );

      state = state.copyWith(
        state: RegistrationState.verifyCodeSent,
        userEmail: email,
        userName: name,
        errorMessage: '',
        canResendCode: false,
      );

      _startResendCooldown();
    } catch (e) {
      state = state.copyWith(
        state: RegistrationState.error,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  Future<void> verifyCode({
    required String code,
  }) async {
    state = state.copyWith(state: RegistrationState.verifying);
    try {
      final verifyCodeUseCase = ref.read(verifyCodeUseCaseProvider);
      await verifyCodeUseCase(
        email: state.userEmail,
        code: code,
      );

      state = state.copyWith(
        state: RegistrationState.success,
        errorMessage: '',
      );
    } catch (e) {
      final errorMsg = _getErrorMessage(e);
      state = state.copyWith(
        state: RegistrationState.error,
        errorMessage: errorMsg,
        remainingAttempts: _extractRemainingAttempts(errorMsg),
      );
    }
  }

  Future<void> resendVerificationCode() async {
    if (!state.canResendCode) return;

    state = state.copyWith(state: RegistrationState.loading);
    try {
      final resendUseCase = ref.read(resendVerificationCodeUseCaseProvider);
      await resendUseCase(email: state.userEmail);

      state = state.copyWith(
        state: RegistrationState.verifyCodeSent,
        errorMessage: '',
        canResendCode: false,
      );

      _startResendCooldown();
    } catch (e) {
      state = state.copyWith(
        state: RegistrationState.verifyCodeSent,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  void resetState() {
    state = const RegistrationUIState(
      state: RegistrationState.idle,
      userEmail: '',
      userName: '',
      errorMessage: '',
      remainingAttempts: 5,
      canResendCode: false,
    );
  }

  void _startResendCooldown() {
    _resendCooldownSeconds = 60;
    _updateResendCooldown();
  }

  void _updateResendCooldown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_resendCooldownSeconds > 0) {
        _resendCooldownSeconds--;
        state = state.copyWith(
          canResendCode: _resendCooldownSeconds == 0,
        );
        if (_resendCooldownSeconds > 0) {
          _updateResendCooldown();
        }
      }
    });
  }

  String _getErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data as Map<String, dynamic>?;
      return data?['error']?['message'] ?? error.message ?? '發生錯誤，請稍後重試';
    }
    return error.toString();
  }

  int _extractRemainingAttempts(String errorMsg) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(errorMsg);
    return match != null ? int.tryParse(match.group(1)!) ?? 5 : 5;
  }
}

class RegistrationUIState {
  final RegistrationState state;
  final String userEmail;
  final String userName;
  final String errorMessage;
  final int remainingAttempts;
  final bool canResendCode;

  const RegistrationUIState({
    required this.state,
    required this.userEmail,
    required this.userName,
    required this.errorMessage,
    required this.remainingAttempts,
    required this.canResendCode,
  });

  RegistrationUIState copyWith({
    RegistrationState? state,
    String? userEmail,
    String? userName,
    String? errorMessage,
    int? remainingAttempts,
    bool? canResendCode,
  }) {
    return RegistrationUIState(
      state: state ?? this.state,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      errorMessage: errorMessage ?? this.errorMessage,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
      canResendCode: canResendCode ?? this.canResendCode,
    );
  }
}

final registrationProvider =
    StateNotifierProvider.autoDispose<RegistrationNotifier, RegistrationUIState>((ref) {
  return RegistrationNotifier(ref);
});
