class ValidateActivityItem {
  const ValidateActivityItem({
    required this.progressId,
    this.taskCode,
    this.structure,
    this.component,
    this.element,
    this.activityName,
    this.unit,
    this.scope,
    this.priorActivity,
    this.priorComponent,
    this.priorStructure,
    this.actualForDay,
    this.updatedScope,
    this.postActivity,
    this.postComponent,
    this.postStructure,
    this.reporting,
    this.updatedOn,
    this.approvedOn,
    this.rejectedOn,
    this.contractId,
  });

  final String progressId;
  final String? taskCode;
  final String? structure;
  final String? component;
  final String? element;
  final String? activityName;
  final String? unit;
  final String? scope;
  final String? priorActivity;
  final String? priorComponent;
  final String? priorStructure;
  final String? actualForDay;
  final String? updatedScope;
  final String? postActivity;
  final String? postComponent;
  final String? postStructure;
  final String? reporting;
  final String? updatedOn;
  final String? approvedOn;
  final String? rejectedOn;
  final String? contractId;

  String get actualUpdatedLabel {
    final String actual = actualForDay ?? '-';
    final String updated = updatedScope ?? '-';
    return '$actual / $updated';
  }

  factory ValidateActivityItem.fromJson(Map<String, dynamic> json) {
    final String updatedBy = _n(json['updated_by']) ?? '';
    final String progressDate = _n(json['progress_date']) ?? '';
    final String reporting = <String>[updatedBy, progressDate]
        .where((String value) => value.isNotEmpty)
        .join('\n');
    return ValidateActivityItem(
      progressId: _n(json['progress_id']) ?? '',
      taskCode: _n(json['p6_task_code']),
      structure: _n(json['structure']),
      component: _n(json['component']),
      element: _n(json['component_id']),
      activityName: _n(json['activity_name']),
      unit: _n(json['unit']),
      scope: _n(json['total_scope']),
      priorActivity: _n(json['cumulative_completed']),
      priorComponent: _n(json['component_per_prior']),
      priorStructure: _n(json['structure_per_prior']),
      actualForDay: _n(json['actual_for_the_day']),
      updatedScope: _n(json['updated_scope']),
      postActivity: _n(json['activity_per_post']) ??
          _n(json['activity_level']) ??
          _added(json['cumulative_completed'], json['actual_for_the_day']),
      postComponent: _n(json['component_per_post']),
      postStructure: _n(json['structure_per_post']),
      reporting: reporting.isEmpty ? null : reporting,
      updatedOn: _n(json['updated_on']),
      approvedOn: _n(json['approved_on']),
      rejectedOn: _n(json['rejected_on']),
      contractId: _n(json['contract_id_fk']),
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

  static String? _added(dynamic left, dynamic right) {
    final double? a = double.tryParse(_n(left) ?? '');
    final double? b = double.tryParse(_n(right) ?? '');
    if (a == null || b == null) {
      return _n(left) ?? _n(right);
    }
    return (a + b).toStringAsFixed(1);
  }
}

class ValidateDataQuery {
  const ValidateDataQuery({
    required this.status,
    this.contractId,
    this.structure,
    this.updatedBy,
  });

  final String status;
  final String? contractId;
  final String? structure;
  final String? updatedBy;

  Map<String, dynamic> get params => <String, dynamic>{
        'contract_id_fk': contractId ?? '',
        'structure': structure ?? '',
        'updated_by_user_id_fk': updatedBy ?? '',
        'approval_status_fk': status,
      };

  @override
  bool operator ==(Object other) {
    return other is ValidateDataQuery &&
        other.status == status &&
        other.contractId == contractId &&
        other.structure == structure &&
        other.updatedBy == updatedBy;
  }

  @override
  int get hashCode => Object.hash(status, contractId, structure, updatedBy);
}
