import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/design_drawing_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

class DesignDrawingApiDataSource {
  const DesignDrawingApiDataSource(this._dio);

  final Dio _dio;

  Future<List<DropdownOption>> fetchContractFilter(
    DesignDrawingFilterQuery query,
  ) {
    return _mapFilter(
      path: ApiConstants.designContractFilterPath,
      params: query.filterParams,
      idKeys: const <String>['contract_id_fk', 'contract_id'],
      nameKeys: const <String>['contract_short_name', 'contract_name'],
      prefixIdInName: true,
    );
  }

  Future<List<DropdownOption>> fetchStructureTypeFilter(
    DesignDrawingFilterQuery query,
  ) {
    return _mapFilter(
      path: ApiConstants.designStructureTypeFilterPath,
      params: query.filterParams,
      idKeys: const <String>['structure_type_fk'],
      nameKeys: const <String>['structure_type_fk'],
    );
  }

  Future<List<DropdownOption>> fetchDrawingTypeFilter(
    DesignDrawingFilterQuery query,
  ) {
    return _mapFilter(
      path: ApiConstants.designDrawingTypeFilterPath,
      params: query.filterParams,
      idKeys: const <String>['drawing_type_fk'],
      nameKeys: const <String>['drawing_type_fk'],
    );
  }

  Future<DesignDrawingListResult> fetchDesigns(
    DesignDrawingFilterQuery query,
  ) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.designsListPath,
      queryParameters: query.listParams,
      options: _ajaxGetOptions,
    );
    final Map<String, dynamic> map = _asMap(_decodeJson(response.data));
    final List<DesignDrawingItem> items = _asList(
      map['aaData'] ?? map['data'],
    ).map(DesignDrawingItem.fromJson).where((e) => e.isValid).toList();
    final int total =
        int.tryParse('${map['iTotalRecords'] ?? items.length}') ?? items.length;
    final int filtered =
        int.tryParse('${map['iTotalDisplayRecords'] ?? total}') ?? total;
    return DesignDrawingListResult(
      items: items,
      totalRecords: total,
      filteredRecords: filtered,
    );
  }

  Future<List<DesignUploadItem>> fetchUploads() async {
    final response = await _dio.post<dynamic>(
      ApiConstants.designUploadsListPath,
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
    return _asList(_decodeJson(response.data))
        .map(DesignUploadItem.fromJson)
        .toList();
  }

  Future<List<DropdownOption>> _mapFilter({
    required String path,
    required Map<String, dynamic> params,
    required List<String> idKeys,
    required List<String> nameKeys,
    bool prefixIdInName = false,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: params,
      options: _ajaxGetOptions,
    );
    final List<DropdownOption> options = <DropdownOption>[];
    final Set<String> seen = <String>{};
    for (final Map<String, dynamic> row in _asList(_decodeJson(response.data))) {
      final String id = _first(row, idKeys);
      if (id.isEmpty || !seen.add(id)) {
        continue;
      }
      final String name = _first(row, nameKeys);
      final String label = name.isEmpty
          ? id
          : (prefixIdInName ? '$id - $name' : name);
      options.add(DropdownOption(id: id, name: label));
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

  List<Map<String, dynamic>> _asList(dynamic data) {
    final dynamic decoded = _decodeJson(data);
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
          return _asList(map[key]);
        }
      }
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

final designDrawingApiDataSourceProvider =
    Provider<DesignDrawingApiDataSource>((ref) {
  return DesignDrawingApiDataSource(ref.watch(dioProvider));
});
