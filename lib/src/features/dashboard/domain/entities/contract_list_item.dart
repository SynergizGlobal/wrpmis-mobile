/// One row from Contracts list (`POST /ajax/getContracts`).
class ContractListItem {
  const ContractListItem({
    required this.contractId,
    this.projectId,
    this.projectName,
    this.contractName,
    this.contractShortName,
    this.contractorId,
    this.contractorName,
    this.departmentName,
    this.hodDesignation,
    this.dyHodDesignation,
    this.modifiedDate,
    this.hodUserId,
    this.dyHodUserId,
  });

  final String contractId;
  final String? projectId;
  final String? projectName;
  final String? contractName;
  final String? contractShortName;
  final String? contractorId;
  final String? contractorName;
  final String? departmentName;
  final String? hodDesignation;
  final String? dyHodDesignation;
  final String? modifiedDate;
  final String? hodUserId;
  final String? dyHodUserId;

  String get title {
    final String shortName = (contractShortName ?? '').trim();
    if (shortName.isNotEmpty) {
      return shortName;
    }
    final String name = (contractName ?? '').trim();
    return name.isEmpty ? contractId : name;
  }

  String get projectDisplay {
    final String name = (projectName ?? '').trim();
    final String id = (projectId ?? '').trim();
    if (id.isNotEmpty && name.isNotEmpty) {
      return '$id - $name';
    }
    return name.isNotEmpty ? name : (id.isEmpty ? '-' : id);
  }

  bool get isValid {
    if (contractId.isEmpty) {
      return false;
    }
    return !contractId.toLowerCase().contains('null');
  }

  bool matchesSearch(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }
    return <String?>[
      contractId,
      projectId,
      projectName,
      contractName,
      contractShortName,
      contractorName,
      departmentName,
      hodDesignation,
      dyHodDesignation,
    ].any((String? v) => (v ?? '').toLowerCase().contains(q));
  }

  factory ContractListItem.fromJson(Map<String, dynamic> json) {
    return ContractListItem(
      contractId: _s(json['contract_id'] ?? json['contract_ID']),
      projectId: _n(json['project_id_fk'] ?? json['project_id']),
      projectName: _n(json['project_name']),
      contractName: _n(json['contract_name']),
      contractShortName: _n(json['contract_short_name']),
      contractorId: _n(json['contractor_id_fk'] ?? json['contractor_id']),
      contractorName: _n(json['contractor_name']),
      departmentName: _n(json['department_name'] ?? json['contract_department']),
      hodDesignation: _n(json['designation'] ?? json['hod_designation']),
      dyHodDesignation: _n(json['dy_hod_designation']),
      modifiedDate: _n(json['modified_date']),
      hodUserId: _n(json['hod_user_id_fk'] ?? json['hod_user_id']),
      dyHodUserId: _n(json['dy_hod_user_id_fk'] ?? json['dy_hod_user_id']),
    );
  }

  static String _s(dynamic v) => (v ?? '').toString().trim();

  static String? _n(dynamic v) {
    if (v == null) {
      return null;
    }
    final String t = v.toString().trim();
    return t.isEmpty || t.toLowerCase() == 'null' ? null : t;
  }
}

class ContractListResult {
  const ContractListResult({
    required this.items,
    required this.totalRecords,
    required this.filteredRecords,
  });

  final List<ContractListItem> items;
  final int totalRecords;
  final int filteredRecords;
}

class ContractFilterQuery {
  const ContractFilterQuery({
    this.designation,
    this.dyHodDesignation,
    this.contractorId,
    this.contractStatus,
    this.workStatus,
    this.search = '',
    this.page = 0,
    this.pageSize = 10,
  });

  final String? designation;
  final String? dyHodDesignation;
  final String? contractorId;
  final String? contractStatus;
  final String? workStatus;
  final String search;
  final int page;
  final int pageSize;

  Map<String, dynamic> get ajaxParams => <String, dynamic>{
        'designation': designation ?? '',
        'dy_hod_designation': dyHodDesignation ?? '',
        'contractor_id_fk': contractorId ?? '',
        'contract_status': contractStatus ?? '',
        'contract_status_fk': workStatus ?? '',
        'project_id_fk': '',
      };

  @override
  bool operator ==(Object other) {
    return other is ContractFilterQuery &&
        other.designation == designation &&
        other.dyHodDesignation == dyHodDesignation &&
        other.contractorId == contractorId &&
        other.contractStatus == contractStatus &&
        other.workStatus == workStatus &&
        other.search == search &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
        designation,
        dyHodDesignation,
        contractorId,
        contractStatus,
        workStatus,
        search,
        page,
        pageSize,
      );
}
