import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:wr_pmis_mobile/src/features/auth/data/models/auth_session_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// API-007: POST `/api/v1/login` as JSON.
  /// Success → HTTP 200 + User entity + `JSESSIONID` cookie.
  /// Failure → HTTP 401/400 with `{"error":"..."}`.
  Future<AuthSessionModel> login({
    required String userId,
    required String password,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.apiLoginPath,
      data: <String, dynamic>{
        'user_id': userId,
        'password': password,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
        extra: const <String, dynamic>{
          'skipAuth': true,
          'allowSetCookie': true,
        },
      ),
    );

    final int status = response.statusCode ?? 0;
    final Map<String, dynamic> body = _asMap(response.data);
    final String errorMessage = (body['error'] ?? '').toString().trim();

    if (status == 401 || status == 400 || status == 403) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: errorMessage.isNotEmpty
            ? errorMessage
            : 'Invalid user name or password.',
      );
    }

    if (status != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: errorMessage.isNotEmpty
            ? errorMessage
            : 'Login failed (HTTP $status).',
      );
    }

    if (errorMessage.isNotEmpty && body['user_id'] == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: errorMessage,
      );
    }

    final String? sessionId = _sessionIdFrom(
      setCookie: response.headers['set-cookie'],
    );

    final AuthSessionModel parsed = AuthSessionModel.fromJson(body);
    return AuthSessionModel(
      token: sessionId ?? parsed.token,
      userId: parsed.userId.isNotEmpty ? parsed.userId : userId,
      userName: parsed.userName.isNotEmpty ? parsed.userName : userId,
      emailId: parsed.emailId,
      userRoleNameFk: parsed.userRoleNameFk,
      userTypeFk: parsed.userTypeFk,
      departmentFk: parsed.departmentFk,
      designation: parsed.designation,
    );
  }

  Future<void> logoutSession() async {
    await _dio.get<dynamic>(
      ApiConstants.logoutPath,
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
  }

  static final Options _unauthenticatedOptions = Options(
    extra: const <String, dynamic>{'skipAuth': true},
  );

  Future<void> sendForgotPasswordOtp({required String emailId}) async {
    await _dio.post<Map<String, dynamic>>(
      ApiConstants.forgotSendOtpPath,
      data: <String, dynamic>{'emailId': emailId},
      options: _unauthenticatedOptions,
    );
  }

  Future<void> verifyForgotPasswordOtp({
    required String emailId,
    required String otp,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      ApiConstants.forgotVerifyOtpPath,
      data: <String, dynamic>{'emailId': emailId, 'otp': otp},
      options: _unauthenticatedOptions,
    );
  }

  Future<void> resetForgotPassword({
    required String emailId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      ApiConstants.forgotResetPasswordPath,
      data: <String, dynamic>{
        'emailId': emailId,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      options: _unauthenticatedOptions,
    );
  }

  String? _sessionIdFrom({required List<String>? setCookie}) {
    if (setCookie == null) {
      return null;
    }
    final RegExp cookieRe = RegExp(
      r'JSESSIONID=([^;]+)',
      caseSensitive: false,
    );
    for (final String header in setCookie) {
      final Match? match = cookieRe.firstMatch(header);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );
    }
    return <String, dynamic>{};
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});
