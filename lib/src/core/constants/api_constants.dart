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
  /// Doc v1 paths (may 404 on QA until backend ships them).
  static const String structuresFormDataPath =
      '/api/v1/structures/add-form-data';
  static const String structuresPath = '/api/v1/structures';

  /// Web Structure list (DataTables JSON). Same source as Update Forms → Structure.
  static const String structuresListPath = '/ajax/getStructureList';
  static const String structuresProjectFilterPath =
      '/ajax/getProjectsListFilterInStructure';
  static const String structuresTypeFilterPath =
      '/ajax/getStructureTypeListForFilter';

  /// Web Structure Form list (Update Forms → Works → Update Structure).
  static const String structureFormListPath = '/ajax/getStructuresList';
  static const String structureFormContractsFilterPath =
      '/ajax/getContractsFilterListInStructure';
  static const String structureFormWorkStatusFilterPath =
      '/ajax/getWorkStatusListInStructure';

  /// Structure Form edit (pencil on Structure Form list).
  static const String structureFormGetPath = '/get-structure-form';
  static const String structureFormUpdatePath = '/update-structure-form';
  static const String structureFormContractsByProjectPath =
      '/ajax/getContractsListForStructureFrom';
  static const String structureFormResponsibleExecutivesPath =
      '/ajax/getResponsibleExecutives';

  /// P6 Data History (Update Forms → Execution & Monitoring → Structure P6 Updates).
  static const String p6ContractsFilterPath =
      '/ajax/getContractsListFilterInP6New';
  static const String p6UploadTypesFilterPath =
      '/ajax/getUploadTypesFilterInP6New';
  static const String p6StatusFilterPath = '/ajax/getStatusListFilterInP6New';
  static const String p6NewActivityDataPath = '/ajax/getP6NewActivityData';

  /// Web Add/Update Structure HTML forms (working on QA).
  static const String structuresAddFormPath = '/add-structure-form';
  static const String structuresGetPath = '/get-structure';
  static const String structuresAddPath = '/add-structure';
  static const String structuresUpdatePath = '/update-structure';

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
