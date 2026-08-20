/// Dropdown data for Add/Edit Project form (from /api/v1/projects/add-form-data).
class ProjectFormData {
  const ProjectFormData({
    this.projectTypes = const [],
    this.railwayZones = const [],
    this.divisions = const [],
    this.sections = const [],
    this.years = const [],
    this.fileTypes = const [],
  });

  final List<DropdownOption> projectTypes;
  final List<DropdownOption> railwayZones;
  final List<DropdownOption> divisions;
  final List<DropdownOption> sections;
  final List<DropdownOption> years;
  final List<DropdownOption> fileTypes;

  factory ProjectFormData.fromJson(Map<String, dynamic> json) {
    return ProjectFormData(
      projectTypes: _parseOptions(
        json['projectTypes'],
        idKey: 'project_type_id',
        nameKey: 'project_type_name',
      ),
      railwayZones: _parseOptions(
        json['railwayZones'],
        idKey: 'railway_id',
        nameKey: 'railway_name',
      ),
      divisions: _parseOptions(
        json['divisions'],
        idKey: 'division_id',
        nameKey: 'division_name',
      ),
      sections: _parseSectionOptions(json['sections']),
      years: _parseOptions(
        json['yearList'] ?? json['years'] ?? json['financialYears'],
        idKey: 'financial_year',
        nameKey: 'financial_year',
      ),
      fileTypes: _parseOptions(
        json['projectFileTypes'] ?? json['fileTypes'],
        idKey: 'file_type_id',
        nameKey: 'file_type_name',
      ),
    );
  }

  List<DropdownOption> sectionsForDivision(String? divisionId) {
    if (divisionId == null || divisionId.isEmpty) {
      return sections;
    }
    final List<DropdownOption> filtered = sections
        .where((DropdownOption o) => o.extra == divisionId)
        .toList();
    return filtered.isEmpty ? sections : filtered;
  }

  static List<DropdownOption> _parseSectionOptions(dynamic list) {
    if (list is! List) return const [];
    return list.whereType<Map>().map((entry) {
      final map = entry.map((k, v) => MapEntry(k.toString(), v));
      return DropdownOption(
        id: (map['section_id'] ?? map['id'] ?? '').toString(),
        name: (map['section_name'] ?? map['name'] ?? '').toString(),
        extra: (map['division_id'] ?? '').toString(),
      );
    }).toList();
  }

  static List<DropdownOption> _parseOptions(
    dynamic list, {
    required String idKey,
    required String nameKey,
  }) {
    if (list is! List) return const [];
    return list.whereType<Map>().map((entry) {
      final map = entry.map((k, v) => MapEntry(k.toString(), v));
      final id = (map[idKey] ?? map['id'] ?? '').toString();
      final name = (map[nameKey] ?? map['name'] ?? id).toString();
      if (id.isEmpty && name.isEmpty) {
        return null;
      }
      return DropdownOption(id: id.isEmpty ? name : id, name: name);
    }).whereType<DropdownOption>().toList();
  }
}

class DropdownOption {
  const DropdownOption({
    required this.id,
    required this.name,
    this.extra,
  });

  final String id;
  final String name;
  final String? extra;

  @override
  String toString() => name;
}
