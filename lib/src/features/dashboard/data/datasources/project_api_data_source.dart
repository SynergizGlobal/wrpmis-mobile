import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';
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

  /// GET /api/v1/structures/add-form-data
  Future<Map<String, dynamic>> fetchStructureFormData() async {
    final response =
        await _dio.get<dynamic>(ApiConstants.structuresFormDataPath);
    return _asMap(response.data);
  }

  /// GET /api/v1/structures/{structure_id}
  Future<Map<String, dynamic>> fetchStructureById(String structureId) async {
    final response = await _dio.get<dynamic>(
      '${ApiConstants.structuresPath}/$structureId',
    );
    return _asMap(response.data);
  }

  /// POST /api/v1/structures
  Future<String> addStructures(Map<String, dynamic> payload) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.structuresPath,
      data: payload,
      options: Options(contentType: Headers.jsonContentType),
    );
    final data = _asMap(response.data);
    return data['message']?.toString() ?? 'Structure added.';
  }

  /// PUT /api/v1/structures
  Future<String> updateStructures(Map<String, dynamic> payload) async {
    final response = await _dio.put<dynamic>(
      ApiConstants.structuresPath,
      data: payload,
      options: Options(contentType: Headers.jsonContentType),
    );
    final data = _asMap(response.data);
    return data['message']?.toString() ?? 'Structure updated.';
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
    final List<Map<String, dynamic>> rows = _asList(
      map['aaData'] ?? map['data'],
    );
    final int total = int.tryParse('${map['iTotalRecords'] ?? rows.length}') ??
        rows.length;
    final int filtered =
        int.tryParse('${map['iTotalDisplayRecords'] ?? total}') ?? total;
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

  // ── Helpers ─────────────────────────────────────────────────────────

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
