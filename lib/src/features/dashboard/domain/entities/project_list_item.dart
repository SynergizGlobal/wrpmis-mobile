class ProjectListItem {
  const ProjectListItem({
    required this.projectId,
    required this.projectName,
    this.projectStatus,
    this.projectTypeName,
    this.railwayZone,
    this.planHeadNumber,
    this.sanctionedYear,
    this.sanctionedAmount,
    this.sanctionedCompletionDate,
    this.division,
    this.sections,
    this.remarks,
  });

  final String projectId;
  final String projectName;
  final String? projectStatus;
  final String? projectTypeName;
  final String? railwayZone;
  final String? planHeadNumber;
  final String? sanctionedYear;
  final String? sanctionedAmount;
  final String? sanctionedCompletionDate;
  final String? division;
  final String? sections;
  final String? remarks;

  factory ProjectListItem.fromJson(Map<String, dynamic> json) {
    return ProjectListItem(
      projectId: _string(json['project_id'] ?? json['projectId']),
      projectName: _string(
        json['project_name'] ?? json['projectName'],
        fallback: 'Untitled Project',
      ),
      projectStatus: _nullable(
        json['project_status'] ?? json['projectStatus'] ?? json['status'],
      ),
      projectTypeName: _nullable(
        json['project_type_name'] ?? json['projectTypeName'],
      ),
      railwayZone: _nullable(
        json['railway_zone'] ?? json['railwayZone'] ?? json['railway'],
      ),
      planHeadNumber: _nullable(
        json['plan_head_number'] ?? json['planHeadNumber'],
      ),
      sanctionedYear: _nullable(
        json['sanctioned_year'] ?? json['sanctionedYear'],
      ),
      sanctionedAmount: _nullable(
        json['sanctioned_amount'] ??
            json['sanctionedAmount'] ??
            json['sanctioned_estimated_cost'] ??
            json['latest_sanctioned_cost'] ??
            json['latest_revised_cost'],
      ),
      sanctionedCompletionDate: _nullable(
        json['sanctioned_commissioning_date'] ??
            json['sanctionedCommissioningDate'] ??
            json['completion_date'] ??
            json['revised_target_date'],
      ),
      division: _nullable(
        json['division'] ?? json['division_name'] ?? json['divisionName'],
      ),
      sections: _nullable(
        json['sections'] ?? json['section_name'] ?? json['sectionName'],
      ),
      remarks: _nullable(json['remarks'] ?? json['project_description']),
    );
  }

  ProjectListItem merge(ProjectListItem other) {
    return ProjectListItem(
      projectId: projectId.isNotEmpty ? projectId : other.projectId,
      projectName: projectName.isNotEmpty && projectName != 'Untitled Project'
          ? projectName
          : other.projectName,
      projectStatus: projectStatus ?? other.projectStatus,
      projectTypeName: projectTypeName ?? other.projectTypeName,
      railwayZone: railwayZone ?? other.railwayZone,
      planHeadNumber: planHeadNumber ?? other.planHeadNumber,
      sanctionedYear: sanctionedYear ?? other.sanctionedYear,
      sanctionedAmount: sanctionedAmount ?? other.sanctionedAmount,
      sanctionedCompletionDate:
          sanctionedCompletionDate ?? other.sanctionedCompletionDate,
      division: division ?? other.division,
      sections: sections ?? other.sections,
      remarks: remarks ?? other.remarks,
    );
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final String? text = _nullable(value);
    return text ?? fallback;
  }

  static String? _nullable(dynamic value) {
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
