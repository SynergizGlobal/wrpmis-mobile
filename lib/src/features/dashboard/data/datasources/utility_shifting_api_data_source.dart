import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/project_page_parser.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/utility_shifting_item.dart';

class UtilityShiftingApiDataSource {
  const UtilityShiftingApiDataSource(this._dio);

  final Dio _dio;

  Future<List<DropdownOption>> fetchLocationFilter(
    UtilityShiftingFilterQuery query,
  ) {
    return _mapFilter(
      path: ApiConstants.utilityLocationFilterPath,
      params: query.filterParams,
      keys: const <String>['location_name'],
    );
  }

  Future<List<DropdownOption>> fetchCategoryFilter(
    UtilityShiftingFilterQuery query,
  ) {
    return _mapFilter(
      path: ApiConstants.utilityCategoryFilterPath,
      params: query.filterParams,
      keys: const <String>['utility_category_fk'],
    );
  }

  Future<List<DropdownOption>> fetchTypeFilter(
    UtilityShiftingFilterQuery query,
  ) {
    return _mapFilter(
      path: ApiConstants.utilityTypeFilterPath,
      params: query.filterParams,
      keys: const <String>['utility_type_fk'],
    );
  }

  Future<List<DropdownOption>> fetchStatusFilter(
    UtilityShiftingFilterQuery query,
  ) {
    return _mapFilter(
      path: ApiConstants.utilityStatusFilterPath,
      params: query.filterParams,
      keys: const <String>['shifting_status_fk'],
    );
  }

