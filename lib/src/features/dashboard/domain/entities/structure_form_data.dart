import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

/// Dropdown data for Add/Edit Structure form.
class StructureFormData {
  const StructureFormData({
    this.projects = const [],
    this.structureTypes = const [],
  });

  final List<DropdownOption> projects;
  final List<DropdownOption> structureTypes;

  factory StructureFormData.fromJson(Map<String, dynamic> json) {
    return StructureFormData(
      projects: _opts(
        json['projectsList'] ?? json['projects'],
        'project_id',
        'project_name',
        altIdKeys: const <String>['project_id_fk', 'id'],
        altNameKeys: const <String>['projectName', 'name'],
      ),
      structureTypes: _opts(
        json['structuresList'] ??
            json['structureTypes'] ??
            json['structure_types'],
        'structure_type',
        'structure_type',
        altIdKeys: const <String>[
          'structure_type_fk',
          'structure_type_name',
          'id',
        ],
        altNameKeys: const <String>[
          'structure_type_name',
          'structure_type_fk',
          'name',
        ],
      ),
    );
  }

  static List<DropdownOption> _opts(
    dynamic list,
    String idKey,
    String nameKey, {
    List<String> altIdKeys = const <String>[],
    List<String> altNameKeys = const <String>[],
  }) {
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) {
      final Map<String, dynamic> m =
          e.map((k, v) => MapEntry(k.toString(), v));
      String id = (m[idKey] ?? '').toString();
      String name = (m[nameKey] ?? '').toString();
      for (final String k in altIdKeys) {
        if (id.isEmpty) id = (m[k] ?? '').toString();
      }
      for (final String k in altNameKeys) {
        if (name.isEmpty) name = (m[k] ?? '').toString();
      }
      if (id.isEmpty) id = name;
      if (name.isEmpty) name = id;
      return DropdownOption(id: id, name: name);
    }).where((DropdownOption o) => o.id.isNotEmpty).toList();
  }
}
