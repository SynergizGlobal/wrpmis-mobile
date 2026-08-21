/// One row from Structure Form list (`/ajax/getStructuresList`).
class StructureFormListItem {
  const StructureFormListItem({
    required this.structureId,
    this.projectId,
    this.structureType,
    this.structure,
    this.structureName,
    this.contractId,
    this.contractName,
    this.contractShortName,
    this.workStatus,
  });

  final String structureId;
  final String? projectId;
  final String? structureType;
  final String? structure;
  final String? structureName;
  final String? contractId;
  final String? contractName;
  final String? contractShortName;
  final String? workStatus;

  String get structureDisplay {
    final String name = (structureName ?? '').trim();
    if (name.isNotEmpty) return name;
    final String raw = (structure ?? '').trim();
    return raw.isEmpty ? '-' : raw;
  }

  String get contractDisplay {
    final String shortName = (contractShortName ?? '').trim();
    if (shortName.isNotEmpty) return shortName;
    final String name = (contractName ?? '').trim();
    return name.isEmpty ? '-' : name;
  }

  factory StructureFormListItem.fromJson(Map<String, dynamic> json) {
    return StructureFormListItem(
      structureId: _s(json['structure_id'] ?? json['structureId']),
      projectId: _n(json['project_id_fk'] ?? json['project_id'] ?? json['projectId']),
      structureType: _n(
        json['structure_type_fk'] ??
            json['structure_type'] ??
            json['structureType'],
      ),
      structure: _n(json['structure']),
      structureName: _n(json['structure_name'] ?? json['structureName']),
      contractId: _n(json['contract_id_fk'] ?? json['contract_id']),
      contractName: _n(json['contract_name'] ?? json['contractName']),
      contractShortName: _n(
        json['contract_short_name'] ?? json['contractShortName'],
      ),
      workStatus: _n(json['work_status_fk'] ?? json['work_status']),
    );
  }

  static String _s(dynamic v) => (v ?? '').toString().trim();

  static String? _n(dynamic v) {
    if (v == null) return null;
    final String t = v.toString().trim();
    return t.isEmpty || t.toLowerCase() == 'null' ? null : t;
  }
}

class StructureFormListResult {
  const StructureFormListResult({
    required this.items,
    required this.totalRecords,
    required this.filteredRecords,
  });

  final List<StructureFormListItem> items;
  final int totalRecords;
  final int filteredRecords;
}
