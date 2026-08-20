import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

/// Dropdown data for Add/Edit Structure form (from /api/v1/structures/add-form-data).
class StructureFormData {
  const StructureFormData({
    this.projects = const [],
    this.works = const [],
    this.contracts = const [],
    this.structures = const [],
    this.departments = const [],
    this.responsiblePeople = const [],
    this.workStatus = const [],
    this.units = const [],
    this.fileTypes = const [],
  });

  final List<DropdownOption> projects;
  final List<DropdownOption> works;
  final List<DropdownOption> contracts;
  final List<DropdownOption> structures;
  final List<DropdownOption> departments;
  final List<DropdownOption> responsiblePeople;
  final List<DropdownOption> workStatus;
  final List<DropdownOption> units;
  final List<DropdownOption> fileTypes;

  factory StructureFormData.fromJson(Map<String, dynamic> json) {
    return StructureFormData(
      projects: _opts(json['projectsList'], 'project_id', 'project_name'),
      works: _opts(json['worksList'], 'work_id', 'work_name'),
      contracts: _opts(json['contractsList'], 'contract_id', 'contract_name'),
      structures:
          _opts(json['structuresList'], 'structure_id', 'structure_name'),
      departments:
          _opts(json['departmentsList'], 'department_id', 'department_name'),
      responsiblePeople: _opts(
        json['responsiblePeopleList'],
        'person_id',
        'person_name',
      ),
      workStatus:
          _opts(json['workStatusList'], 'status_id', 'status_name'),
      units: _opts(json['unitsList'], 'unit_id', 'unit_name'),
      fileTypes:
          _opts(json['fileType'] ?? json['fileTypes'], 'file_type_id', 'file_type_name'),
    );
  }

  static List<DropdownOption> _opts(
    dynamic list,
    String idKey,
    String nameKey,
  ) {
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) {
      final m = e.map((k, v) => MapEntry(k.toString(), v));
      return DropdownOption(
        id: (m[idKey] ?? m['id'] ?? '').toString(),
        name: (m[nameKey] ?? m['name'] ?? '').toString(),
      );
    }).toList();
  }
}
