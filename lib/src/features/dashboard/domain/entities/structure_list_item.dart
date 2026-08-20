/// One row from the web Structure list (`/ajax/getStructureList`).
class StructureListItem {
  const StructureListItem({
    required this.structureId,
    required this.projectId,
    this.projectName,
    this.structureSummary,
    this.status,
  });

  final String structureId;
  final String projectId;
  final String? projectName;
  final String? structureSummary;
  final String? status;

  /// Lines like `Ballast - 3` for display.
  List<String> get structureLines {
    final String raw = structureSummary?.trim() ?? '';
    if (raw.isEmpty) {
      return const <String>[];
    }
    return raw
        .split(',')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
  }

  factory StructureListItem.fromJson(Map<String, dynamic> json) {
    return StructureListItem(
      structureId: _s(json['structure_id'] ?? json['structureId']),
      projectId: _s(
        json['project_id_fk'] ?? json['project_id'] ?? json['projectId'],
      ),
      projectName: _n(json['project_name'] ?? json['projectName']),
      structureSummary: _n(
        json['structure_type_fk'] ??
            json['structure_type'] ??
            json['structures'],
      ),
      status: _n(json['status']),
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

class StructureListResult {
  const StructureListResult({
    required this.items,
    required this.totalRecords,
    required this.filteredRecords,
  });

  final List<StructureListItem> items;
  final int totalRecords;
  final int filteredRecords;
}
