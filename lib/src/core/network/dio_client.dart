import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:wr_pmis_mobile/src/app/config/app_config_provider.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/auth_interceptor.dart';
import 'package:wr_pmis_mobile/src/core/network/session_cookie_manager.dart';
import 'package:wr_pmis_mobile/src/core/network/session_cookie_protection_interceptor.dart';
import 'package:wr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:wr_pmis_mobile/src/features/auth/presentation/providers/auth_token_provider.dart';

final sessionCookieManagerProvider =
    FutureProvider<SessionCookieManager>((ref) {
  return SessionCookieManager.create();
});

/// Session-cookie Dio client.
///
/// Requires [sessionCookieManagerProvider] to be ready (bootstrapped at app
/// start) so requests never go out without the cookie jar attached.
final dioProvider = Provider<Dio>((ref) {
  final appConfig = ref.watch(appConfigProvider);
  final SessionCookieManager sessionCookieManager =
      ref.watch(sessionCookieManagerProvider).requireValue;

  final dio = Dio(
    BaseOptions(
      baseUrl: appConfig.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.connectTimeout,
      responseType: ResponseType.json,
      headers: const <String, String>{'Accept': '*/*'},
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        maxWidth: 120,
      ),
    );
  }

  dio.interceptors.add(
    AuthInterceptor(() => ref.read(authTokenProvider)),
  );

  // CookieManager saves Set-Cookie on response. Protection runs *before* it
  // (added after → first on response) and strips anonymous JSESSIONID updates.
  dio.interceptors.add(sessionCookieManager.asInterceptor());
  dio.interceptors.add(const SessionCookieProtectionInterceptor());

  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) {
        handler.next(
          error.copyWith(
            message: userFriendlyErrorMessage(error),
          ),
        );
      },
    ),
  );

  return dio;
});
