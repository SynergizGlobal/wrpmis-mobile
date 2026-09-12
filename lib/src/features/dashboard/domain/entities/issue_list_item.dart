/// One row from Issues list (`POST /ajax/getIssuesList`).
class IssueListItem {
  const IssueListItem({
    required this.issueId,
    this.contractId,
    this.contractName,
    this.contractShortName,
    this.shortDescription,
    this.location,
    this.responsiblePerson,
    this.responsiblePersonDesignation,
    this.department,
    this.departmentName,
    this.railwayName,
    this.status,
    this.lastUpdate,
    this.projectId,
    this.projectName,
    this.category,
    this.priority,
    this.description,
    this.deadline,
    this.reportedBy,
    this.responsibleOrganization,
    this.remarks,
    this.structure,
    this.component,
    this.contractType,
  });

  final String issueId;
  final String? contractId;
  final String? contractName;
  final String? contractShortName;
  final String? shortDescription;
  final String? location;
  final String? responsiblePerson;
  final String? responsiblePersonDesignation;
  final String? department;
  final String? departmentName;
  final String? railwayName;
  final String? status;
  final String? lastUpdate;
  final String? projectId;
  final String? projectName;
  final String? category;
  final String? priority;
  final String? description;
  final String? deadline;
  final String? reportedBy;
  final String? responsibleOrganization;
  final String? remarks;
  final String? structure;
  final String? component;
  final String? contractType;

  String get contractDisplay {
    final String shortName = (contractShortName ?? '').trim();
    if (shortName.isNotEmpty) {
      return shortName;
    }
    final String name = (contractName ?? '').trim();
    return name.isEmpty ? (contractId ?? '-') : name;
  }

  String get departmentDisplay {
    final String railway = (railwayName ?? '').trim();
    final String dept = ((departmentName ?? department) ?? '').trim();
    if (railway.isNotEmpty && dept.isNotEmpty) {
      return '$railway - $dept';
    }
    if (dept.isNotEmpty) {
      return dept;
    }
    return railway.isEmpty ? '-' : railway;
  }

  bool get isValid {
    if (issueId.isEmpty) {
      return false;
    }
    return !issueId.toLowerCase().contains('null');
  }

  bool matchesSearch(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }
    return <String?>[
      issueId,
      contractId,
      contractName,
      contractShortName,
      shortDescription,
      location,
      responsiblePerson,
      departmentDisplay,
      status,
      projectName,
      category,
    ].any((String? v) => (v ?? '').toLowerCase().contains(q));
  }

  factory IssueListItem.fromJson(Map<String, dynamic> json) {
    return IssueListItem(
      issueId: _s(json['issue_id'] ?? json['issueId']),
      contractId: _n(json['contract_id_fk'] ?? json['contract_id']),
      contractName: _n(json['contract_name']),
      contractShortName: _n(json['contract_short_name']),
      shortDescription: _n(json['short_description'] ?? json['title']),
      location: _n(json['location']),
      responsiblePerson: _n(json['responsible_person']),
      responsiblePersonDesignation: _n(json['responsible_person_designation']),
      department: _n(json['department_fk'] ?? json['department']),
      departmentName: _n(json['department_name']),
      railwayName: _n(json['railway_name']),
      status: _n(json['status_fk'] ?? json['status']),
      lastUpdate: _n(json['modified_date'] ?? json['date'] ?? json['curdate']),
      projectId: _n(json['project_id_fk'] ?? json['project_id']),
      projectName: _n(json['project_name']),
      category: _n(json['category_fk'] ?? json['category']),
      priority: _n(json['priority_fk'] ?? json['priority']),
      description: _n(json['description']),
      deadline: _n(json['resolved_date'] ?? json['escalation_date']),
      reportedBy: _n(json['reported_by']),
      responsibleOrganization: _n(
        json['other_organization'] ?? json['issue_other_organization'],
      ),
      remarks: _n(json['remarks'] ?? json['actionremarks'] ?? json['comment']),
      structure: _n(json['structure']),
      component: _n(json['component']),
      contractType: _n(json['contract_type_fk']),
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

class IssueListResult {
  const IssueListResult({
    required this.items,
    required this.totalRecords,
    required this.filteredRecords,
  });

  final List<IssueListItem> items;
  final int totalRecords;
  final int filteredRecords;
}

class IssueFilterQuery {
  const IssueFilterQuery({
    this.contractId,
    this.hod,
    this.department,
    this.category,
    this.status,
    this.search = '',
    this.page = 0,
    this.pageSize = 10,
  });

  final String? contractId;
  final String? hod;
  final String? department;
  final String? category;
  final String? status;
  final String search;
  final int page;
  final int pageSize;

  Map<String, dynamic> get ajaxParams => <String, dynamic>{
        'contract_id_fk': contractId ?? '',
        'department_fk': department ?? '',
        'category_fk': category ?? '',
        'status_fk': status ?? '',
        'hod': hod ?? '',
      };

  @override
  bool operator ==(Object other) {
    return other is IssueFilterQuery &&
        other.contractId == contractId &&
        other.hod == hod &&
        other.department == department &&
        other.category == category &&
        other.status == status &&
        other.search == search &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
        contractId,
        hod,
        department,
        category,
        status,
        search,
        page,
        pageSize,
      );
}
