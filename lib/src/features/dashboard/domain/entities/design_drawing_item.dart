class DesignDrawingItem {
  const DesignDrawingItem({
    required this.designId,
    this.designSeqId,
    this.structureType,
    this.structureId,
    this.title,
    this.drawingType,
    this.drawingNo,
    this.modifiedDate,
    this.contractId,
    this.contractShortName,
  });

  final String designId;
  final String? designSeqId;
  final String? structureType;
  final String? structureId;
  final String? title;
  final String? drawingType;
  final String? drawingNo;
  final String? modifiedDate;
  final String? contractId;
  final String? contractShortName;

  bool get isValid => designId.isNotEmpty;

  factory DesignDrawingItem.fromJson(Map<String, dynamic> json) {
    return DesignDrawingItem(
      designId: _n(json['design_id']) ?? '',
      designSeqId: _n(json['design_seq_id']),
      structureType: _n(json['structure_type_fk']),
      structureId: _n(json['structure_id_fk'] ?? json['structure_name']),
      title: _n(json['drawing_title']),
      drawingType: _n(json['drawing_type_fk']),
      drawingNo: _n(
        json['mrvc_drawing_no'] ??
            json['drawing_no'] ??
            json['contractor_drawing_no'],
      ),
      modifiedDate: _n(json['modified_date']),
      contractId: _n(json['contract_id_fk']),
      contractShortName: _n(json['contract_short_name']),
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

class DesignUploadItem {
  const DesignUploadItem({
    this.designDataId,
    this.uploadedFile,
    this.status,
    this.remarks,
    this.uploadedBy,
    this.uploadedOn,
  });

  final String? designDataId;
  final String? uploadedFile;
  final String? status;
  final String? remarks;
  final String? uploadedBy;
  final String? uploadedOn;

  factory DesignUploadItem.fromJson(Map<String, dynamic> json) {
    return DesignUploadItem(
      designDataId: DesignDrawingItem._n(json['design_data_id']),
      uploadedFile: DesignDrawingItem._n(json['uploaded_file']),
      status: DesignDrawingItem._n(json['status']),
      remarks: DesignDrawingItem._n(json['remarks']),
      uploadedBy: DesignDrawingItem._n(json['uploaded_by_user_id_fk']),
      uploadedOn: DesignDrawingItem._n(json['uploaded_on']),
    );
  }
}

class DesignDrawingListResult {
  const DesignDrawingListResult({
    required this.items,
    required this.totalRecords,
    required this.filteredRecords,
  });

  final List<DesignDrawingItem> items;
  final int totalRecords;
  final int filteredRecords;
}

class DesignDrawingFilterQuery {
  const DesignDrawingFilterQuery({
    this.contractId,
    this.structureType,
    this.drawingType,
    this.search = '',
    this.page = 0,
    this.pageSize = 10,
  });

  final String? contractId;
  final String? structureType;
  final String? drawingType;
  final String search;
  final int page;
  final int pageSize;

  Map<String, dynamic> get filterParams => <String, dynamic>{
        'contract_id_fk': contractId ?? '',
        'structure_type_fk': structureType ?? '',
        'drawing_type_fk': drawingType ?? '',
      };

  Map<String, dynamic> get listParams {
    final Map<String, dynamic> params = <String, dynamic>{
      ...filterParams,
      'sEcho': 1,
      'iColumns': 8,
      'sColumns': ',,,,,,,',
      'iDisplayStart': page * pageSize,
      'iDisplayLength': pageSize,
      'sSearch': search,
      'bRegex': false,
    };
    for (int i = 0; i < 8; i++) {
      params['mDataProp_$i'] = 'function';
      params['sSearch_$i'] = '';
      params['bRegex_$i'] = false;
      params['bSearchable_$i'] = true;
    }
    return params;
  }

  @override
  bool operator ==(Object other) {
    return other is DesignDrawingFilterQuery &&
        other.contractId == contractId &&
        other.structureType == structureType &&
        other.drawingType == drawingType &&
        other.search == search &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
        contractId,
        structureType,
        drawingType,
        search,
        page,
        pageSize,
      );
}
