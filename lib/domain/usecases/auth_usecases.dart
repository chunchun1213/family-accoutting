import '../repositories/auth_repository_impl.dart';
import '../models/api_response_model.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<RegisterResponse> call({
    required String email,
    required String name,
    required String password,
  }) async {
    return await repository.register(
      email: email,
      name: name,
      password: password,
    );
  }
}

class VerifyCodeUseCase {
  final AuthRepository repository;

  VerifyCodeUseCase(this.repository);

  Future<VerifyCodeResponse> call({
    required String email,
    required String code,
  }) async {
    final response = await repository.verifyCode(
      email: email,
      code: code,
    );

    // Save session after verification
    await repository.saveSession(
      accessToken: response.session.accessToken,
      refreshToken: response.session.refreshToken,
      userId: response.user.id,
    );

    return response;
  }
}

class ResendVerificationCodeUseCase {
  final AuthRepository repository;

  ResendVerificationCodeUseCase(this.repository);

  Future<ResendCodeResponse> call({
    required String email,
  }) async {
    return await repository.resendVerificationCode(email: email);
  }
}

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<LoginResponse> call({
    required String email,
    required String password,
  }) async {
    return await repository.login(
      email: email,
      password: password,
    );
  }
}

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<UserInfoResponse> call({
    required String accessToken,
  }) async {
    return await repository.getCurrentUser(accessToken: accessToken);
  }
}

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> call({
    required String accessToken,
  }) async {
    return await repository.logout(accessToken: accessToken);
  }
}

class RefreshTokenUseCase {
  final AuthRepository repository;

  RefreshTokenUseCase(this.repository);

  Future<LoginResponse> call({
    required String refreshToken,
  }) async {
    return await repository.refreshToken(refreshToken: refreshToken);
  }
}

class GetSessionUseCase {
  final AuthRepository repository;

  GetSessionUseCase(this.repository);

  Future<Map<String, String?>> call() async {
    return await repository.getSession();
  }
}

class HasValidSessionUseCase {
  final AuthRepository repository;

  HasValidSessionUseCase(this.repository);

  Future<bool> call() async {
    return await repository.hasValidSession();
  }
}

class ClearSessionUseCase {
  final AuthRepository repository;

  ClearSessionUseCase(this.repository);

  Future<void> call() async {
    return await repository.clearSession();
  }
}
