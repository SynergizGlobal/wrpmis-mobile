import 'package:dio/dio.dart';

/// Prevents Tomcat/anonymous `Set-Cookie: JSESSIONID=…` from overwriting a
/// real login session.
///
/// QA endpoints like `/ajax/getStructureList` return HTTP 200 with totals but
/// **no `aaData`** when unauthenticated, and also issue a fresh JSESSIONID.
/// Dio's [CookieManager] would save that cookie and wipe the logged-in session,
/// leaving lists empty until the next manual login.
///
/// Only `/login` (and explicit `allowSetCookie`) may update session cookies.
class SessionCookieProtectionInterceptor extends Interceptor {
  const SessionCookieProtectionInterceptor();

  static bool _allowsSetCookie(RequestOptions options) {
    if (options.extra['allowSetCookie'] == true) {
      return true;
    }
    if (options.extra['skipAuth'] == true) {
      // Login / forgot-password flows may establish a session.
      final String path = options.path.toLowerCase();
      return path.contains('/login') ||
          path.contains('/forgot') ||
          path.contains('/logout');
    }
    return false;
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!_allowsSetCookie(response.requestOptions)) {
      response.headers.removeAll('set-cookie');
    }
    handler.next(response);
  }
}
