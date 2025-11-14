import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/api_response_model.dart';

class AuthRemoteDatasource {
  final Dio _dio;
  late final String _apiBaseUrl;

  AuthRemoteDatasource({Dio? dio}) : _dio = dio ?? Dio() {
    _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'https://your-project.supabase.co/functions/v1';
    _dio.options = BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  /// Register user with email, name, and password
  Future<RegisterResponse> registerUser({
    required String email,
    required String name,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'name': name,
          'password': password,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return RegisterResponse.fromJson(responseData['data']);
      }

      throw Exception('Register failed: ${responseData['error']?['message']}');
    } catch (e) {
      rethrow;
    }
  }

  /// Verify email with verification code
  Future<VerifyCodeResponse> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-code',
        data: {
          'email': email,
          'code': code,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return VerifyCodeResponse.fromJson(responseData['data']);
      }

      throw Exception('Verify code failed: ${responseData['error']?['message']}');
    } catch (e) {
      rethrow;
    }
  }

  /// Resend verification code
  Future<ResendCodeResponse> resendVerificationCode({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/resend-code',
        data: {
          'email': email,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return ResendCodeResponse.fromJson(responseData['data']);
      }

      throw Exception('Resend code failed: ${responseData['error']?['message']}');
    } catch (e) {
      rethrow;
    }
  }

  /// Login user with email and password
  Future<LoginResponse> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return LoginResponse.fromJson(responseData['data']);
      }

      throw Exception('Login failed: ${responseData['error']?['message']}');
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user information
  Future<UserInfoResponse> getCurrentUser({
    required String accessToken,
  }) async {
    try {
      final response = await _dio.get(
        '/auth/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return UserInfoResponse.fromJson(responseData['data']);
      }

      throw Exception('Get current user failed: ${responseData['error']?['message']}');
    } catch (e) {
      rethrow;
    }
  }

  /// Logout user
  Future<void> logoutUser({
    required String accessToken,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/logout',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] != true) {
        throw Exception('Logout failed: ${responseData['error']?['message']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh access token
  Future<LoginResponse> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/refresh-token',
        data: {
          'refreshToken': refreshToken,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return LoginResponse.fromJson(responseData['data']);
      }

      throw Exception('Refresh token failed: ${responseData['error']?['message']}');
    } catch (e) {
      rethrow;
    }
  }
}
