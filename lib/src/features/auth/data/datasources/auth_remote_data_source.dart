import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/config/environment.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:wr_pmis_mobile/src/core/network/session_cookie_manager.dart';
import 'package:wr_pmis_mobile/src/features/auth/data/models/auth_session_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio, this._cookieManager);

  final Dio _dio;
  final SessionCookieManager _cookieManager;

  /// Web form login: POST `/login` as `application/x-www-form-urlencoded`.
  ///
  /// QA/prod do not expose API-007 (`/api/v1/login` → 404). Use the same
  /// form POST as the browser.
  ///
  /// Success → HTTP 302 `Location: …/home` + authenticated `JSESSIONID`.
  /// Failure → HTTP 200 still on `/login` (body still has loginForm).
  ///
  /// Important: home / projects (`/api/v1/projects/list`) need that cookie.
  /// A bare 302 often has **no** `Set-Cookie`, so we warm up GET `/login`
  /// first, then hit `/home` once so the jar keeps the authenticated session.
  Future<AuthSessionModel> login({
    required String userId,
    required String password,
  }) async {
    final Options sessionOptions = Options(
      responseType: ResponseType.plain,
      validateStatus: _okUnder400,
      extra: const <String, dynamic>{
        'skipAuth': true,
        'allowSetCookie': true,
      },
    );

    // 1) Seed anonymous JSESSIONID (same as opening the web login page).
    await _dio.get<dynamic>(ApiConstants.loginPath, options: sessionOptions);

    // 2) Form POST — do not auto-follow; success is 302 → /home.
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.loginPath,
      data: <String, dynamic>{
        'user_id': userId,
        'password': password,
      },
      options: sessionOptions.copyWith(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        maxRedirects: 0,
      ),
    );

    final int status = response.statusCode ?? 0;
    final String body = (response.data ?? '').toString();
    final String finalUrl = response.realUri.toString().toLowerCase();
    final String location =
        (response.headers.value('location') ?? '').toLowerCase();

    // Web success is often a bare 302 to /home while realUri is still /login.
    final bool redirectedToHome =
        status >= 300 && status < 400 && location.contains('/home');
    final bool landedOnHome = finalUrl.contains('/home');
    final bool dashboardHtml = body.toLowerCase().contains('<title') &&
        body.toLowerCase().contains('dashboard');
    final bool looksLikeHome =
        redirectedToHome || landedOnHome || dashboardHtml;

    if (!looksLikeHome) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Invalid user name or password.',
      );
    }

    // 3) Follow redirect once so cookie jar confirms the authenticated session.
    String homeBody = body;
    if (redirectedToHome) {
      final String homePath = _absoluteOrRelativePath(
        response.headers.value('location')!,
      );
      final Response<dynamic> homeResponse = await _dio.get<dynamic>(
        homePath,
        options: sessionOptions.copyWith(followRedirects: true),
      );
      homeBody = (homeResponse.data ?? '').toString();
    }

    final String? sessionId = await _resolveSessionId(
      locationHeader: response.headers.value('location'),
      setCookie: response.headers['set-cookie'],
      finalUrl: response.realUri.toString(),
    );

    if (sessionId == null || sessionId.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Login succeeded but session cookie was missing. Please retry.',
      );
    }

    final Map<String, String> htmlFields = _parseUserFieldsFromHtml(homeBody);

    return AuthSessionModel(
      token: sessionId,
      userId: _nonEmpty(htmlFields['userId']) ?? userId,
      userName: _nonEmpty(htmlFields['userName']) ?? userId,
      emailId: htmlFields['emailId'] ?? '',
      userRoleNameFk: htmlFields['userRoleNameFk'] ?? '',
      userTypeFk: htmlFields['userTypeFk'] ?? '',
      departmentFk: htmlFields['departmentFk'] ?? '',
      designation: htmlFields['designation'] ?? '',
    );
  }

  static bool _okUnder400(int? status) =>
      status != null && status >= 200 && status < 400;

  /// Prefer app-relative path so Dio keeps [baseUrl] (incl. `/wrpmis_qa`).
  String _absoluteOrRelativePath(String location) {
    final String trimmed = location.trim();
    if (trimmed.isEmpty) {
      return ApiConstants.homePath;
    }
    final Uri? uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      final String path = uri.path;
      final String basePath = Uri.parse(Environment.wrBaseUrl).path;
      if (basePath.isNotEmpty &&
          basePath != '/' &&
          path.startsWith(basePath)) {
        final String relative = path.substring(basePath.length);
        return relative.isEmpty ? '/' : relative;
      }
      return path.isEmpty ? ApiConstants.homePath : path;
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
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

  /// Best-effort scrape of user fields from dashboard HTML (often absent).
  Map<String, String> _parseUserFieldsFromHtml(String html) {
    String? read(List<String> names) {
      for (final String name in names) {
        final Match? match = RegExp(
          '''(?:name|id)=["']$name["'][^>]*value=["']([^"']*)["']'''
          '|'
          '''value=["']([^"']*)["'][^>]*(?:name|id)=["']$name["']''',
          caseSensitive: false,
        ).firstMatch(html);
        final String? value = (match?.group(1) ?? match?.group(2))?.trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
      return null;
    }

    final Map<String, String> fields = <String, String>{};
    void put(String key, List<String> names) {
      final String? value = read(names);
      if (value != null) {
        fields[key] = value;
      }
    }

    put('userId', <String>['user_id', 'userId']);
    put('userName', <String>['user_name', 'userName']);
    put('emailId', <String>['email_id', 'emailId', 'email']);
    put('userRoleNameFk', <String>['user_role_name_fk', 'userRoleNameFk']);
    put('userTypeFk', <String>['user_type_fk', 'userTypeFk']);
    put('departmentFk', <String>['department_fk', 'departmentFk', 'department']);
    put('designation', <String>['designation']);
    return fields;
  }

  Future<String?> _resolveSessionId({
    required String? locationHeader,
    required List<String>? setCookie,
    required String finalUrl,
  }) async {
    final String? fromHeaders = _sessionIdFromHeaders(
      locationHeader: locationHeader,
      setCookie: setCookie,
      finalUrl: finalUrl,
    );
    if (fromHeaders != null && fromHeaders.isNotEmpty) {
      return fromHeaders;
    }
    return _sessionIdFromCookieJar();
  }

  String? _sessionIdFromHeaders({
    required String? locationHeader,
    required List<String>? setCookie,
    required String finalUrl,
  }) {
    final RegExp jsessionInUrl = RegExp(
      r'jsessionid=([^;/?#]+)',
      caseSensitive: false,
    );
    for (final String candidate in <String>[
      locationHeader ?? '',
      finalUrl,
    ]) {
      final Match? urlMatch = jsessionInUrl.firstMatch(candidate);
      if (urlMatch != null) {
        return urlMatch.group(1);
      }
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

  Future<String?> _sessionIdFromCookieJar() async {
    try {
      final List<Cookie> cookies = await _cookieManager.cookieJar.loadForRequest(
        Uri.parse(Environment.wrBaseUrl),
      );
      for (final Cookie cookie in cookies) {
        if (cookie.name.toLowerCase() == 'jsessionid' &&
            cookie.value.trim().isNotEmpty) {
          return cookie.value.trim();
        }
      }
    } catch (_) {}
    return null;
  }

  String? _nonEmpty(String? value) {
    final String text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    ref.watch(dioProvider),
    ref.watch(sessionCookieManagerProvider).requireValue,
  );
});
