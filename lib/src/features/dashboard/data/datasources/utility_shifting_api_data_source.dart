import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';
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
      return jsonDecode(trimmed);
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
