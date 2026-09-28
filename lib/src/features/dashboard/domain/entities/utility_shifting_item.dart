class UtilityShiftingItem {
  const UtilityShiftingItem({
    required this.id,
    this.utilityShiftingId,
    this.description,
    this.utilityType,
    this.custodian,
    this.hod,
    this.hodUserId,
    this.executionAgency,
    this.status,
    this.lastUpdate,
    this.projectId,
    this.locationName,
    this.referenceNumber,
    this.executedBy,
    this.chainage,
    this.latitude,
    this.longitude,
    this.impactedContractId,
    this.requirementStage,
    this.impactedElement,
    this.affectedStructures,
    this.targetDate,
    this.scope,
    this.completed,
    this.unit,
    this.startDate,
    this.completionDate,
    this.identification,
    this.remarks,
  });

  final String id;
  final String? utilityShiftingId;
  final String? description;
  final String? utilityType;
  final String? custodian;
  final String? hod;
  final String? hodUserId;
  final String? executionAgency;
  final String? status;
  final String? lastUpdate;
  final String? projectId;
  final String? locationName;
  final String? referenceNumber;
  final String? executedBy;
  final String? chainage;
  final String? latitude;
  final String? longitude;
  final String? impactedContractId;
  final String? requirementStage;
  final String? impactedElement;
  final String? affectedStructures;
  final String? targetDate;
  final String? scope;
  final String? completed;
  final String? unit;
  final String? startDate;
  final String? completionDate;
  final String? identification;
  final String? remarks;

  bool get isValid =>
      (utilityShiftingId ?? '').isNotEmpty || id.isNotEmpty;

  factory UtilityShiftingItem.fromJson(Map<String, dynamic> json) {
    return UtilityShiftingItem(
      id: _n(json['id']) ?? '',
      utilityShiftingId: _n(json['utility_shifting_id']),
      description: _n(json['utility_description']),
      utilityType: _n(json['utility_type_fk']),
      custodian: _n(json['custodian']),
      hod: _n(json['user_name'] ?? json['designation']),
      executionAgency: _n(json['execution_agency_fk']),
      status: _n(json['shifting_status_fk']),
      lastUpdate: _n(
        json['latest_progress_date'] ?? json['modified_date'],
      ),
      projectId: _n(json['project_id_fk']),
      locationName: _n(json['location_name']),
      referenceNumber: _n(json['reference_number']),
      executedBy: _n(json['executed_by']),
      chainage: _n(json['chainage']),
      latitude: _n(json['latitude']),
      longitude: _n(json['longitude']),
      impactedContractId: _n(json['impacted_contract_id_fk']),
      requirementStage: _n(json['requirement_stage_fk']),
      impactedElement: _n(json['impacted_element']),
      affectedStructures: _n(json['affected_structures']),
      targetDate: _n(json['planned_completion_date']),
      scope: _n(json['scope']),
      completed: _n(json['completed']),
      unit: _n(json['unit_fk']),
      startDate: _n(json['start_date']),
      completionDate: _n(json['shifting_completion_date']),
      identification: _n(json['identification']),
      remarks: _n(json['remarks']),
      hodUserId: _n(json['hod_user_id_fk']),
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

class UtilityUploadItem {
  const UtilityUploadItem({
    this.utilityDataId,
    this.uploadedFile,
    this.status,
    this.remarks,
    this.uploadedBy,
    this.uploadedOn,
  });

  final String? utilityDataId;
  final String? uploadedFile;
  final String? status;
  final String? remarks;
  final String? uploadedBy;
  final String? uploadedOn;

  factory UtilityUploadItem.fromJson(Map<String, dynamic> json) {
    return UtilityUploadItem(
      utilityDataId: UtilityShiftingItem._n(json['utility_data_id']),
      uploadedFile: UtilityShiftingItem._n(json['uploaded_file']),
      status: UtilityShiftingItem._n(json['status']),
      remarks: UtilityShiftingItem._n(json['remarks']),
      uploadedBy: UtilityShiftingItem._n(json['uploaded_by_user_id_fk']),
      uploadedOn: UtilityShiftingItem._n(json['uploaded_on']),
    );
  }
}

class UtilityShiftingListResult {
  const UtilityShiftingListResult({
    required this.items,
    required this.totalRecords,
    required this.filteredRecords,
  });

  final List<UtilityShiftingItem> items;
  final int totalRecords;
  final int filteredRecords;
}

class UtilityShiftingFilterQuery {
  const UtilityShiftingFilterQuery({
    this.location,
    this.category,
    this.utilityType,
    this.status,
    this.search = '',
    this.page = 0,
    this.pageSize = 10,
  });

  final String? location;
  final String? category;
  final String? utilityType;
  final String? status;
  final String search;
  final int page;
  final int pageSize;

  Map<String, dynamic> get filterParams => <String, dynamic>{
        'location_name': location ?? '',
        'utility_category_fk': category ?? '',
        'utility_type_fk': utilityType ?? '',
        'shifting_status_fk': status ?? '',
      };

  Map<String, dynamic> get listParams {
    final Map<String, dynamic> params = <String, dynamic>{
      ...filterParams,
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
    return other is UtilityShiftingFilterQuery &&
        other.location == location &&
        other.category == category &&
        other.utilityType == utilityType &&
        other.status == status &&
        other.search == search &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
        location,
        category,
        utilityType,
        status,
        search,
        page,
        pageSize,
      );
}
