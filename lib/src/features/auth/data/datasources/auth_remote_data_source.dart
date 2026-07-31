import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:wr_pmis_mobile/src/features/auth/data/models/auth_session_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// Web form login: POST `/login` as `application/x-www-form-urlencoded`.
  /// Success → HTTP 302 to `/home` (+ `JSESSIONID` cookie).
  /// Failure → HTTP 200 back on `/login`.
  Future<AuthSessionModel> login({
    required String userId,
    required String password,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.loginPath,
      data: <String, dynamic>{
        'user_id': userId,
        'password': password,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
        followRedirects: false,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 400,
        extra: const <String, dynamic>{'skipAuth': true},
      ),
    );

    final int status = response.statusCode ?? 0;
    final String location =
        (response.headers.value('location') ?? '').toLowerCase();
    final bool redirectedHome =
        status == 302 && location.contains('/home');

    if (!redirectedHome) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Invalid user name or password.',
      );
    }

    final String? sessionId = _sessionIdFrom(
      locationHeader: response.headers.value('location'),
      setCookie: response.headers['set-cookie'],
    );

    return AuthSessionModel(
      token: sessionId ?? '',
      userId: userId,
      userName: userId,
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

  String? _sessionIdFrom({
    required String? locationHeader,
    required List<String>? setCookie,
  }) {
    final String location = locationHeader ?? '';
    final RegExp jsessionInUrl = RegExp(
      r'jsessionid=([^;/?#]+)',
      caseSensitive: false,
    );
    final Match? urlMatch = jsessionInUrl.firstMatch(location);
    if (urlMatch != null) {
      return urlMatch.group(1);
    }

    if (setCookie != null) {
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
    }
    return null;
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});
