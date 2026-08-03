class ApiConstants {
  const ApiConstants._();

  /// Form POST: `user_id`, `password` → 302 `/home` on success.
  static const String loginPath = '/login';
  static const String logoutPath = '/logout';
  static const String homePath = '/home';
  static const String forgotSendOtpPath = '/api/forgot/send-otp';
  static const String forgotVerifyOtpPath = '/api/forgot/verify-otp';
  static const String forgotResetPasswordPath = '/api/forgot/reset-password';

  static const String projectTypesPath = '/projects/api/projectTypes';
  static const String projectListPath = '/projects/api/getProjectList';
  static const String projectListByTypePath =
      '/projects/api/getProjectListByType';
  /// Authenticated projects list for Home (requires JSESSIONID).
  static const String projectsApiPath = '/api/projects';
  static const String updateFormsPath = '/forms/api/getUpdateForms';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 45);
}
