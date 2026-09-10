import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/new_activity_row.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/p6_data_history_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_form_edit_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_form_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_list_item.dart';

/// Handles all `/api/v1/projects` and `/api/v1/structures` endpoints.
class ProjectApiDataSource {
  const ProjectApiDataSource(this._dio);

  final Dio _dio;

  // ── Projects ────────────────────────────────────────────────────────

  /// GET /api/v1/projects/list
  Future<List<Map<String, dynamic>>> fetchProjectsList() async {
    final response = await _dio.get<dynamic>(ApiConstants.projectsListPath);
    return _asList(response.data);
  }

  /// GET /api/v1/projects/add-form-data
  Future<Map<String, dynamic>> fetchProjectFormData() async {
    final response = await _dio.get<dynamic>(ApiConstants.projectsFormDataPath);
    return _asMap(response.data);
  }

  /// GET /api/v1/projects/{project_id}
  Future<Map<String, dynamic>> fetchProjectById(String projectId) async {
    final response = await _dio.get<dynamic>(
      '${ApiConstants.projectsPath}/$projectId',
    );
    return _asMap(response.data);
  }

  /// GET /api/v1/projects/export — JSON `{ projects, projectPinkBook }`.
  Future<Map<String, dynamic>> fetchProjectsExport() async {
    final response = await _dio.get<dynamic>(
      ApiConstants.projectsExportPath,
      options: Options(
        responseType: ResponseType.json,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    final int status = response.statusCode ?? 0;
    if (status == 401 || status == 403) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Session expired. Please sign in again.',
      );
    }
    if (status == 404) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'No project data available to export.',
      );
    }
    if (status != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Unable to export projects (HTTP $status).',
      );
    }
    return _asMap(response.data);
  }

  /// POST /api/v1/projects
  Future<String> addProject(Map<String, dynamic> payload) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.projectsPath,
      data: payload,
      options: Options(contentType: Headers.jsonContentType),
    );
    final data = _asMap(response.data);
    return data['message']?.toString() ?? 'Project added.';
  }

  /// PUT /api/v1/projects
  Future<String> updateProject(Map<String, dynamic> payload) async {
    final response = await _dio.put<dynamic>(
      ApiConstants.projectsPath,
      data: payload,
      options: Options(contentType: Headers.jsonContentType),
    );
    final data = _asMap(response.data);
    return data['message']?.toString() ?? 'Project updated.';
  }

  // ── Structures ──────────────────────────────────────────────────────

  /// Projects + structure types for the Add/Update Structure form.
  /// Uses working web AJAX endpoints (v1 form-data is 404 on QA).
  Future<Map<String, dynamic>> fetchStructureFormData() async {
    final List<Map<String, dynamic>> projects =
        await fetchStructureProjectFilter();
    final List<Map<String, dynamic>> types = await fetchStructureTypeFilter();
    return <String, dynamic>{
      'projectsList': projects,
      'structuresList': types,
    };
  }

  /// POST /ajax/getStructureTypeListForFilter
  Future<List<Map<String, dynamic>>> fetchStructureTypeFilter({
    String? projectId,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.structuresTypeFilterPath,
      data: <String, dynamic>{
        'project_id_fk': projectId ?? '',
        'structure_type_fk': '',
      },
      options: Options(
        responseType: ResponseType.plain,
        contentType: Headers.formUrlEncodedContentType,
        headers: const <String, String>{
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
        },
      ),
    );
    return _asList(_decodeJson(response.data));
  }

  /// POST /get-structure — returns Update Structure HTML; parsed into groups.
  Future<StructureDetail> fetchStructureById(String structureId) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.structuresGetPath,
      data: <String, dynamic>{'structure_id': structureId},
      options: Options(
        responseType: ResponseType.plain,
        contentType: Headers.formUrlEncodedContentType,
        headers: const <String, String>{
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'text/html, */*; q=0.01',
        },
      ),
    );
    final String html = (response.data ?? '').toString();
    return _parseStructureEditHtml(html, structureId);
  }

  /// POST /add-structure (form-urlencoded, same fields as web).
  Future<String> addStructures(Map<String, dynamic> payload) async {
    await _dio.post<dynamic>(
      ApiConstants.structuresAddPath,
      data: payload,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        listFormat: ListFormat.multi,
        followRedirects: false,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
    return 'Structure added.';
  }

  /// POST /update-structure (form-urlencoded, same fields as web).
  Future<String> updateStructures(Map<String, dynamic> payload) async {
    await _dio.post<dynamic>(
      ApiConstants.structuresUpdatePath,
      data: payload,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        listFormat: ListFormat.multi,
        followRedirects: false,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
    return 'Structure updated.';
  }

  /// GET /ajax/getStructureList — same DataTables JSON the web Structure page uses.
  Future<StructureListResult> fetchStructureList({
    String? projectId,
    String search = '',
    int start = 0,
    int length = 10,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.structuresListPath,
      queryParameters: <String, dynamic>{
        'project_id_fk': projectId ?? '',
        'sEcho': 1,
        'iDisplayStart': start,
        'iDisplayLength': length,
        'sSearch': search,
      },
      options: Options(
        responseType: ResponseType.plain,
        headers: const <String, String>{
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
        },
      ),
    );
    final Map<String, dynamic> map = _asMap(_decodeJson(response.data));
    final bool hasRowPayload =
        map.containsKey('aaData') || map.containsKey('data');
    final List<Map<String, dynamic>> rows = _asList(
      map['aaData'] ?? map['data'],
    );
    final int total = int.tryParse('${map['iTotalRecords'] ?? rows.length}') ??
        rows.length;
    final int filtered =
        int.tryParse('${map['iTotalDisplayRecords'] ?? total}') ?? total;

    // Unauthenticated Tomcat session: totals present, aaData omitted, and a
    // fresh JSESSIONID would have been issued (now blocked by interceptor).
    if (!hasRowPayload && (total > 0 || filtered > 0)) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Session expired. Please sign in again.',
      );
    }
    if (start == 0 && rows.isEmpty && (total > 0 || filtered > 0)) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Session expired. Please sign in again.',
      );
    }

    return StructureListResult(
      items: rows.map(StructureListItem.fromJson).toList(),
      totalRecords: total,
      filteredRecords: filtered,
    );
  }

  /// POST /ajax/getProjectsListFilterInStructure
  Future<List<Map<String, dynamic>>> fetchStructureProjectFilter({
    String? projectId,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.structuresProjectFilterPath,
      data: <String, dynamic>{'project_id_fk': projectId ?? ''},
      options: Options(
        responseType: ResponseType.plain,
        contentType: Headers.formUrlEncodedContentType,
        headers: const <String, String>{
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
        },
      ),
    );
    return _asList(_decodeJson(response.data));
  }

  // ── Structure Form (Update Structure) ───────────────────────────────

  /// GET /ajax/getStructuresList — Structure Form DataTables JSON.
  Future<StructureFormListResult> fetchStructureFormList({
    String? contractId,
    String? structureType,
    String? workStatus,
    String search = '',
    int start = 0,
    int length = 10,
    int echo = 1,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.structureFormListPath,
      queryParameters: <String, dynamic>{
        'work_status_fk': workStatus ?? '',
        'contract_id_fk': contractId ?? '',
        'structure_type_fk': structureType ?? '',
        'sEcho': echo,
        'iColumns': 6,
        'sColumns': ',,,,,',
        'iDisplayStart': start,
        'iDisplayLength': length,
        'sSearch': search,
        'bRegex': false,
      },
      options: Options(
        responseType: ResponseType.plain,
        headers: const <String, String>{
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
        },
      ),
    );
    return _parseDataTablesList(
      response: response,
      start: start,
      mapRow: StructureFormListItem.fromJson,
      wrap: (List<StructureFormListItem> items, int total, int filtered) {
        return StructureFormListResult(
          items: items,
          totalRecords: total,
          filteredRecords: filtered,
        );
      },
    );
  }

  /// GET /ajax/getContractsFilterListInStructure
  Future<List<Map<String, dynamic>>> fetchStructureFormContractFilter({
    String? contractId,
    String? workStatus,
    String? structureType,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.structureFormContractsFilterPath,
      queryParameters: <String, dynamic>{
        'contract_id_fk': contractId ?? '',
        'work_status_fk': workStatus ?? '',
        'structure_type_fk': structureType ?? '',
      },
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  /// GET /ajax/getWorkStatusListInStructure
  Future<List<Map<String, dynamic>>> fetchStructureFormWorkStatusFilter({
    String? workStatus,
    String? contractId,
    String? structureType,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.structureFormWorkStatusFilterPath,
      queryParameters: <String, dynamic>{
        'work_status_fk': workStatus ?? '',
        'contract_id_fk': contractId ?? '',
        'structure_type_fk': structureType ?? '',
      },
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  /// GET /ajax/getStructureTypeListForFilter (Structure Form filters).
  Future<List<Map<String, dynamic>>> fetchStructureFormTypeFilter({
    String? contractId,
    String? structureType,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.structuresTypeFilterPath,
      queryParameters: <String, dynamic>{
        'contract_id_fk': contractId ?? '',
        'structure_type_fk': structureType ?? '',
      },
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  /// POST /get-structure-form — Update Structure Form HTML prefill.
  Future<StructureFormEditDetail> fetchStructureFormEdit(
    String structureId,
  ) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.structureFormGetPath,
      data: <String, dynamic>{'structure_id': structureId},
      options: Options(
        responseType: ResponseType.plain,
        contentType: Headers.formUrlEncodedContentType,
        headers: const <String, String>{
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'text/html, */*; q=0.01',
        },
      ),
    );
    return _parseStructureFormEditHtml(
      (response.data ?? '').toString(),
      structureId,
    );
  }

  /// POST /update-structure-form (multipart, same as web).
  Future<String> updateStructureForm(FormData formData) async {
    await _dio.post<dynamic>(
      ApiConstants.structureFormUpdatePath,
      data: formData,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
        followRedirects: false,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
    return 'Structure form updated.';
  }

  /// GET /ajax/getContractsListForStructureFrom?project_id_fk=
  Future<List<Map<String, dynamic>>> fetchContractsForStructureForm({
    required String projectId,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.structureFormContractsByProjectPath,
      queryParameters: <String, dynamic>{'project_id_fk': projectId},
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  /// GET /ajax/getResponsibleExecutives?contract_id_fk=
  Future<List<Map<String, dynamic>>> fetchResponsibleExecutives({
    required String contractId,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.structureFormResponsibleExecutivesPath,
      queryParameters: <String, dynamic>{'contract_id_fk': contractId},
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  // ── P6 Data History (Structure P6 Updates) ──────────────────────────

  /// Shared filter query params for P6 New filter endpoints.
  Map<String, dynamic> _p6FilterQuery({
    String? contractId,
    String? uploadType,
    String? statusFk,
  }) {
    return <String, dynamic>{
      'contract_id': contractId ?? '',
      'upload_type': uploadType ?? '',
      'status_fk': statusFk ?? '',
    };
  }

  /// GET /ajax/getContractsListFilterInP6New
  Future<List<Map<String, dynamic>>> fetchP6ContractFilter({
    String? contractId,
    String? uploadType,
    String? statusFk,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.p6ContractsFilterPath,
      queryParameters: _p6FilterQuery(
        contractId: contractId,
        uploadType: uploadType,
        statusFk: statusFk,
      ),
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  /// GET /ajax/getUploadTypesFilterInP6New
  Future<List<Map<String, dynamic>>> fetchP6UploadTypeFilter({
    String? contractId,
    String? uploadType,
    String? statusFk,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.p6UploadTypesFilterPath,
      queryParameters: _p6FilterQuery(
        contractId: contractId,
        uploadType: uploadType,
        statusFk: statusFk,
      ),
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  /// GET /ajax/getStatusListFilterInP6New
  Future<List<Map<String, dynamic>>> fetchP6StatusFilter({
    String? contractId,
    String? uploadType,
    String? statusFk,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.p6StatusFilterPath,
      queryParameters: _p6FilterQuery(
        contractId: contractId,
        uploadType: uploadType,
        statusFk: statusFk,
      ),
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  /// POST /ajax/getP6NewActivityData — may return a raw JSON array or DataTables.
  Future<P6DataHistoryListResult> fetchP6DataHistoryList({
    String? contractId,
    String? uploadType,
    String? statusFk,
    String search = '',
    int start = 0,
    int length = 10,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.p6NewActivityDataPath,
      data: <String, dynamic>{
        'contract_id_fk': contractId ?? '',
        'upload_type': uploadType ?? '',
        'status_fk': statusFk ?? '',
      },
      options: Options(
        responseType: ResponseType.plain,
        contentType: Headers.formUrlEncodedContentType,
        headers: const <String, String>{
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
        },
      ),
    );

    final dynamic decoded = _decodeJson(response.data);
    final List<P6DataHistoryItem> all = _extractP6HistoryRows(decoded)
        .map(P6DataHistoryItem.fromJson)
        .toList();

    final List<P6DataHistoryItem> filtered = search.trim().isEmpty
        ? all
        : all.where((P6DataHistoryItem e) => e.matchesSearch(search)).toList();

    final int total = all.length;
    final int filteredCount = filtered.length;
    final int safeStart = start < 0 ? 0 : start;
    final List<P6DataHistoryItem> page = length <= 0
        ? filtered
        : filtered.skip(safeStart).take(length).toList();

    return P6DataHistoryListResult(
      items: page,
      totalRecords: total,
      filteredRecords: filteredCount,
    );
  }

  /// POST `/api/v1/p6/upload-baseline` | `revised-activities` | `update-activities`
  /// multipart: project_id_fk, contract_id_fk, data_date (dd-mm-yyyy), p6dataFile.
  Future<String> uploadP6Data({
    required String apiPath,
    required String projectId,
    required String contractId,
    required String dataDate,
    required String filePath,
    required String fileName,
  }) async {
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'project_id_fk': projectId,
      'contract_id_fk': contractId,
      'data_date': dataDate,
      'p6dataFile': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    final Response<dynamic> response = await _dio.post<dynamic>(
      apiPath,
      data: formData,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
        responseType: ResponseType.json,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
      ),
    );

    final int status = response.statusCode ?? 0;
    final Map<String, dynamic> map = _asMap(response.data);
    final String message = _stripHtml(
      (map['message'] ?? map['error'] ?? map['status'] ?? '').toString(),
    );

    if (status == 401 || status == 403) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Session expired. Please sign in again.',
      );
    }
    if (status < 200 || status >= 300) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: message.isNotEmpty
            ? message
            : 'Unable to upload P6 data (HTTP $status).',
      );
    }

    final String statusFlag = (map['status'] ?? '').toString().toLowerCase();
    final String errorText = _stripHtml((map['error'] ?? '').toString());
    if (errorText.isNotEmpty && statusFlag != 'success') {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: errorText,
      );
    }

    if (message.isNotEmpty) {
      return message;
    }
    return 'P6 data uploaded successfully.';
  }

  // ── New Activities Update ───────────────────────────────────────────

  /// GET /ajax/getNewActivitiesUpdateContractsList
  Future<List<Map<String, dynamic>>> fetchNewActivitiesContracts() async {
    final response = await _dio.get<dynamic>(
      ApiConstants.newActivitiesContractsPath,
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  /// GET /ajax/getStructureTypesInActivitiesUpdate
  Future<List<Map<String, dynamic>>> fetchNewActivitiesStructureTypes({
    required String contractId,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.newActivitiesStructureTypesPath,
      queryParameters: <String, dynamic>{'contract_id_fk': contractId},
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  /// GET /ajax/getNewActivitiesUpdateStructures
  Future<List<Map<String, dynamic>>> fetchNewActivitiesStructures({
    required String contractId,
    required String structureType,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.newActivitiesStructuresPath,
      queryParameters: <String, dynamic>{
        'contract_id_fk': contractId,
        'structure_type_fk': structureType,
      },
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  /// GET /ajax/getNewActivitiesUpdateComponentsList
  Future<List<Map<String, dynamic>>> fetchNewActivitiesComponents({
    required String contractId,
    required String structureId,
    required String structureType,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.newActivitiesComponentsPath,
      queryParameters: <String, dynamic>{
        'contract_id_fk': contractId,
        'strip_chart_structure_id_fk': structureId,
        'structure_type_fk': structureType,
      },
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  /// GET /ajax/getNewActivitiesUpdateComponentIdsList (Element)
  Future<List<Map<String, dynamic>>> fetchNewActivitiesElements({
    required String contractId,
    required String structureId,
    required String component,
    required String structureType,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.newActivitiesElementsPath,
      queryParameters: <String, dynamic>{
        'contract_id_fk': contractId,
        'strip_chart_structure_id_fk': structureId,
        'strip_chart_component': component,
        'structure_type_fk': structureType,
      },
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  /// GET /ajax/getNewActivitiesfiltersList
  Future<List<NewActivityRow>> fetchNewActivitiesFiltersList({
    required String contractId,
    required String structureId,
    required String component,
    required String structureType,
    String elementId = '',
    String activityId = '',
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.newActivitiesFiltersPath,
      queryParameters: <String, dynamic>{
        'strip_chart_component_id': elementId,
        'strip_chart_activity_id': activityId,
        'strip_chart_structure_id_fk': structureId,
        'contract_id_fk': contractId,
        'strip_chart_component': component,
        'structure_type_fk': structureType,
      },
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data))
        .map(NewActivityRow.fromJson)
        .toList();
  }

  /// GET /ajax/getContractStructures?contract_id_fk=
  Future<List<Map<String, dynamic>>> fetchContractStructures({
    required String contractId,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.contractStructuresPath,
      queryParameters: <String, dynamic>{'contract_id_fk': contractId},
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  /// GET /ajax/getNewActivitiesfiltersList for Modify Actuals
  /// (contract + optional structure + searchStr; no component/type).
  Future<List<NewActivityRow>> fetchModifyActualsFiltersList({
    required String contractId,
    String structureId = '',
    String searchStr = '',
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.newActivitiesFiltersPath,
      queryParameters: <String, dynamic>{
        'contract_id_fk': contractId,
        'strip_chart_structure_id_fk': structureId,
        'searchStr': searchStr,
      },
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data))
        .map(NewActivityRow.fromJson)
        .toList();
  }

  /// GET /ajax/getLatestRowData
  Future<NewActivitiesLatestInfo?> fetchNewActivitiesLatestRow() async {
    final response = await _dio.get<dynamic>(
      ApiConstants.newActivitiesLatestRowPath,
      options: _ajaxGetOptions,
    );
    final List<Map<String, dynamic>> rows =
        _asList(_decodeJson(response.data));
    if (rows.isEmpty) {
      return null;
    }
    return NewActivitiesLatestInfo.fromJson(rows.first);
  }

  /// GET /ajax/bindData?activity_id=
  Future<NewActivitiesLatestInfo?> fetchNewActivitiesBindData(
    String activityId,
  ) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.newActivitiesBindDataPath,
      queryParameters: <String, dynamic>{'activity_id': activityId},
      options: _ajaxGetOptions,
    );
    final List<Map<String, dynamic>> rows =
        _asList(_decodeJson(response.data));
    if (rows.isEmpty) {
      return null;
    }
    return NewActivitiesLatestInfo.fromJson(rows.first);
  }

  String _stripHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  List<Map<String, dynamic>> _extractP6HistoryRows(dynamic decoded) {
    if (decoded is List) {
      return _asList(decoded);
    }
    if (decoded is Map) {
      final Map<String, dynamic> map = _asMap(decoded);
      return _asList(map['aaData'] ?? map['data'] ?? map['result'] ?? map);
    }
    return const <Map<String, dynamic>>[];
  }

  static Options get _ajaxGetOptions => Options(
        responseType: ResponseType.plain,
        headers: const <String, String>{
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
        },
      );

  // ── Helpers ─────────────────────────────────────────────────────────

  StructureFormEditDetail _parseStructureFormEditHtml(
    String html,
    String structureId,
  ) {
    String? inputValue(String name) {
      return _firstMatch(
            html,
            RegExp(
              '''name=["']$name["'][^>]*value=["']([^"']*)["']''',
              caseSensitive: false,
            ),
          ) ??
          _firstMatch(
            html,
            RegExp(
              '''value=["']([^"']*)["'][^>]*name=["']$name["']''',
              caseSensitive: false,
            ),
          );
    }

    List<StructureFormOption> optionsFromSelect(String name) {
      final RegExpMatch? select = RegExp(
        '''<select[^>]*name=["']$name["'][^>]*>([\\s\\S]*?)</select>''',
        caseSensitive: false,
      ).firstMatch(html);
      if (select == null) return const <StructureFormOption>[];
      final List<StructureFormOption> out = <StructureFormOption>[];
      final Set<String> seen = <String>{};
      for (final RegExpMatch m in RegExp(
        r'''<option([^>]*)value=["']([^"']*)["']([^>]*)>([^<]*)''',
        caseSensitive: false,
      ).allMatches(select.group(1)!)) {
        final String id = (m.group(2) ?? '').trim();
        final String label = (m.group(4) ?? '').trim();
        if (id.isEmpty || !seen.add(id)) continue;
        out.add(StructureFormOption(id: id, name: label.isEmpty ? id : label));
      }
      return out;
    }

    String? selectedOption(String name) {
      final RegExpMatch? select = RegExp(
        '''<select[^>]*name=["']$name["'][^>]*>([\\s\\S]*?)</select>''',
        caseSensitive: false,
      ).firstMatch(html);
      if (select == null) return null;
      for (final RegExpMatch m in RegExp(
        r'''<option([^>]*)value=["']([^"']*)["']([^>]*)>([^<]*)''',
        caseSensitive: false,
      ).allMatches(select.group(1)!)) {
        final String attrs = '${m.group(1)}${m.group(3)}'.toLowerCase();
        if (attrs.contains('selected')) {
          return (m.group(2) ?? '').trim();
        }
      }
      return null;
    }

    String? textareaValue(String name) {
      return _firstMatch(
        html,
        RegExp(
          '''<textarea[^>]*name=["']$name["'][^>]*>([\\s\\S]*?)</textarea>''',
          caseSensitive: false,
        ),
      )?.trim();
    }

    final List<String> contractIds = <String>[];
    for (final RegExpMatch m in RegExp(
      r'''<select[^>]*name=["']contracts_id_fk["'][^>]*>([\s\S]*?)</select>''',
      caseSensitive: false,
    ).allMatches(html)) {
      String? selected;
      for (final RegExpMatch o in RegExp(
        r'''<option([^>]*)value=["']([^"']*)["']([^>]*)>''',
        caseSensitive: false,
      ).allMatches(m.group(1)!)) {
        final String attrs = '${o.group(1)}${o.group(3)}'.toLowerCase();
        if (attrs.contains('selected') && (o.group(2) ?? '').trim().isNotEmpty) {
          selected = o.group(2)!.trim();
          break;
        }
      }
      // Skip empty template rows without selection at the end if duplicate empty.
      contractIds.add(selected ?? '');
    }

    final List<List<String>> execRows = <List<String>>[];
    for (final RegExpMatch m in RegExp(
      r'''<select[^>]*name=["']excecutives["'][^>]*>([\s\S]*?)</select>''',
      caseSensitive: false,
    ).allMatches(html)) {
      final List<String> ids = <String>[];
      for (final RegExpMatch o in RegExp(
        r'''<option([^>]*)value=["']([^"']+)["']([^>]*)>''',
        caseSensitive: false,
      ).allMatches(m.group(1)!)) {
        final String attrs = '${o.group(1)}${o.group(3)}'.toLowerCase();
        if (attrs.contains('selected')) {
          ids.add(o.group(2)!.trim());
        }
      }
      execRows.add(ids);
    }

    final List<StructureFormContractRow> contractRows =
        <StructureFormContractRow>[];
    final int rowCount = contractIds.length > execRows.length
        ? contractIds.length
        : execRows.length;
    for (int i = 0; i < rowCount; i++) {
      final String cid = i < contractIds.length ? contractIds[i] : '';
      final List<String> execs =
          i < execRows.length ? execRows[i] : const <String>[];
      if (cid.isEmpty && execs.isEmpty) continue;
      contractRows.add(
        StructureFormContractRow(contractIdFk: cid, executiveIds: execs),
      );
    }
    if (contractRows.isEmpty) {
      contractRows.add(const StructureFormContractRow());
    }

    final List<String> details = RegExp(
      r'''name=["']structure_details["'][^>]*value=["']([^"']*)["']''',
      caseSensitive: false,
    ).allMatches(html).map((RegExpMatch m) => m.group(1) ?? '').toList();
    final List<String> values = RegExp(
      r'''name=["']structure_values["'][^>]*value=["']([^"']*)["']''',
      caseSensitive: false,
    ).allMatches(html).map((RegExpMatch m) => m.group(1) ?? '').toList();
    final List<StructureFormDetailRow> detailRows = <StructureFormDetailRow>[];
    final int detailCount =
        details.length > values.length ? details.length : values.length;
    for (int i = 0; i < detailCount; i++) {
      final String d = i < details.length ? details[i] : '';
      final String v = i < values.length ? values[i] : '';
      if (d.trim().isEmpty && v.trim().isEmpty) continue;
      detailRows.add(StructureFormDetailRow(detail: d, value: v));
    }
    if (detailRows.isEmpty) {
      detailRows.add(const StructureFormDetailRow());
    }

    final List<String> docTypes = <String>[];
    for (final RegExpMatch m in RegExp(
      r'''<select[^>]*name=["']structure_file_types["'][^>]*>([\s\S]*?)</select>''',
      caseSensitive: false,
    ).allMatches(html)) {
      String selected = '';
      for (final RegExpMatch o in RegExp(
        r'''<option([^>]*)value=["']([^"']*)["']([^>]*)>''',
        caseSensitive: false,
      ).allMatches(m.group(1)!)) {
        final String attrs = '${o.group(1)}${o.group(3)}'.toLowerCase();
        if (attrs.contains('selected')) {
          selected = (o.group(2) ?? '').trim();
          break;
        }
      }
      docTypes.add(selected);
    }
    final List<String> docNames = RegExp(
      r'''name=["']structureDocumentNames["'][^>]*value=["']([^"']*)["']''',
      caseSensitive: false,
    ).allMatches(html).map((RegExpMatch m) => m.group(1) ?? '').toList();
    final List<String> docIds = RegExp(
      r'''name=["']structure_file_ids["'][^>]*value=["']([^"']*)["']''',
      caseSensitive: false,
    ).allMatches(html).map((RegExpMatch m) => m.group(1) ?? '').toList();
    final List<String> docFiles = RegExp(
      r'''name=["']structureFileNames["'][^>]*value=["']([^"']*)["']''',
      caseSensitive: false,
    ).allMatches(html).map((RegExpMatch m) => m.group(1) ?? '').toList();

    final List<StructureFormDocumentRow> documentRows =
        <StructureFormDocumentRow>[];
    final int docCount = <int>[
      docTypes.length,
      docNames.length,
      docIds.length,
      docFiles.length,
    ].reduce((int a, int b) => a > b ? a : b);
    for (int i = 0; i < docCount; i++) {
      final String type = i < docTypes.length ? docTypes[i] : '';
      final String name = i < docNames.length ? docNames[i] : '';
      final String id = i < docIds.length ? docIds[i] : '';
      final String file = i < docFiles.length ? docFiles[i] : '';
      if (type.isEmpty && name.isEmpty && id.isEmpty && file.isEmpty) continue;
      documentRows.add(
        StructureFormDocumentRow(
          fileType: type,
          name: name,
          fileId: id,
          existingFileName: file,
        ),
      );
    }
    if (documentRows.isEmpty) {
      documentRows.add(const StructureFormDocumentRow());
    }

    final String? projectId = selectedOption('project_id_fk') ??
        inputValue('project_id_fk');
    final List<StructureFormOption> projects =
        optionsFromSelect('project_id_fk');
    String? projectLabel;
    for (final StructureFormOption o in projects) {
      if (o.id == projectId) {
        projectLabel = o.name;
        break;
      }
    }

    return StructureFormEditDetail(
      structureId: inputValue('structure_id') ?? structureId,
      projectIdFk: projectId,
      projectLabel: projectLabel ?? projectId,
      structureTypeFk: selectedOption('structure_type_fk'),
      structureName: inputValue('structure_name'),
      structure: inputValue('structure'),
      workStatusFk: selectedOption('work_status_fk'),
      existingWorkStatusFk: inputValue('existing_work_status_fk'),
      targetDate: inputValue('target_date'),
      estimatedCost: inputValue('estimated_cost'),
      estimatedCostUnits: selectedOption('estimated_cost_units'),
      remarks: textareaValue('remarks'),
      latitude: inputValue('latitude'),
      longitude: inputValue('longitude'),
      constructionStartDate: inputValue('construction_start_date'),
      revisedCompletion: inputValue('revised_completion'),
      commissioningDate: inputValue('commissioning_date'),
      actualCompletionDate: inputValue('actual_completion_date'),
      completionCost: inputValue('completion_cost'),
      completionCostUnits: selectedOption('completion_cost_units'),
      contractRows: contractRows,
      detailRows: detailRows,
      documentRows: documentRows,
      projects: projects,
      structureTypes: optionsFromSelect('structure_type_fk'),
      workStatuses: optionsFromSelect('work_status_fk'),
    );
  }

  T _parseDataTablesList<T, R>({
    required Response<dynamic> response,
    required int start,
    required R Function(Map<String, dynamic>) mapRow,
    required T Function(List<R> items, int total, int filtered) wrap,
  }) {
    final Map<String, dynamic> map = _asMap(_decodeJson(response.data));
    final bool hasRowPayload =
        map.containsKey('aaData') || map.containsKey('data');
    final List<Map<String, dynamic>> rows = _asList(
      map['aaData'] ?? map['data'],
    );
    final int total = int.tryParse('${map['iTotalRecords'] ?? rows.length}') ??
        rows.length;
    final int filtered =
        int.tryParse('${map['iTotalDisplayRecords'] ?? total}') ?? total;

    if (!hasRowPayload && (total > 0 || filtered > 0)) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Session expired. Please sign in again.',
      );
    }
    if (start == 0 && rows.isEmpty && (total > 0 || filtered > 0)) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Session expired. Please sign in again.',
      );
    }

    return wrap(rows.map(mapRow).toList(), total, filtered);
  }

  StructureDetail _parseStructureEditHtml(String html, String structureId) {
    final String? projectId = _firstMatch(
          html,
          RegExp(
            r'''name=["']project_id_fk["'][^>]*value=["']([^"']*)["']''',
            caseSensitive: false,
          ),
        ) ??
        _firstMatch(
          html,
          RegExp(
            r'''value=["']([^"']*)["'][^>]*name=["']project_id_fk["']''',
            caseSensitive: false,
          ),
        );

    // Edit page shows readonly text like "P05- Dahod - Indore New BG lines".
    final String? projectLabel = _firstMatch(
          html,
          RegExp(
            r'''id=["']project_id_fk["'][^>]*value=["']([^"']*)["']''',
            caseSensitive: false,
          ),
        ) ??
        _firstMatch(
          html,
          RegExp(
            r'''value=["']([^"']*)["'][^>]*id=["']project_id_fk["']''',
            caseSensitive: false,
          ),
        ) ??
        projectId;

    // Web form posts one triple per row in document order:
    // structures → structure_names → structure_type_fks (and optional structure_ids).
    String pendingStructure = '';
    String pendingName = '';
    String pendingId = '';
    final List<({String type, StructureNameRow row})> flat =
        <({String type, StructureNameRow row})>[];

    for (final RegExpMatch m in RegExp(
      r'<input[^>]*>',
      caseSensitive: false,
    ).allMatches(html)) {
      final String tag = m.group(0)!;
      final String? name = _attr(tag, 'name');
      if (name == null) continue;
      final String value = _attr(tag, 'value') ?? '';
      switch (name) {
        case 'structures':
          pendingStructure = value;
        case 'structure_names':
          pendingName = value;
        case 'structure_ids':
          pendingId = value;
        case 'structure_type_fks':
          final String type = value.trim();
          if (type.isEmpty) {
            pendingStructure = '';
            pendingName = '';
            pendingId = '';
            break;
          }
          flat.add(
            (
              type: type,
              row: StructureNameRow(
                structureId: pendingId,
                structure: pendingStructure,
                structureName:
                    pendingName.isEmpty ? pendingStructure : pendingName,
              ),
            ),
          );
          pendingStructure = '';
          pendingName = '';
          pendingId = '';
      }
    }

    final Map<String, List<StructureNameRow>> byType =
        <String, List<StructureNameRow>>{};
    final List<String> typeOrder = <String>[];
    for (final ({String type, StructureNameRow row}) item in flat) {
      if (!byType.containsKey(item.type)) {
        typeOrder.add(item.type);
        byType[item.type] = <StructureNameRow>[];
      }
      byType[item.type]!.add(item.row);
    }

    final List<StructureTypeGroup> groups = typeOrder
        .map(
          (String t) => StructureTypeGroup(
            structureType: t,
            rows: byType[t] ?? const <StructureNameRow>[],
          ),
        )
        .toList();

    return StructureDetail(
      structureId: structureId,
      projectIdFk: projectId,
      projectLabel: projectLabel,
      groups: groups,
    );
  }

  String? _attr(String tag, String name) {
    final RegExpMatch? m = RegExp(
      '''$name=["']([^"']*)["']''',
      caseSensitive: false,
    ).firstMatch(tag);
    return m?.group(1);
  }

  String? _firstMatch(String source, RegExp pattern) {
    return pattern.firstMatch(source)?.group(1);
  }

  dynamic _decodeJson(dynamic data) {
    if (data is String) {
      final String trimmed = data.trim();
      if (trimmed.isEmpty || trimmed == 'null') {
        return null;
      }
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    final dynamic decoded = _decodeJson(data);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }
    if (decoded is Map) {
      final map = _asMap(decoded);
      for (final key in [
        'aaData',
        'data',
        'result',
        'list',
        'projects',
        'content',
      ]) {
        if (map[key] is List) return _asList(map[key]);
      }
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic data) {
    final dynamic decoded = _decodeJson(data);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
    return const {};
  }
}

final projectApiDataSourceProvider = Provider<ProjectApiDataSource>((ref) {
  return ProjectApiDataSource(ref.watch(dioProvider));
});
