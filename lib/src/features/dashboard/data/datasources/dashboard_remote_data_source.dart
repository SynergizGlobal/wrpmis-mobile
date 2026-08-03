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

  /// GET `/api/projects` — requires logged-in session cookie.
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

  /// Home page embeds `allProjectsProjectTypes` (full project list for summary).
  Future<List<Map<String, dynamic>>> fetchHomeProjectSummaries() async {
    final response = await _dio.get<dynamic>(
      ApiConstants.homePath,
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    final String html = response.data?.toString() ?? '';
    if (html.toLowerCase().contains('<title>login</title>')) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Session expired. Please sign in again.',
      );
    }
    return _parseEmbeddedProjectTypes(html);
  }

  List<Map<String, dynamic>> _parseEmbeddedProjectTypes(String html) {
    final RegExp block = RegExp(
      r"allProjectsProjectTypes\.push\(\s*\{(.*?)\}\s*\)",
      dotAll: true,
    );
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    for (final RegExpMatch match in block.allMatches(html)) {
      final String body = match.group(1) ?? '';
      String? read(String key) {
        final RegExp value = RegExp(
          "$key\\s*:\\s*'([^']*)'|$key\\s*:\\s*([0-9.]+)",
        );
        final RegExpMatch? m = value.firstMatch(body);
        if (m == null) {
          return null;
        }
        return (m.group(1) ?? m.group(2))?.trim();
      }

      final String? projectId = read('project_id');
      if (projectId == null || projectId.isEmpty) {
        continue;
      }
      rows.add(<String, dynamic>{
        'project_id': projectId,
        'project_name': read('project_name'),
        'project_type_id': read('project_type_id'),
        'project_type_name': read('project_type_name'),
        'length': read('length'),
        'commissioned_length': read('commissioned_length'),
      });
    }
    return rows;
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
      for (final String key in <String>['data', 'result', 'list', 'projects']) {
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
