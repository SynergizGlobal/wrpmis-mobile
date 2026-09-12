class ApiConstants {
  const ApiConstants._();

  // ── Auth ──────────────────────────────────────────────────────────────
  static const String loginPath = '/login';
  /// API-007 JSON login (preferred for mobile).
  static const String apiLoginPath = '/api/v1/login';
  static const String logoutPath = '/logout';
  static const String homePath = '/home';
  static const String forgotSendOtpPath = '/api/forgot/send-otp';
  static const String forgotVerifyOtpPath = '/api/forgot/verify-otp';
  static const String forgotResetPasswordPath = '/api/forgot/reset-password';

  // ── Projects ──────────────────────────────────────────────────────────
  static const String projectsListPath = '/api/v1/projects/list';
  static const String projectsFormDataPath = '/api/v1/projects/add-form-data';
  static const String projectsPath = '/api/v1/projects';
  static const String projectsExportPath = '/api/v1/projects/export';
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

  /// P6 New Data uploads (multipart).
  static const String p6UploadBaselinePath = '/api/v1/p6/upload-baseline';
  static const String p6RevisedActivitiesPath = '/api/v1/p6/revised-activities';
  static const String p6UpdateActivitiesPath = '/api/v1/p6/update-activities';

  /// Static template files (same as web "Click here for the file format").
  static const String p6BaselineTemplateFile = 'P6BaselineFile.xlsx';
  static const String p6RevisedTemplateFile = 'P6RevisedFile.xlsx';
  static const String p6UpdateTemplateFile = 'P6UpdateFile.xlsx';

  /// New Activities Update (Execution & Monitoring).
  static const String newActivitiesContractsPath =
      '/ajax/getNewActivitiesUpdateContractsList';
  static const String newActivitiesStructureTypesPath =
      '/ajax/getStructureTypesInActivitiesUpdate';
  static const String newActivitiesStructuresPath =
      '/ajax/getNewActivitiesUpdateStructures';
  static const String newActivitiesComponentsPath =
      '/ajax/getNewActivitiesUpdateComponentsList';
  static const String newActivitiesElementsPath =
      '/ajax/getNewActivitiesUpdateComponentIdsList';
  static const String newActivitiesFiltersPath =
      '/ajax/getNewActivitiesfiltersList';
  static const String newActivitiesLatestRowPath = '/ajax/getLatestRowData';
  static const String newActivitiesBindDataPath = '/ajax/bindData';

  /// Modify Actuals (Execution & Monitoring) — structures by contract.
  static const String contractStructuresPath = '/ajax/getContractStructures';

  /// Contracts / Tenders list + form.
  static const String contractsListPath = '/ajax/getContracts';
  static const String contractHodFilterPath =
      '/ajax/getDesignationsFilterListInContract';
  static const String contractDyHodFilterPath =
      '/ajax/getDyHODDesignationsFilterListInContract';
  static const String contractContractorFilterPath =
      '/ajax/getContractorsFilterListInContract';
  static const String contractStatusFilterPath =
      '/ajax/getContractStatusFilterListInContract';
  static const String contractWorkStatusFilterPath =
      '/ajax/getStatusFilterListInContract';
  static const String contractHodListPath = '/ajax/getHodList';
  static const String contractDyHodListPath = '/ajax/getDyHodList';
  static const String contractExecutivesPath =
      '/ajax/getExecutivesListForContractForm';
  static const String contractFormWorkStatusPath =
      '/ajax/getContractStatusLIstFormContractFom';
  static const String contractAddFormPath = '/add-contract-form';
  static const String contractGetPath = '/get-contract';

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
