/// Single project entity from GET /api/v1/projects/{project_id}.
class ProjectDetail {
  const ProjectDetail({
    required this.projectId,
    required this.projectName,
    this.projectStatus,
    this.planHeadNumber,
    this.financialYearFk,
    this.projectTypeIdFk,
    this.projectTypeName,
    this.railwayZone,
    this.divisionId,
    this.division,
    this.sectionId,
    this.sections,
    this.sanctionedAmount,
    this.sanctionedCommissioningDate,
    this.pbItemNo,
    this.actualCompletionCost,
    this.actualCompletionDate,
    this.proposedLength,
    this.benefits,
    this.remarks,
    this.commissionedLengths = const [],
    this.costRows = const [],
  });

  final String projectId;
  final String projectName;
  final String? projectStatus;
  final String? planHeadNumber;
  final String? financialYearFk;
  final String? projectTypeIdFk;
  final String? projectTypeName;
  final String? railwayZone;
  final String? divisionId;
  final String? division;
  final String? sectionId;
  final String? sections;
  final String? sanctionedAmount;
  final String? sanctionedCommissioningDate;
  final String? pbItemNo;
  final String? actualCompletionCost;
  final String? actualCompletionDate;
  final String? proposedLength;
  final String? benefits;
  final String? remarks;
  final List<CommissionedLengthRow> commissionedLengths;
  final List<ProjectCostRow> costRows;

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    return ProjectDetail(
      projectId: _s(json['project_id'] ?? json['projectId']),
      projectName: _s(json['project_name'] ?? json['projectName']),
      projectStatus: _n(json['project_status'] ?? json['projectStatus']),
      planHeadNumber: _n(json['plan_head_number'] ?? json['planHeadNumber']),
      financialYearFk: _n(
        json['financial_year_fk'] ??
            json['financialYearFk'] ??
            json['sanctioned_year'] ??
            json['sanctioned_year_fk'],
      ),
      projectTypeIdFk: _n(
        json['project_type_id_fk'] ??
            json['projectTypeIdFk'] ??
            json['project_type_id'] ??
            json['projectTypeId'],
      ),
      projectTypeName:
          _n(json['project_type_name'] ?? json['projectTypeName']),
      railwayZone: _n(
        json['railway_zone'] ?? json['railwayZone'] ?? json['railway_id'],
      ),
      divisionId: _n(json['division_id'] ?? json['divisionId']),
      division: _n(json['division'] ?? json['division_name']),
      sectionId: _n(json['section_id'] ?? json['sectionId']),
      sections: _n(json['sections'] ?? json['section_name']),
      sanctionedAmount: _n(
        json['sanctioned_amount'] ?? json['sanctionedAmount'],
      ),
      sanctionedCommissioningDate: _n(
        json['sanctioned_commissioning_date'] ??
            json['sanctionedCommissioningDate'],
      ),
      pbItemNo: _n(
        json['pb_item_no'] ??
            json['pb_item_number'] ??
            json['pink_book_item_number'],
      ),
      actualCompletionCost: _n(
        json['actual_completion_cost'] ?? json['actualCompletionCost'],
      ),
      actualCompletionDate: _n(
        json['actual_completion_date'] ?? json['actualCompletionDate'],
      ),
      proposedLength: _n(json['proposed_length'] ?? json['proposedLength']),
      benefits: _n(json['benefits']),
      remarks: _n(json['remarks']),
      commissionedLengths: _parseCommissioned(json),
      costRows: _parseCosts(json),
    );
  }

  static List<CommissionedLengthRow> _parseCommissioned(
    Map<String, dynamic> json,
  ) {
    final dynamic list = json['projectCommissionedLengthList'];
    if (list is List && list.isNotEmpty) {
      return list.whereType<Map>().map((entry) {
        final map = entry.map((k, v) => MapEntry(k.toString(), v));
        return CommissionedLengthRow(
          id: _n(map['commissioned_id'] ?? map['id']),
          fromChainage: _n(
            map['commission_from_chainage'] ??
                map['commission_fromchainage'] ??
                map['from_chainage'],
          ),
          toChainage: _n(
            map['commission_to_chainage'] ??
                map['commission_tochainage'] ??
                map['to_chainage'],
          ),
          completedLength: _n(
            map['commission_completed_length'] ??
                map['commission_completedlength'] ??
                map['completed_length'] ??
                map['commissioned_length'],
          ),
        );
      }).toList();
    }
    return const [];
  }

  static List<ProjectCostRow> _parseCosts(Map<String, dynamic> json) {
    final dynamic pinkBooks = json['projectPinkBooks'];
    if (pinkBooks is List && pinkBooks.isNotEmpty) {
      return pinkBooks.whereType<Map>().map((entry) {
        final map = entry.map((k, v) => MapEntry(k.toString(), v));
        return ProjectCostRow(
          date: _n(map['entry_date'] ?? map['date'] ?? map['completion_date']),
          estimatedCompletionCost: _n(
            map['estimated_completion_cost'] ?? map['completion_cost'],
          ),
          revisedCompletionDate: _n(
            map['revised_completion_date'] ?? map['revised_target_date'],
          ),
        );
      }).toList();
    }

    final String? date = _n(json['entry_date'] ?? json['completion_date']);
    final String? cost = _n(
      json['estimated_completion_cost'] ?? json['latest_revised_cost'],
    );
    final String? revised = _n(
      json['revised_completion_date'] ?? json['revised_target_date'],
    );
    if (date != null || cost != null || revised != null) {
      return <ProjectCostRow>[
        ProjectCostRow(
          date: date,
          estimatedCompletionCost: cost,
          revisedCompletionDate: revised,
        ),
      ];
    }
    return const [];
  }

  static String _s(dynamic v) => (v ?? '').toString().trim();

  static String? _n(dynamic v) {
    if (v == null) return null;
    final String t = v.toString().trim();
    return t.isEmpty || t.toLowerCase() == 'null' ? null : t;
  }
}

class CommissionedLengthRow {
  const CommissionedLengthRow({
    this.id,
    this.fromChainage,
    this.toChainage,
    this.completedLength,
  });

  final String? id;
  final String? fromChainage;
  final String? toChainage;
  final String? completedLength;
}

class ProjectCostRow {
  const ProjectCostRow({
    this.date,
    this.estimatedCompletionCost,
    this.revisedCompletionDate,
  });

  final String? date;
  final String? estimatedCompletionCost;
  final String? revisedCompletionDate;
}
