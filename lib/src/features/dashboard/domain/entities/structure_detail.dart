/// Single structure entity from GET /api/v1/structures/{structure_id}.
class StructureDetail {
  const StructureDetail({
    required this.structureId,
    this.projectIdFk,
    this.structureTypeFk,
    this.structureName,
    this.structure,
  });

  final String structureId;
  final String? projectIdFk;
  final String? structureTypeFk;
  final String? structureName;
  final String? structure;

  factory StructureDetail.fromJson(Map<String, dynamic> json) {
    return StructureDetail(
      structureId: (json['structure_id'] ?? json['structureId'] ?? '').toString(),
      projectIdFk: _n(json['project_id_fk'] ?? json['projectIdFk']),
      structureTypeFk: _n(json['structure_type_fk'] ?? json['structureTypeFk']),
      structureName: _n(json['structure_name'] ?? json['structureName']),
      structure: _n(json['structure'] ?? json['structures']),
    );
  }

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      if (structureId.isNotEmpty) 'structure_ids': [structureId],
      if (projectIdFk != null) 'project_id_fk': projectIdFk,
      if (structureTypeFk != null) 'structure_type_fks': [structureTypeFk],
      if (structureName != null) 'structure_names': [structureName],
      if (structure != null) 'structures': [structure],
    };
  }

  static String? _n(dynamic v) {
    if (v == null) return null;
    final t = v.toString().trim();
    return t.isEmpty || t.toLowerCase() == 'null' ? null : t;
  }
}
