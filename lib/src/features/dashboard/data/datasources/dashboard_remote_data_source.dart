import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/project_page_parser.dart';

class DashboardRemoteDataSource {
  const DashboardRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchProjectTypes() async {
    final response = await _dio.get<dynamic>(ApiConstants.projectTypesPath);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> fetchProjectList() async {
    final response = await _dio.get<dynamic>(ApiConstants.projectListPath);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> fetchProjectListByType() async {
    final response =
        await _dio.get<dynamic>(ApiConstants.projectListByTypePath);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> fetchUpdateForms() async {
    final response = await _dio.get<dynamic>(ApiConstants.updateFormsPath);
    return _asMap(response.data);
  }

  /// Same source as the web Projects page: `GET /project`.
  Future<List<Map<String, dynamic>>> fetchProjects() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.projectsPagePath,
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    final String body = response.data?.toString() ?? '';
    if (_isLoginHtml(body) ||
        response.statusCode == 401 ||
        response.statusCode == 403) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Session expired. Please sign in again.',
      );
    }
    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Unable to load projects.',
      );
    }

    final String trimmed = body.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        return _asListOfMaps(jsonDecode(trimmed));
      } catch (_) {
        // Fall through to HTML table parse.
      }
    }
    return ProjectPageParser.parse(body);
  }

  bool _isLoginHtml(String body) {
    final String lower = body.toLowerCase();
    return lower.contains('<title>login</title>');
  }

  List<Map<String, dynamic>> _asListOfMaps(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (Map entry) => entry.map(
              (dynamic key, dynamic value) => MapEntry(key.toString(), value),
            ),
          )
          .toList();
    }
    if (data is Map) {
      final Map<String, dynamic> map = data.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );
      for (final String key in <String>[
        'data',
        'result',
        'list',
        'projects',
        'content',
        'items',
        'records',
      ]) {
        final dynamic nested = map[key];
        if (nested is List) {
          return _asListOfMaps(nested);
        }
      }
    }
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );
    }
    if (data is List) {
      return <String, dynamic>{'data': data};
    }
    return <String, dynamic>{};
  }
}

final dashboardRemoteDataSourceProvider =
    Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSource(ref.watch(dioProvider));
});
