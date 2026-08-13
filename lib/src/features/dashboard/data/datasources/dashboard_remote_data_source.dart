import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';

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

  /// GET `/api/v1/projects/list` — requires logged-in session cookie.
  Future<List<Map<String, dynamic>>> fetchProjects() async {
    final response = await _dio.get<dynamic>(
      ApiConstants.projectsApiPath,
      options: Options(
        responseType: ResponseType.json,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    final dynamic data = response.data;
    if (data is String && data.toLowerCase().contains('<title>login</title>')) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Session expired. Please sign in again.',
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Session expired. Please sign in again.',
      );
    }
    return _asListOfMaps(data);
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