  Future<UtilityShiftingListResult> fetchList(
    UtilityShiftingFilterQuery query,
  ) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.utilityShiftingListPath,
      queryParameters: query.listParams,
      options: _ajaxGetOptions,
    );
    final Map<String, dynamic> map = _asMap(_decodeJson(response.data));
    final List<UtilityShiftingItem> items = _asRows(map['aaData'] ?? map)
        .map(UtilityShiftingItem.fromJson)
        .where((UtilityShiftingItem e) => e.isValid)
        .toList();
    final int total = int.tryParse('${map['iTotalRecords'] ?? items.length}') ??
        items.length;
    final int filtered =
        int.tryParse('${map['iTotalDisplayRecords'] ?? total}') ?? total;
    return UtilityShiftingListResult(
      items: items,
      totalRecords: total,
      filteredRecords: filtered,
    );
  }

  Future<List<UtilityUploadItem>> fetchUploads() async {
    final response = await _dio.post<dynamic>(
      ApiConstants.utilityShiftingUploadsPath,
      data: const <String, dynamic>{},
      options: Options(
        responseType: ResponseType.plain,
        contentType: Headers.formUrlEncodedContentType,
        headers: const <String, String>{
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
        },
      ),
    );
    return _asRows(_decodeJson(response.data))
        .map(UtilityUploadItem.fromJson)
        .where(
          (UtilityUploadItem e) =>
              (e.uploadedFile ?? '').isNotEmpty ||
              (e.utilityDataId ?? '').isNotEmpty,
        )
        .toList();
  }

  Future<List<DropdownOption>> fetchImpactedContracts(String projectId) {
    return _namedOptions(
      path: ApiConstants.utilityImpactedContractsPath,
      params: <String, dynamic>{'project_id_fk': projectId},
      idKeys: const <String>['contract_id_fk', 'contract_id'],
      nameKeys: const <String>['contract_short_name', 'contract_name'],
      prefixId: true,
    );
  }

  Future<List<DropdownOption>> fetchRequirementStages(String contractId) {
    return _namedOptions(
      path: ApiConstants.utilityRequirementStagePath,
      params: <String, dynamic>{'impacted_contract_id_fk': contractId},
      idKeys: const <String>['requirement_stage_fk'],
      nameKeys: const <String>['requirement_stage_fk'],
    );
  }

  Future<List<DropdownOption>> fetchImpactedElements({
    required String contractId,
    required String stage,
  }) {
    return _namedOptions(
      path: ApiConstants.utilityImpactedElementPath,
      params: <String, dynamic>{
        'impacted_contract_id_fk': contractId,
        'requirement_stage_fk': stage,
      },
      idKeys: const <String>['impacted_element'],
      nameKeys: const <String>['impacted_element'],
    );
  }

  Future<Map<String, List<DropdownOption>>> fetchAddFormOptions() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.utilityAddFormPath,
      options: Options(
        responseType: ResponseType.plain,
        headers: const <String, String>{
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'text/html,application/json, */*; q=0.01',
        },
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
    final String body = response.data?.toString() ?? '';
    final Map<String, List<DropdownOption>> parsed = _parseSelects(body);
    if ((parsed['project_id_fk'] ?? const <DropdownOption>[]).isEmpty) {
      parsed['project_id_fk'] = await _projectsFromPage();
    }
    if ((parsed['utility_type_fk'] ?? const <DropdownOption>[]).isEmpty) {
      parsed['utility_type_fk'] = await fetchTypeFilter(
        const UtilityShiftingFilterQuery(),
      );
    }
    if ((parsed['shifting_status_fk'] ?? const <DropdownOption>[]).isEmpty) {
      parsed['shifting_status_fk'] = await fetchStatusFilter(
        const UtilityShiftingFilterQuery(),
      );
    }
    return parsed;
  }

  Future<UtilityShiftingItem?> fetchDetail({
    required String id,
    required String utilityShiftingId,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.utilityGetPath,
      queryParameters: <String, dynamic>{
        'id': id,
        'utility_shifting_id': utilityShiftingId,
      },
      options: Options(
        responseType: ResponseType.plain,
        headers: const <String, String>{
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json, text/html, */*; q=0.01',
        },
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
    final dynamic decoded = _decodeJson(response.data);
    if (decoded is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
      final UtilityShiftingItem item = UtilityShiftingItem.fromJson(map);
      if (item.isValid &&
          (item.utilityShiftingId != null || item.description != null)) {
        return item;
      }
    }
    if (decoded is String || response.data is String) {
      final String html = response.data.toString();
      if (html.toLowerCase().contains('<title>login</title>')) {
        return null;
      }
    }
    return null;
  }

  Future<String> save(Map<String, dynamic> fields) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.utilityAddFormPath,
      data: fields,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
        headers: const <String, String>{
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json, text/html, */*; q=0.01',
        },
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    final int status = response.statusCode ?? 0;
    final String body = response.data?.toString() ?? '';
    if (body.toLowerCase().contains('<title>login</title>') ||
        status == 401 ||
        status == 403) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Session expired. Please sign in again.',
      );
    }
    if (status >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Unable to save utility shifting.',
      );
    }
    final dynamic decoded = _decodeJson(body);
    if (decoded is Map) {
      final String message =
          (decoded['message'] ?? decoded['remarks'] ?? '').toString().trim();
      if (message.isNotEmpty && message.toLowerCase() != 'null') {
        return message;
      }
    }
    return 'Saved.';
  }

  Future<List<DropdownOption>> _projectsFromPage() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.projectsPagePath,
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    if (response.statusCode != 200) {
      return const <DropdownOption>[];
    }
    return ProjectPageParser.parse(response.data?.toString() ?? '')
        .map((Map<String, dynamic> row) {
          final String id = (row['project_id'] ?? '').toString();
          final String name = (row['project_name'] ?? id).toString();
          return DropdownOption(
            id: id,
            name: name.isEmpty || name == id ? id : '$id - $name',
          );
        })
        .where((DropdownOption e) => e.id.isNotEmpty)
        .toList();
  }

  Future<List<DropdownOption>> _namedOptions({
    required String path,
    required Map<String, dynamic> params,
    required List<String> idKeys,
    required List<String> nameKeys,
    bool prefixId = false,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: params,
      options: _ajaxGetOptions,
    );
    final List<DropdownOption> options = <DropdownOption>[];
    final Set<String> seen = <String>{};
    for (final Map<String, dynamic> row in _asRows(_decodeJson(response.data))) {
      final String id = _first(row, idKeys);
      if (id.isEmpty || !seen.add(id)) {
        continue;
      }
      final String name = _first(row, nameKeys);
      final String label = name.isEmpty
          ? id
          : (prefixId && name != id ? '$id - $name' : name);
      options.add(DropdownOption(id: id, name: label));
    }
    return options;
  }

  Map<String, List<DropdownOption>> _parseSelects(String html) {
    final Map<String, List<DropdownOption>> result =
        <String, List<DropdownOption>>{};
    if (!html.toLowerCase().contains('<select')) {
      return result;
    }
    final RegExp selectRe = RegExp(
      '''<select[^>]*name=["']([^"']+)["'][^>]*>([\\s\\S]*?)</select>''',
      caseSensitive: false,
    );
    final RegExp optionRe = RegExp(
      '''<option([^>]*)>([\\s\\S]*?)</option>''',
      caseSensitive: false,
    );
    for (final RegExpMatch select in selectRe.allMatches(html)) {
      final String name = select.group(1) ?? '';
      final List<DropdownOption> options = <DropdownOption>[];
      final Set<String> seen = <String>{};
      for (final RegExpMatch option in optionRe.allMatches(select.group(2) ?? '')) {
        final String attrs = option.group(1) ?? '';
        final String text = option
            .group(2)!
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        final RegExpMatch? valueMatch =
            RegExp('''value=["']([^"']*)["']''', caseSensitive: false)
                .firstMatch(attrs);
        final String value = (valueMatch?.group(1) ?? text).trim();
        if (value.isEmpty ||
            value.toLowerCase() == 'select' ||
            text.toLowerCase() == 'select' ||
            !seen.add(value)) {
          continue;
        }
        options.add(DropdownOption(id: value, name: text.isEmpty ? value : text));
      }
      if (options.isNotEmpty) {
        result[name] = options;
      }
    }
    return result;
  }

  Future<List<DropdownOption>> _mapFilter({
    required String path,
    required Map<String, dynamic> params,
    required List<String> keys,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: params,
      options: _ajaxGetOptions,
    );
    final List<DropdownOption> options = <DropdownOption>[];
    final Set<String> seen = <String>{};
    for (final Map<String, dynamic> row in _asRows(_decodeJson(response.data))) {
      final String value = _first(row, keys);
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      options.add(DropdownOption(id: value, name: value));
    }
    return options;
  }

  String _first(Map<String, dynamic> row, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = row[key];
      if (value == null) {
        continue;
      }
      final String text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  dynamic _decodeJson(dynamic data) {
    if (data is String) {
      final String trimmed = data.trim();
      if (trimmed.isEmpty || trimmed == 'null') {
        return <dynamic>[];
      }
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return trimmed;
      }
    }
    return data;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asRows(dynamic data) {
    final dynamic decoded = data is String ? _decodeJson(data) : data;
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((Map e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (decoded is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
      for (final String key in <String>['aaData', 'data', 'result', 'list']) {
        if (map[key] is List) {
          return _asRows(map[key]);
        }
      }
      return <Map<String, dynamic>>[map];
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
}

final utilityShiftingApiDataSourceProvider =
    Provider<UtilityShiftingApiDataSource>((ref) {
  return UtilityShiftingApiDataSource(ref.watch(dioProvider));
});
