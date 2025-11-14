import '../models/api_response_model.dart';
import '../datasources/session_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

abstract class AuthRepository {
  Future<RegisterResponse> register({
    required String email,
    required String name,
    required String password,
  });

  Future<VerifyCodeResponse> verifyCode({
    required String email,
    required String code,
  });

  Future<ResendCodeResponse> resendVerificationCode({
    required String email,
  });

  Future<LoginResponse> login({
    required String email,
    required String password,
  });

  Future<UserInfoResponse> getCurrentUser({
    required String accessToken,
  });

  Future<void> logout({
    required String accessToken,
  });

  Future<LoginResponse> refreshToken({
    required String refreshToken,
  });

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
  });

  Future<Map<String, String?>> getSession();

  Future<void> clearSession();

  Future<bool> hasValidSession();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDataSource;
  final SessionLocalDatasource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDatasource remoteDataSource,
    required SessionLocalDatasource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<RegisterResponse> register({
    required String email,
    required String name,
    required String password,
  }) async {
    try {
      return await _remoteDataSource.registerUser(
        email: email,
        name: name,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<VerifyCodeResponse> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      return await _remoteDataSource.verifyCode(
        email: email,
        code: code,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ResendCodeResponse> resendVerificationCode({
    required String email,
  }) async {
    try {
      return await _remoteDataSource.resendVerificationCode(email: email);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.loginUser(
        email: email,
        password: password,
      );

      // Save session locally
      await _localDataSource.saveSession(
        accessToken: response.session.accessToken,
        refreshToken: response.session.refreshToken,
        userId: response.user.id,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserInfoResponse> getCurrentUser({
    required String accessToken,
  }) async {
    try {
      return await _remoteDataSource.getCurrentUser(accessToken: accessToken);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout({
    required String accessToken,
  }) async {
    try {
      await _remoteDataSource.logoutUser(accessToken: accessToken);
      await _localDataSource.clearSession();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<LoginResponse> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await _remoteDataSource.refreshToken(
        refreshToken: refreshToken,
      );

      // Update session locally
      await _localDataSource.saveSession(
        accessToken: response.session.accessToken,
        refreshToken: response.session.refreshToken,
        userId: response.user.id,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await _localDataSource.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );
  }

  @override
  Future<Map<String, String?>> getSession() async {
    return await _localDataSource.getSession();
  }

  @override
  Future<void> clearSession() async {
    await _localDataSource.clearSession();
  }

  @override
  Future<bool> hasValidSession() async {
    return await _localDataSource.hasValidSession();
  }
}
