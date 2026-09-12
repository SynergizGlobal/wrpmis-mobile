import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/issue_form_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/issue_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

class IssueApiDataSource {
  const IssueApiDataSource(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchIssueFilter({
    required String path,
    required Map<String, dynamic> params,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: params,
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  Future<List<IssueListItem>> fetchIssuesList({
    required Map<String, dynamic> params,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.issuesListPath,
      data: params,
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
        .map(IssueListItem.fromJson)
        .where((IssueListItem e) => e.isValid)
        .toList();
  }

  Future<List<DropdownOption>> fetchProjects() async {
    final response = await _dio.get<dynamic>(
      ApiConstants.projectsListPath,
      options: Options(
        responseType: ResponseType.json,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    return _mapOptions(
      _asList(_decodeJson(response.data)),
      idKeys: const <String>['project_id', 'projectId'],
      nameKeys: const <String>['project_name', 'projectName'],
    );
  }

  Future<List<DropdownOption>> fetchFormContracts(String projectId) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.issueFormContractsPath,
      queryParameters: <String, dynamic>{'project_id_fk': projectId},
      options: _ajaxGetOptions,
    );
    return _mapOptions(
      _asList(_decodeJson(response.data)),
      idKeys: const <String>['contract_id_fk', 'contract_id'],
      nameKeys: const <String>['contract_short_name', 'contract_name'],
      extraKeys: const <String>['contract_type_fk'],
    );
  }

  Future<List<DropdownOption>> fetchFormCategories(String contractType) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.issueFormCategoryPath,
      queryParameters: <String, dynamic>{'contract_type_fk': contractType},
      options: _ajaxGetOptions,
    );
    return _mapOptions(
      _asList(_decodeJson(response.data)),
      idKeys: const <String>['category', 'category_fk'],
      nameKeys: const <String>['category', 'category_fk'],
    );
  }

  Future<List<DropdownOption>> fetchFormTitles(String category) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.issueFormTitlesPath,
      queryParameters: <String, dynamic>{'category_fk': category},
      options: _ajaxGetOptions,
    );
    return _mapOptions(
      _asList(_decodeJson(response.data)),
      idKeys: const <String>['short_description', 'title'],
      nameKeys: const <String>['short_description', 'title'],
    );
  }

