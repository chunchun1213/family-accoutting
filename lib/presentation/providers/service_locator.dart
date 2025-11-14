import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/session_local_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/auth_usecases.dart';

// Datasource providers
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource();
});

final sessionLocalDatasourceProvider = Provider<SessionLocalDatasource>((ref) {
  return SessionLocalDatasource();
});

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDatasourceProvider);
  final localDataSource = ref.watch(sessionLocalDatasourceProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

// Use case providers
final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RegisterUseCase(repository);
});

final verifyCodeUseCaseProvider = Provider<VerifyCodeUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyCodeUseCase(repository);
});

final resendVerificationCodeUseCaseProvider = Provider<ResendVerificationCodeUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ResendVerificationCodeUseCase(repository);
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
});

final refreshTokenUseCaseProvider = Provider<RefreshTokenUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RefreshTokenUseCase(repository);
});

final getSessionUseCaseProvider = Provider<GetSessionUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetSessionUseCase(repository);
});

final hasValidSessionUseCaseProvider = Provider<HasValidSessionUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return HasValidSessionUseCase(repository);
});

final clearSessionUseCaseProvider = Provider<ClearSessionUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ClearSessionUseCase(repository);
});
