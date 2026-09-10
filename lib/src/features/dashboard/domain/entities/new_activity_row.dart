/// One activity row from New Activities Update filters list.
class NewActivityRow {
  const NewActivityRow({
    required this.activityId,
    required this.taskCode,
    required this.activityName,
    required this.unit,
    required this.baselineStart,
    required this.baselineFinish,
    required this.expectedStart,
    required this.expectedFinish,
    required this.scope,
    required this.validationPending,
    required this.completed,
    required this.componentIdName,
    required this.dataDate,
  });

  final String activityId;
  final String taskCode;
  final String activityName;
  final String unit;
  final String baselineStart;
  final String baselineFinish;
  final String expectedStart;
  final String expectedFinish;
  final String scope;
  final String validationPending;
  final String completed;
  final String componentIdName;
  final String dataDate;

  factory NewActivityRow.fromJson(Map<String, dynamic> json) {
    String read(List<String> keys) {
      for (final String key in keys) {
        final dynamic value = json[key];
        if (value == null) continue;
        final String text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
      return '';
    }

    final String unit = read(<String>['unit_fk', 'unit']);
    final String activity = read(<String>[
      'strip_chart_activity_name',
      'activity_name',
    ]);
    return NewActivityRow(
      activityId: read(<String>['activity_id', 'strip_chart_activity_id']),
      taskCode: read(<String>['p6_task_code']),
      activityName: unit.isEmpty ? activity : '$activity ($unit)',
      unit: unit,
      baselineStart: read(<String>['planned_start', 'baseline_start', 'start']),
      baselineFinish:
          read(<String>['planned_finish', 'baseline_finish', 'finish']),
      expectedStart: read(<String>['start', 'planned_start']),
      expectedFinish: read(<String>['finish', 'planned_finish']),
      scope: read(<String>['scope', 'total_scope']),
      validationPending: read(<String>['validation_pending', 'pending']),
      completed: read(<String>['completed']),
      componentIdName: read(<String>['strip_chart_component_id_name']),
      dataDate: read(<String>['data_date']),
    );
  }
}

class NewActivitiesLatestInfo {
  const NewActivitiesLatestInfo({
    required this.structure,
    required this.component,
    required this.contractId,
    required this.structureType,
  });

  final String structure;
  final String component;
  final String contractId;
  final String structureType;

  String get displayLabel {
    if (structure.isEmpty && component.isEmpty) {
      return '';
    }
    if (structure.isEmpty) {
      return component;
    }
    if (component.isEmpty) {
      return structure;
    }
    return '$structure --> $component';
  }

  factory NewActivitiesLatestInfo.fromJson(Map<String, dynamic> json) {
    String read(List<String> keys) {
      for (final String key in keys) {
        final dynamic value = json[key];
        if (value == null) continue;
        final String text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
      return '';
    }

    return NewActivitiesLatestInfo(
      structure: read(<String>['structure', 'strip_chart_structure']),
      component: read(<String>['strip_chart_component', 'component']),
      contractId: read(<String>['contract_id_fk', 'contract_id']),
      structureType: read(<String>['structure_type_fk', 'structure_type']),
    );
  }
}
