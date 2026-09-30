import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/validate_activity_item.dart';

class ValidateDataApiDataSource {
  const ValidateDataApiDataSource(this._dio);

  final Dio _dio;

  Future<List<DropdownOption>> fetchContracts(ValidateDataQuery query) {
    return _options(
      ApiConstants.validateContractsPath,
      query,
      idKeys: const <String>['contract_id_fk'],
      nameKeys: const <String>['contract_short_name', 'contract_name'],
      prefixId: true,
    );
  }

  Future<List<DropdownOption>> fetchStructures(ValidateDataQuery query) {
    return _options(
      ApiConstants.validateStructuresPath,
      query,
      idKeys: const <String>['structure'],
      nameKeys: const <String>['structure'],
    );
  }

  Future<List<DropdownOption>> fetchUpdatedBy(ValidateDataQuery query) {
    return _options(
      ApiConstants.validateUpdatedByPath,
      query,
      idKeys: const <String>['user_id'],
      nameKeys: const <String>['user_name', 'user_id'],
    );
  }

  Future<List<ValidateActivityItem>> fetchActivities(
    ValidateDataQuery query,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.validateActivitiesPath,
      data: query.params,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
        headers: _ajaxHeaders,
      ),
    );
    return _rows(_decode(response.data))
        .map(ValidateActivityItem.fromJson)
        .where((ValidateActivityItem item) => item.progressId.isNotEmpty)
        .toList();
  }

  Future<String> approve({
    required String structure,
    required String progressId,
    required String contractId,
  }) {
    return _action(
      ApiConstants.validateApprovePath,
      <String, dynamic>{
        'structure': structure,
        'progress_id': progressId,
        'work_id_fk': 'null',
        'contract_id_fk': contractId,
      },
    );
  }

  Future<String> reject({
    required String structure,
    required String progressId,
    required String contractId,
  }) {
    return _action(
      ApiConstants.validateRejectPath,
      <String, dynamic>{
        'structure': structure,
        'progress_id': progressId,
        'work_id_fk': 'null',
        'contract_id_fk': contractId,
      },
    );
  }

  Future<String> approveMany(List<ValidateActivityItem> items) {
    return _action(
      ApiConstants.validateApproveManyPath,
      <String, dynamic>{
        'progress_id': items.map((e) => e.progressId).join(','),
        'work_id_fk': '',
        'contract_id_fk': items.first.contractId ?? '',
        'structure': items.first.structure ?? '',
      },
    );
  }

  Future<String> rejectMany(List<ValidateActivityItem> items) {
    return _action(
      ApiConstants.validateRejectManyPath,
      <String, dynamic>{
        'progress_id': items.map((e) => e.progressId).join(','),
      },
    );
  }

  Future<List<DropdownOption>> _options(
    String path,
    ValidateDataQuery query, {
    required List<String> idKeys,
    required List<String> nameKeys,
    bool prefixId = false,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      path,
      queryParameters: query.params,
      options: Options(
        responseType: ResponseType.plain,
        headers: _ajaxHeaders,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    if (response.statusCode == 404) {
      return const <DropdownOption>[];
    }
    final List<DropdownOption> options = <DropdownOption>[];
    final Set<String> seen = <String>{};
    for (final Map<String, dynamic> row in _rows(_decode(response.data))) {
      final String id = _first(row, idKeys);
      if (id.isEmpty || !seen.add(id)) {
        continue;
      }
      final String name = _first(row, nameKeys);
      final String label =
          name.isEmpty ? id : (prefixId && name != id ? '$id - $name' : name);
      options.add(DropdownOption(id: id, name: label));
    }
    return options;
  }

  Future<String> _action(String path, Map<String, dynamic> query) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      queryParameters: query,
      options: Options(
        responseType: ResponseType.plain,
        headers: _ajaxHeaders,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    final int status = response.statusCode ?? 0;
    if (status >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Unable to update approval.',
      );
    }
    final dynamic decoded = _decode(response.data);
    if (decoded is Map) {
      final String message = (decoded['message'] ?? '').toString().trim();
      final bool flagged = decoded['message_flag'] == true;
      if (message.isNotEmpty && message.toLowerCase() != 'null') {
        if (!flagged) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: message,
          );
        }
        return message;
      }
    }
    return 'Updated.';
  }

  String _first(Map<String, dynamic> row, List<String> keys) {
    for (final String key in keys) {
      final String text = (row[key] ?? '').toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  dynamic _decode(dynamic data) {
    if (data is String) {
      final String trimmed = data.trim();
      if (trimmed.isEmpty) {
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

  List<Map<String, dynamic>> _rows(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((Map row) => Map<String, dynamic>.from(row))
          .toList();
    }
    if (data is Map) {
      return <Map<String, dynamic>>[Map<String, dynamic>.from(data)];
    }
    return const <Map<String, dynamic>>[];
  }

  static const Map<String, String> _ajaxHeaders = <String, String>{
    'X-Requested-With': 'XMLHttpRequest',
    'Accept': 'application/json, text/javascript, */*; q=0.01',
  };
}

final validateDataApiDataSourceProvider =
    Provider<ValidateDataApiDataSource>((ref) {
  return ValidateDataApiDataSource(ref.watch(dioProvider));
});
