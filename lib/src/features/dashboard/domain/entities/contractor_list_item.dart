class ContractorListItem {
  const ContractorListItem({
    required this.contractorId,
    this.contractorName,
    this.panNumber,
    this.specialization,
    this.address,
    this.primaryContact,
    this.phoneNumber,
    this.email,
  });

  final String contractorId;
  final String? contractorName;
  final String? panNumber;
  final String? specialization;
  final String? address;
  final String? primaryContact;
  final String? phoneNumber;
  final String? email;

  bool get isValid => contractorId.isNotEmpty && contractorId != 'nullnull01';

  factory ContractorListItem.fromJson(Map<String, dynamic> json) {
    return ContractorListItem(
      contractorId: _n(json['contractor_id']) ?? '',
      contractorName: _n(json['contractor_name']),
      panNumber: _n(json['pan_number']),
      specialization: _n(json['contractor_specilization_fk']),
      address: _n(json['address']),
      primaryContact: _n(json['primary_contact_name']),
      phoneNumber: _n(json['phone_number']),
      email: _n(json['email_id'] ?? json['email']),
    );
  }

  static String? _n(dynamic value) {
    if (value == null) {
      return null;
    }
    final String text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }
}

class ContractorListResult {
  const ContractorListResult({
    required this.items,
    required this.totalRecords,
    required this.filteredRecords,
  });

  final List<ContractorListItem> items;
  final int totalRecords;
  final int filteredRecords;
}

class ContractorFilterQuery {
  const ContractorFilterQuery({
    this.search = '',
    this.page = 0,
    this.pageSize = 10,
  });

  final String search;
  final int page;
  final int pageSize;

  Map<String, dynamic> get ajaxParams {
    final Map<String, dynamic> params = <String, dynamic>{
      'sEcho': 1,
      'iColumns': 9,
      'sColumns': ',,,,,,,,',
      'iDisplayStart': page * pageSize,
      'iDisplayLength': pageSize,
      'sSearch': search,
      'bRegex': false,
    };
    for (int i = 0; i < 9; i++) {
      params['mDataProp_$i'] = 'function';
      params['sSearch_$i'] = '';
      params['bRegex_$i'] = false;
      params['bSearchable_$i'] = true;
    }
    return params;
  }

  @override
  bool operator ==(Object other) {
    return other is ContractorFilterQuery &&
        other.search == search &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(search, page, pageSize);
}