  Future<List<DropdownOption>> fetchFormStructures(String contractId) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.issueFormStructuresPath,
      queryParameters: <String, dynamic>{'contract_id_fk': contractId},
      options: _ajaxGetOptions,
    );
    return _mapOptions(
      _asList(_decodeJson(response.data)),
      idKeys: const <String>['structure'],
      nameKeys: const <String>['structure'],
    );
  }

  Future<List<DropdownOption>> fetchFormComponents({
    required String contractId,
    required String structure,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.issueFormComponentsPath,
      queryParameters: <String, dynamic>{
        'contract_id_fk': contractId,
        'structure': structure,
      },
      options: _ajaxGetOptions,
    );
    return _mapOptions(
      _asList(_decodeJson(response.data)),
      idKeys: const <String>['component'],
      nameKeys: const <String>['component'],
    );
  }

  Future<List<DropdownOption>> fetchFormStatuses() async {
    final response = await _dio.get<dynamic>(
      ApiConstants.issueFormStatusPath,
      options: _ajaxGetOptions,
    );
    return _mapOptions(
      _asList(_decodeJson(response.data)),
      idKeys: const <String>['status', 'status_fk'],
      nameKeys: const <String>['status', 'status_fk'],
    );
  }

  Future<List<DropdownOption>> fetchResponsiblePersons(
    String departmentName,
  ) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.issueFormResponsiblePath,
      queryParameters: <String, dynamic>{'department_name': departmentName},
      options: _ajaxGetOptions,
    );
    return _mapOptions(
      _asList(_decodeJson(response.data)),
      idKeys: const <String>[
        'responsible_person_user_id',
        'responsible_person',
      ],
      nameKeys: const <String>[
        'responsible_person',
        'responsible_person_designation',
      ],
      extraKeys: const <String>['responsible_person_designation'],
      combineName: true,
    );
  }

  Future<List<DropdownOption>> fetchLaDetails() async {
    final response = await _dio.get<dynamic>(
      ApiConstants.issueFormLaDetailsPath,
      options: _ajaxGetOptions,
    );
    return _mapOptions(
      _asList(_decodeJson(response.data)),
      idKeys: const <String>['la_id', 'id'],
      nameKeys: const <String>['la_name', 'name', 'title'],
    );
  }

  Future<IssueFormDetail> fetchIssueForm({String? issueId}) async {
    final bool editing = issueId != null && issueId.isNotEmpty;
    final String path =
        editing ? ApiConstants.issueGetPath : ApiConstants.issueAddFormPath;
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: editing
            ? <String, dynamic>{'issue_id': issueId}
            : const <String, dynamic>{},
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (int? status) =>
              status != null && status >= 200 && status < 500,
        ),
      );
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Session expired. Please sign in again.',
        );
      }
      if (response.statusCode != 200) {
        return const IssueFormDetail();
      }
      return _parseIssueFormHtml(
        (response.data ?? '').toString(),
        issueId: issueId,
      );
    } on DioException {
      rethrow;
    } catch (_) {
      return const IssueFormDetail();
    }
  }

  IssueFormDetail _parseIssueFormHtml(String html, {String? issueId}) {
    String? inputValue(String name) {
      return _first(
            html,
            RegExp(
              '''name=["']$name["'][^>]*value=["']([^"']*)["']''',
              caseSensitive: false,
            ),
          ) ??
          _first(
            html,
            RegExp(
              '''value=["']([^"']*)["'][^>]*name=["']$name["']''',
              caseSensitive: false,
            ),
          );
    }

    String? textareaValue(String name) {
      return _first(
        html,
        RegExp(
          '''<(?:textarea)[^>]*(?:name|id)=["']$name["'][^>]*>([\\s\\S]*?)</textarea>''',
          caseSensitive: false,
        ),
      )?.trim();
    }

    String? selectedOption(String name) {
      final String? block = _selectBlock(html, name);
      if (block == null) {
        return null;
      }
      for (final _HtmlOption opt in _parseOptions(block)) {
        if (opt.selected && opt.id.isNotEmpty) {
          return opt.id;
        }
      }
      return null;
    }

    List<DropdownOption> optionsFor(String name) {
      return _uniqueOptions(_parseOptions(_selectBlock(html, name) ?? ''));
    }

    final List<DropdownOption> projects = optionsFor('project_id_fk');
    final List<DropdownOption> priorities = optionsFor('priority_fk');
    final List<DropdownOption> organizations = optionsFor(
      'other_organization',
    );
    List<DropdownOption> fileTypes = optionsFor('issue_file_types');
    if (fileTypes.isEmpty) {
      fileTypes = optionsFor('issue_file_type_fk');
    }

    final String? contractId =
        _clean(inputValue('contract_id_fk')) ?? selectedOption('contract_id_fk');
    final List<IssueHistoryRow> history = _parseHistory(html);

    return IssueFormDetail(
      issueId: _clean(inputValue('issue_id')) ?? issueId,
      projectId: _clean(inputValue('project_id_fk')) ??
          selectedOption('project_id_fk'),
      projectLabel: _clean(inputValue('project_id_fk_temp')),
      contractId: contractId,
      contractLabel: _clean(inputValue('contract_id_fk_temp')),
      contractType: _clean(inputValue('contract_type_fk')) ??
          selectedOption('contract_type_fk'),
      structure: selectedOption('structure') ?? _clean(inputValue('structure')),
      component: selectedOption('component') ?? _clean(inputValue('component')),
      category: selectedOption('category_fk') ??
          selectedOption('issue_category') ??
          _clean(inputValue('category_fk')),
      shortDescription: _clean(inputValue('short_description')) ??
          selectedOption('short_description'),
      priority: selectedOption('priority_fk') ?? _clean(inputValue('priority_fk')),
      description: _clean(textareaValue('description')) ??
          _clean(inputValue('description')),
      deadline: _clean(inputValue('resolved_date')) ??
          _clean(inputValue('deadline_for_issue_resolution')),
      location: _clean(inputValue('location')),
      responsibleOrganization: selectedOption('other_organization') ??
          _clean(inputValue('other_organization')),
      responsiblePersonName: _clean(inputValue('responsible_person')),
      responsiblePersonDesignation:
          _clean(inputValue('responsible_person_designation')),
      reportedBy: _clean(inputValue('reported_by')),
      status: selectedOption('status_fk') ?? _clean(inputValue('status_fk')),
      remarks: _clean(textareaValue('remarks')) ??
          _clean(textareaValue('actionremarks')),
      history: history,
      projects: projects,
      priorities:
          priorities.isEmpty ? IssueFormDetail.fallbackPriorities : priorities,
      organizations: organizations.isEmpty
          ? IssueFormDetail.fallbackOrganizations
          : organizations,
      fileTypes:
          fileTypes.isEmpty ? IssueFormDetail.fallbackFileTypes : fileTypes,
    );
  }

  List<IssueHistoryRow> _parseHistory(String html) {
    final List<IssueHistoryRow> rows = <IssueHistoryRow>[];
    final Iterable<RegExpMatch> matches = RegExp(
      r'''updated_by["'][^>]*>([^<]+).*?update_date["'][^>]*>([^<]+).*?remarks["'][^>]*>([^<]+)''',
      caseSensitive: false,
    ).allMatches(html);
    for (final RegExpMatch m in matches) {
      rows.add(
        IssueHistoryRow(
          updatedBy: _clean(m.group(1)),
          updateDate: _clean(m.group(2)),
          remarks: _clean(m.group(3)),
        ),
      );
    }
    return rows;
  }

  String? _selectBlock(String html, String name) {
    return _first(
          html,
          RegExp(
            '''<(?:select)[^>]*(?:name|id)=["']$name["'][^>]*>[\\s\\S]*?</select>''',
            caseSensitive: false,
          ),
        ) ??
        _first(
          html,
          RegExp(
            '''<(?:select)[^>]*(?:name|id)=["']$name\\d*["'][^>]*>[\\s\\S]*?</select>''',
            caseSensitive: false,
          ),
        );
  }

  List<_HtmlOption> _parseOptions(String block) {
    final List<_HtmlOption> options = <_HtmlOption>[];
    final Iterable<RegExpMatch> matches = RegExp(
      r'''<option([^>]*)>([\s\S]*?)</option>''',
      caseSensitive: false,
    ).allMatches(block);
    for (final RegExpMatch m in matches) {
      final String attrs = m.group(1) ?? '';
      final String label = _stripHtml(m.group(2) ?? '').trim();
      final String id = _first(
            attrs,
            RegExp(r'''value\s*=\s*["']?\s*([^"'\s>]+)''', caseSensitive: false),
          ) ??
          '';
      if (label.isEmpty && id.isEmpty) {
        continue;
      }
      options.add(
        _HtmlOption(
          id: id,
          name: label.isEmpty ? id : label,
          selected: attrs.toLowerCase().contains('selected'),
        ),
      );
    }
    return options;
  }

  List<DropdownOption> _uniqueOptions(List<_HtmlOption> options) {
    final Set<String> seen = <String>{};
    final List<DropdownOption> out = <DropdownOption>[];
    for (final _HtmlOption opt in options) {
      if (opt.id.isEmpty || !seen.add(opt.id)) {
        continue;
      }
      out.add(opt.toDropdown());
    }
    return out;
  }

  List<DropdownOption> _mapOptions(
    List<Map<String, dynamic>> rows, {
    required List<String> idKeys,
    required List<String> nameKeys,
    List<String> extraKeys = const <String>[],
    bool combineName = false,
  }) {
    final List<DropdownOption> options = <DropdownOption>[];
    final Set<String> seen = <String>{};
    for (final Map<String, dynamic> row in rows) {
      final String id = _firstValue(row, idKeys);
      if (id.isEmpty || !seen.add(id)) {
        continue;
      }
      final String primary = _firstValue(row, nameKeys);
      String label = primary.isEmpty ? id : primary;
      if (combineName && nameKeys.length > 1) {
        final String second = _firstValue(row, nameKeys.sublist(1));
        if (second.isNotEmpty && second != primary) {
          label = '$primary - $second';
        }
      }
      options.add(
        DropdownOption(
          id: id,
          name: label,
          extra: extraKeys.isEmpty ? null : _firstValue(row, extraKeys),
        ),
      );
    }
    return options;
  }

  String _firstValue(Map<String, dynamic> row, List<String> keys) {
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

  String? _first(String source, RegExp pattern) {
    final Match? match = pattern.firstMatch(source);
    return match?.group(1);
  }

  String? _clean(String? value) {
    if (value == null) {
      return null;
    }
    final String text = _stripHtml(value).trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }

  String _stripHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
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

class _HtmlOption {
  const _HtmlOption({
    required this.id,
    required this.name,
    required this.selected,
  });

  final String id;
  final String name;
  final bool selected;

  DropdownOption toDropdown() => DropdownOption(id: id, name: name);
}

final issueApiDataSourceProvider = Provider<IssueApiDataSource>((ref) {
  return IssueApiDataSource(ref.watch(dioProvider));
});
