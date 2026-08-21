/// One Structure Id / Structure Name row under a structure type.
class StructureNameRow {
  const StructureNameRow({
    this.structureId = '',
    this.structure = '',
    this.structureName = '',
  });

  final String structureId;
  final String structure;
  final String structureName;

  StructureNameRow copyWith({
    String? structureId,
    String? structure,
    String? structureName,
  }) {
    return StructureNameRow(
      structureId: structureId ?? this.structureId,
      structure: structure ?? this.structure,
      structureName: structureName ?? this.structureName,
    );
  }
}

/// Group of structure names under one structure type.
class StructureTypeGroup {
  const StructureTypeGroup({
    this.structureType = '',
    this.rows = const <StructureNameRow>[],
  });

  final String structureType;
  final List<StructureNameRow> rows;

  int get count => rows.length;

  StructureTypeGroup copyWith({
    String? structureType,
    List<StructureNameRow>? rows,
  }) {
    return StructureTypeGroup(
      structureType: structureType ?? this.structureType,
      rows: rows ?? this.rows,
    );
  }
}

/// Full Add/Update Structure form state (project + type groups).
/// Loaded for edit via POST `/get-structure`.
class StructureDetail {
  const StructureDetail({
    required this.structureId,
    this.projectIdFk,
    this.projectLabel,
    this.groups = const <StructureTypeGroup>[],
  });

  /// List-row id used when opening edit (`structure_id` from getStructureList).
  final String structureId;
  final String? projectIdFk;
  final String? projectLabel;
  final List<StructureTypeGroup> groups;

  factory StructureDetail.empty() => const StructureDetail(structureId: '');

  factory StructureDetail.fromJson(Map<String, dynamic> json) {
    final List<StructureTypeGroup> groups = <StructureTypeGroup>[];
    final dynamic rawGroups = json['groups'];
    if (rawGroups is List) {
      for (final dynamic g in rawGroups) {
        if (g is! Map) continue;
        final Map<String, dynamic> m =
            g.map((k, v) => MapEntry(k.toString(), v));
        final String type =
            (m['structure_type'] ?? m['structureType'] ?? '').toString();
        final List<StructureNameRow> rows = <StructureNameRow>[];
        final dynamic rawRows = m['rows'];
        if (rawRows is List) {
          for (final dynamic r in rawRows) {
            if (r is! Map) continue;
            final Map<String, dynamic> rm =
                r.map((k, v) => MapEntry(k.toString(), v));
            rows.add(
              StructureNameRow(
                structureId: (rm['structure_id'] ?? '').toString(),
                structure: (rm['structure'] ?? rm['structures'] ?? '').toString(),
                structureName:
                    (rm['structure_name'] ?? rm['structure_names'] ?? '')
                        .toString(),
              ),
            );
          }
        }
        groups.add(StructureTypeGroup(structureType: type, rows: rows));
      }
    }

    // Legacy single-row JSON fallback.
    if (groups.isEmpty) {
      final String? type = _n(json['structure_type_fk'] ?? json['structureTypeFk']);
      final String? name = _n(json['structure_name'] ?? json['structureName']);
      final String? structure = _n(json['structure'] ?? json['structures']);
      if (type != null || name != null || structure != null) {
        groups.add(
          StructureTypeGroup(
            structureType: type ?? '',
            rows: <StructureNameRow>[
              StructureNameRow(
                structureId:
                    (json['structure_id'] ?? json['structureId'] ?? '').toString(),
                structure: structure ?? '',
                structureName: name ?? '',
              ),
            ],
          ),
        );
      }
    }

    return StructureDetail(
      structureId:
          (json['structure_id'] ?? json['structureId'] ?? '').toString(),
      projectIdFk: _n(json['project_id_fk'] ?? json['projectIdFk']),
      projectLabel: _n(json['project_label'] ?? json['projectLabel']),
      groups: groups,
    );
  }

  /// Flat form payload matching web add/update-structure fields.
  Map<String, dynamic> toPayload() {
    final List<String> types = <String>[];
    final List<String> structures = <String>[];
    final List<String> names = <String>[];
    final List<String> ids = <String>[];

    for (final StructureTypeGroup group in groups) {
      final String type = group.structureType.trim();
      if (type.isEmpty) continue;
      for (final StructureNameRow row in group.rows) {
        final String structure = row.structure.trim();
        final String name = row.structureName.trim();
        if (structure.isEmpty && name.isEmpty) continue;
        types.add(type);
        structures.add(structure.isEmpty ? name : structure);
        names.add(name.isEmpty ? structure : name);
        ids.add(row.structureId);
      }
    }

    return <String, dynamic>{
      'project_id_fk': projectIdFk ?? '',
      'structure_type_fks': types,
      'structures': structures,
      'structure_names': names,
      'structure_ids': ids,
    };
  }

  static String? _n(dynamic v) {
    if (v == null) return null;
    final String t = v.toString().trim();
    return t.isEmpty || t.toLowerCase() == 'null' ? null : t;
  }
}
