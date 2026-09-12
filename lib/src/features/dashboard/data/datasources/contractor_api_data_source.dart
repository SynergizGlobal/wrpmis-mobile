import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contractor_form_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contractor_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

class ContractorApiDataSource {
  const ContractorApiDataSource(this._dio);

  final Dio _dio;

  static const List<DropdownOption> fallbackSpecializations = <DropdownOption>[
    DropdownOption(id: 'Construction', name: 'Construction'),
    DropdownOption(id: 'Consultancy', name: 'Consultancy'),
    DropdownOption(id: 'Design Consultancy', name: 'Design Consultancy'),
    DropdownOption(
      id: 'General Consultancy Services',
      name: 'General Consultancy Services',
    ),
    DropdownOption(id: 'OEM', name: 'OEM'),
    DropdownOption(id: 'Others', name: 'Others'),
    DropdownOption(
      id: 'Project Management Consultancy',
      name: 'Project Management Consultancy',
    ),
  ];

  Future<ContractorListResult> fetchContractors(
    ContractorFilterQuery query,
  ) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.contractorsListPath,
      queryParameters: query.ajaxParams,
      options: _ajaxGetOptions,
    );
    final Map<String, dynamic> map = _asMap(_decodeJson(response.data));
    final List<ContractorListItem> items = _asList(
      map['aaData'] ?? map['data'],
    ).map(ContractorListItem.fromJson).where((e) => e.isValid).toList();
    final int total =
        int.tryParse('${map['iTotalRecords'] ?? items.length}') ?? items.length;
    final int filtered =
        int.tryParse('${map['iTotalDisplayRecords'] ?? total}') ?? total;
    return ContractorListResult(
      items: items,
      totalRecords: total,
      filteredRecords: filtered,
    );
  }

  Future<List<DropdownOption>> fetchSpecializations() async {
    final response = await _dio.get<dynamic>(
      ApiConstants.contractorAddFormPath,
      options: Options(responseType: ResponseType.plain),
    );
    final List<DropdownOption> options = _uniqueOptions(
      _parseOptions(
        _selectBlock(
              (response.data ?? '').toString(),
              'contractor_specilization_fk',
            ) ??
            '',
      ),
    );
    return options.isEmpty ? fallbackSpecializations : options;
  }

  Future<ContractorFormDetail> fetchContractorForm({
    String? contractorId,
  }) async {
    final bool editing = contractorId != null && contractorId.isNotEmpty;
    final List<DropdownOption> specializations = await fetchSpecializations();
    if (!editing) {
      return ContractorFormDetail(specializations: specializations);
    }
    final response = await _dio.get<dynamic>(
      ApiConstants.contractorGetPath,
      queryParameters: <String, dynamic>{'contractor_id': contractorId},
      options: Options(responseType: ResponseType.plain),
    );
    return _parseFormHtml(
      (response.data ?? '').toString(),
      contractorId: contractorId,
      specializations: specializations,
    );
  }

  Future<bool> isPanTaken(String panNumber, {String? ignoreContractorId}) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.contractorPanCheckPath,
      queryParameters: <String, dynamic>{'pan_number': panNumber},
      options: _ajaxGetOptions,
    );
    final List<Map<String, dynamic>> rows = _asList(_decodeJson(response.data));
    for (final Map<String, dynamic> row in rows) {
      final String pan = '${row['pan_number'] ?? ''}'.trim();
      if (pan.isEmpty) {
        continue;
      }
      final String id = '${row['contractor_id'] ?? ''}'.trim();
      if (ignoreContractorId != null &&
          ignoreContractorId.isNotEmpty &&
          id == ignoreContractorId) {
        continue;
      }
      return true;
    }
    return false;
  }

  Future<String> addContractor(Map<String, dynamic> payload) async {
    await _dio.post<dynamic>(
      ApiConstants.contractorAddPath,
      data: payload,
      options: _formPostOptions,
    );
    return 'Contractor added.';
  }

  Future<String> updateContractor(Map<String, dynamic> payload) async {
    await _dio.post<dynamic>(
      ApiConstants.contractorUpdatePath,
      data: payload,
      options: _formPostOptions,
    );
    return 'Contractor updated.';
  }

  ContractorFormDetail _parseFormHtml(
    String html, {
    required String contractorId,
    required List<DropdownOption> specializations,
  }) {
    String? inputValue(String name) {
      return _clean(
            _first(
              html,
              RegExp(
                '''name=["']$name["'][^>]*value=["']([^"']*)["']''',
                caseSensitive: false,
              ),
            ),
          ) ??
          _clean(
            _first(
              html,
              RegExp(
                '''id=["']$name["'][^>]*value=["']([^"']*)["']''',
                caseSensitive: false,
              ),
            ),
          ) ??
          _clean(
            _first(
              html,
              RegExp(
                '''value=["']([^"']*)["'][^>]*name=["']$name["']''',
                caseSensitive: false,
              ),
            ),
          );
    }

    String? textareaValue(String name) {
      return _clean(
        _first(
          html,
          RegExp(
            '''<(?:textarea)[^>]*(?:name|id)=["']$name["'][^>]*>([\\s\\S]*?)</textarea>''',
            caseSensitive: false,
          ),
        ),
      );
    }

    return ContractorFormDetail(
      contractorId: inputValue('contractor_id') ?? contractorId,
      panNumber: inputValue('pan_number'),
      specialization: inputValue('contractor_specilization_fk'),
      contractorName: inputValue('contractor_name'),
      address: textareaValue('address'),
      primaryContact: inputValue('primary_contact_name'),
      phoneNumber: inputValue('phone_number'),
      email: inputValue('email_id') ?? inputValue('email'),
      gstNumber: inputValue('gst_number'),
      bankName: inputValue('bank_name'),
      ifscCode: inputValue('ifsc_code'),
      accountNumber: inputValue('account_number') ?? inputValue('ac_no'),
      bankAddress: textareaValue('bank_address'),
      remarks: textareaValue('remarks'),
      specializations: specializations,
    );
  }

  String? _selectBlock(String html, String name) {
    final Match? exact = RegExp(
      '''<(?:select)[^>]*(?:name|id)=["']$name["'][^>]*>[\\s\\S]*?</select>''',
      caseSensitive: false,
    ).firstMatch(html);
    return exact?.group(0);
  }

  List<_HtmlOption> _parseOptions(String block) {
    final List<_HtmlOption> options = <_HtmlOption>[];
    for (final RegExpMatch m in RegExp(
      r'''<option([^>]*)>([\s\S]*?)</option>''',
      caseSensitive: false,
    ).allMatches(block)) {
      final String attrs = m.group(1) ?? '';
      final String label = _stripHtml(m.group(2) ?? '').trim();
      final String id = _first(
            attrs,
            RegExp(r'''value\s*=\s*["']?\s*([^"'\s>]+)''', caseSensitive: false),
          ) ??
          label;
      if (id.isEmpty || label.toLowerCase() == 'select') {
        continue;
      }
      options.add(_HtmlOption(id: id, name: label.isEmpty ? id : label));
    }
    return options;
  }

  List<DropdownOption> _uniqueOptions(List<_HtmlOption> options) {
    final Set<String> seen = <String>{};
    final List<DropdownOption> out = <DropdownOption>[];
    for (final _HtmlOption opt in options) {
      if (!seen.add(opt.id)) {
        continue;
      }
      out.add(DropdownOption(id: opt.id, name: opt.name));
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
      return _asList(Map<String, dynamic>.from(decoded)['aaData']);
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

  static Options get _formPostOptions => Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 400,
      );
}

class _HtmlOption {
  const _HtmlOption({required this.id, required this.name});

  final String id;
  final String name;
}

final contractorApiDataSourceProvider = Provider<ContractorApiDataSource>((ref) {
  return ContractorApiDataSource(ref.watch(dioProvider));
});
