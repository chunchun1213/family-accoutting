import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response_model.freezed.dart';
part 'api_response_model.g.dart';

// Generic ApiResponse (not using freezed due to generic type limitations)
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;
  final String? timestamp;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: json['error'] != null ? ApiError.fromJson(json['error'] as Map<String, dynamic>) : null,
      timestamp: json['timestamp'] as String?,
    );
  }
}

@freezed
class ApiError with _$ApiError {
  const factory ApiError({
    required String code,
    required String message,
    dynamic details,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);
}

@freezed
class RegisterResponse with _$RegisterResponse {
  const factory RegisterResponse({
    required String email,
    required String expiresAt,
    required String message,
  }) = _RegisterResponse;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);
}

@freezed
class VerifyCodeResponse with _$VerifyCodeResponse {
  const factory VerifyCodeResponse({
    required UserInfo user,
    required SessionInfo session,
  }) = _VerifyCodeResponse;

  factory VerifyCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyCodeResponseFromJson(json);
}

@freezed
class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required UserInfo user,
    required SessionInfo session,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

@freezed
class UserInfo with _$UserInfo {
  const factory UserInfo({
    required String id,
    required String email,
    required String name,
  }) = _UserInfo;

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);
}

@freezed
class SessionInfo with _$SessionInfo {
  const factory SessionInfo({
    required String accessToken,
    required String refreshToken,
    required int expiresAt,
  }) = _SessionInfo;

  factory SessionInfo.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoFromJson(json);
}

@freezed
class ResendCodeResponse with _$ResendCodeResponse {
  const factory ResendCodeResponse({
    required String message,
    required String expiresAt,
  }) = _ResendCodeResponse;

  factory ResendCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$ResendCodeResponseFromJson(json);
}

@freezed
class UserInfoResponse with _$UserInfoResponse {
  const factory UserInfoResponse({
    required String id,
    required String email,
    required String name,
    required String createdAt,
    required String updatedAt,
  }) = _UserInfoResponse;

  factory UserInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$UserInfoResponseFromJson(json);
}
