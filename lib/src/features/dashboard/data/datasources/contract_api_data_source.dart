import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contract_form_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contract_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

class ContractApiDataSource {
  const ContractApiDataSource(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchContractFilter({
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

  Future<List<ContractListItem>> fetchContractsList({
    required Map<String, dynamic> params,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.contractsListPath,
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
        .map(ContractListItem.fromJson)
        .where((ContractListItem e) => e.isValid)
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchHodList() async {
    final response = await _dio.get<dynamic>(
      ApiConstants.contractHodListPath,
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  Future<List<Map<String, dynamic>>> fetchDyHodList(String hodUserId) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.contractDyHodListPath,
      queryParameters: <String, dynamic>{'hod_user_id_fk': hodUserId},
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  Future<List<Map<String, dynamic>>> fetchExecutives(String departmentFk) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.contractExecutivesPath,
      queryParameters: <String, dynamic>{'department_fk': departmentFk},
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  Future<List<Map<String, dynamic>>> fetchFormWorkStatuses(
    String awarded,
  ) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.contractFormWorkStatusPath,
      queryParameters: <String, dynamic>{'contract_status': awarded},
      options: _ajaxGetOptions,
    );
    return _asList(_decodeJson(response.data));
  }

  Future<ContractFormDetail> fetchContractForm({String? contractId}) async {
    final bool editing = contractId != null && contractId.isNotEmpty;
    final response = await _dio.get<dynamic>(
      editing ? ApiConstants.contractGetPath : ApiConstants.contractAddFormPath,
      queryParameters: editing
          ? <String, dynamic>{'contract_id': contractId}
          : const <String, dynamic>{},
      options: Options(responseType: ResponseType.plain),
    );
    return _parseContractFormHtml(
      (response.data ?? '').toString(),
      contractId: contractId,
    );
  }

  ContractFormDetail _parseContractFormHtml(
    String html, {
    String? contractId,
  }) {
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
              '''id=["']$name["'][^>]*value=["']([^"']*)["']''',
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

    String? selectedRadio(String name) {
      final Iterable<RegExpMatch> matches = RegExp(
        '''name=["']$name["'][^>]*value=["']([^"']+)["']([^>]*)>''',
        caseSensitive: false,
      ).allMatches(html);
      for (final RegExpMatch m in matches) {
        final String attrs = '${m.group(2) ?? ''} ${m.group(0)}';
        if (attrs.toLowerCase().contains('checked')) {
          return m.group(1);
        }
      }
      return null;
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

    String? jsUser(String field) {
      return _first(
        html,
        RegExp(
          '''var user = ["']([^"']+)["'];\\s*if\\(val\\.$field''',
          caseSensitive: false,
        ),
      );
    }

    String? jsVar(String name) {
      return _first(
        html,
        RegExp('''var $name = ["']([^"']*)["']'''),
      );
    }

    final List<DropdownOption> projects = _parseOptions(
      _selectBlock(html, 'project_id_fk') ?? '',
    ).where((e) => e.id.isNotEmpty).map((e) => e.toDropdown()).toList();

    final List<DropdownOption> departments = _uniqueOptions(
      _parseOptions(_selectBlock(html, 'contract_department') ?? ''),
    );
    final List<DropdownOption> types = _uniqueOptions(
      _parseOptions(_selectBlock(html, 'contract_type_fk') ?? ''),
    );
    final List<DropdownOption> contractors = _uniqueOptions(
      _parseOptions(_selectBlock(html, 'contractor_id_fk') ?? ''),
    );
    final List<DropdownOption> units = _uniqueOptions(
      _parseOptions(_selectBlock(html, 'estimated_cost_units') ?? ''),
    );
    List<DropdownOption> fileTypes = _uniqueOptions(
      _parseOptions(_selectBlock(html, 'contract_file_types') ?? ''),
    );
    if (fileTypes.isEmpty) {
      fileTypes = const <DropdownOption>[
        DropdownOption(id: 'Document', name: 'Document'),
        DropdownOption(id: 'Drawing', name: 'Drawing'),
        DropdownOption(id: 'Photograph', name: 'Photograph'),
        DropdownOption(id: 'Report', name: 'Report'),
        DropdownOption(id: 'Other', name: 'Other'),
      ];
    }

    final String? departmentFk = selectedOption('department_fks') ??
        selectedOption('department_fk0');
    final List<String> execIds = _parseOptions(
      _selectBlock(html, 'responsible_people_id_fks0') ??
          _selectBlock(html, 'responsible_people_id_fks') ??
          '',
    ).where((e) => e.selected && e.id.isNotEmpty).map((e) => e.id).toList();

    return ContractFormDetail(
      contractId: _clean(inputValue('contract_id')) ?? contractId,
      projectId: _clean(inputValue('project_id_fk')) ??
          selectedOption('project_id_fk'),
      projectLabel: _clean(inputValue('project_id_fk_temp')),
      hodUserId: jsUser('hod_user_id_fk') ?? selectedOption('hod_user_id_fk'),
      dyHodUserId:
          jsUser('dy_hod_user_id_fk') ?? selectedOption('dy_hod_user_id_fk'),
      contractDepartment: selectedOption('contract_department'),
      bankFunded: selectedRadio('bank_funded') ?? 'No',
      awarded: selectedRadio('contract_status') ?? 'No',
      shortName: _clean(inputValue('contract_short_name')),
      contractName: _clean(textareaValue('contract_name')) ??
          _clean(inputValue('contract_name')),
      contractType: selectedOption('contract_type_fk'),
      contractorId: selectedOption('contractor_id_fk'),
      contractCode: _clean(inputValue('contract_ifas_code')) ??
          _clean(inputValue('contract_id_code')),
      scope: _clean(textareaValue('scope_of_contract')),
      loaLetterNumber: _clean(inputValue('loa_letter_number')),
      loaDate: _clean(inputValue('loa_date')),
      caNo: _clean(inputValue('ca_no')),
      caDate: _clean(inputValue('ca_date')),
      dateOfStart: _clean(inputValue('date_of_start')),
      originalDoc: _clean(inputValue('doc')),
      targetDoc: _clean(inputValue('target_doc')),
      awardedCost: _clean(inputValue('awarded_cost')),
      awardedCostUnit: selectedOption('awarded_cost_units'),
      estimatedCost: _clean(inputValue('estimated_cost')),
      estimatedCostUnit: selectedOption('estimated_cost_units'),
      workStatus: jsVar('contract_status_fk') ??
          selectedOption('contract_status_fk'),
      plannedDateOfAward: _clean(inputValue('planned_date_of_award')),
      plannedDateOfCompletion: _clean(inputValue('planned_date_of_completion')),
      noticeInvitingTender: _clean(inputValue('notice_inviting_tender')) ??
          _clean(inputValue('contract_notice_inviting_tender')),
      tenderOpeningDate: _clean(inputValue('tender_opening_date')),
      technicalEvalSubmission: _clean(inputValue('technical_eval_submission')),
      financialEvalSubmission: _clean(inputValue('financial_eval_submission')),
      bgRequired: jsVar('bg_required') ?? selectedRadio('bg_required') ?? 'No',
      insuranceRequired: jsVar('insurance_required') ??
          selectedRadio('insurance_required') ??
          'No',
      milestoneRequired: jsVar('milestone_requried') ??
          selectedRadio('milestone_requried') ??
          'No',
      revisionRequired: jsVar('revision_requried') ??
          selectedRadio('revision_requried') ??
          'No',
      keyPersonnelRequired: jsVar('contractors_key_requried') ??
          selectedRadio('contractors_key_requried') ??
          'No',
      gstInclusive: _clean(inputValue('contract_value_gst')),
      gstRate: _clean(inputValue('gst_rate')),
      executives: <ContractExecutiveRow>[
        ContractExecutiveRow(
          departmentId: departmentFk,
          executiveIds: execIds,
        ),
      ],
      revisions: <ContractRevisionRow>[
        ContractRevisionRow(
          revisionNo: _clean(inputValue('revisionno')) ?? 'R1',
          estimatedCost: _clean(inputValue('revision_estimated_cost')),
          plannedAward: _clean(inputValue('revision_planned_date_of_award')),
          plannedCompletion:
              _clean(inputValue('revision_planned_date_of_completion')),
          noticeInvitingTender: _clean(inputValue('notice_inviting_tender')),
          tenderOpeningDate: _clean(inputValue('tender_bid_opening_date')),
          technicalEvalApproval: _clean(inputValue('technical_eval_approval')),
          financialEvalApproval: _clean(inputValue('financial_eval_approval')),
          remarks: _clean(textareaValue('tender_bid_remarks')),
        ),
      ],
      documents: <ContractDocumentRow>[
        ContractDocumentRow(
          fileType: selectedOption('contract_file_types'),
          name: _clean(inputValue('contractDocumentNames')),
          fileId: _clean(inputValue('contract_file_ids')),
        ),
      ],
      options: ContractFormOptions(
        projects: projects,
        departments: departments,
        contractTypes: types,
        contractors: contractors,
        costUnits: units,
        fileTypes: fileTypes,
      ),
    );
  }

  String? _selectBlock(String html, String name) {
    final Match? exact = RegExp(
      '''<(?:select)[^>]*(?:name|id)=["']$name["'][^>]*>[\\s\\S]*?</select>''',
      caseSensitive: false,
    ).firstMatch(html);
    if (exact != null) {
      return exact.group(0);
    }
    final Match? indexed = RegExp(
      '''<(?:select)[^>]*(?:name|id)=["']$name\\d*["'][^>]*>[\\s\\S]*?</select>''',
      caseSensitive: false,
    ).firstMatch(html);
    return indexed?.group(0);
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

  String? _first(String source, RegExp pattern) {
    final Match? match = pattern.firstMatch(source);
    if (match == null) {
      return null;
    }
    if (match.groupCount >= 1) {
      return match.group(1);
    }
    return match.group(0);
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

final contractApiDataSourceProvider = Provider<ContractApiDataSource>((ref) {
  return ContractApiDataSource(ref.watch(dioProvider));
});
