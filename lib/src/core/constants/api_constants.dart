class ApiConstants {
  const ApiConstants._();

  // ── Auth ──────────────────────────────────────────────────────────────
  static const String loginPath = '/login';
  static const String logoutPath = '/logout';
  static const String homePath = '/home';
  static const String forgotSendOtpPath = '/api/forgot/send-otp';
  static const String forgotVerifyOtpPath = '/api/forgot/verify-otp';
  static const String forgotResetPasswordPath = '/api/forgot/reset-password';

  // ── Projects ──────────────────────────────────────────────────────────
  static const String projectsListPath = '/api/v1/projects/list';
  static const String projectsFormDataPath = '/api/v1/projects/add-form-data';
  static const String projectsPath = '/api/v1/projects';
  // GET /api/v1/projects/{project_id} — single project by ID

  // ── Structures (Works) ────────────────────────────────────────────────
  static const String structuresFormDataPath =
      '/api/v1/structures/add-form-data';
  static const String structuresPath = '/api/v1/structures';
  // GET /api/v1/structures/{structure_id} — single structure by ID

  /// Web Structure list (DataTables JSON). Same source as Update Forms → Structure.
  static const String structuresListPath = '/ajax/getStructureList';
  static const String structuresProjectFilterPath =
      '/ajax/getProjectsListFilterInStructure';

  // ── Legacy (unused) ───────────────────────────────────────────────────
  static const String projectTypesPath = '/projects/api/projectTypes';
  static const String projectListPath = '/projects/api/getProjectList';
  static const String projectListByTypePath =
      '/projects/api/getProjectListByType';
  static const String updateFormsPath = '/forms/api/getUpdateForms';

  // Keep old alias for existing callers until migrated.
  static const String projectsApiPath = projectsListPath;

  // ── Timeouts ──────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 45);
}
