import 'package:flutter/material.dart';

/// Western Railways Modules menu items (web reference).
class AppModuleItem {
  const AppModuleItem({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;

  static const List<AppModuleItem> catalog = <AppModuleItem>[
    AppModuleItem(
      id: 'fortnight_meeting',
      title: 'Fortnight Meeting',
      icon: Icons.event_note_outlined,
    ),
    AppModuleItem(
      id: 'project_performance_appraisal',
      title: 'Project Performance Appraisal',
      icon: Icons.assessment_outlined,
    ),
    AppModuleItem(
      id: 'timeline_schedule',
      title: 'Timeline Schedule Module',
      icon: Icons.calendar_month_outlined,
    ),
    AppModuleItem(
      id: 'bg_insurance_dashboard',
      title: 'BG & Insurance Dashboard',
      icon: Icons.security_outlined,
    ),
    AppModuleItem(
      id: 'usage_analysis_dashboard',
      title: 'Usage Analysis Dashboard',
      icon: Icons.analytics_outlined,
    ),
    AppModuleItem(
      id: 'contractwise_physical_progress',
      title: 'Contractwise Physical Progress',
      icon: Icons.insights_outlined,
    ),
    AppModuleItem(
      id: 'component_wise_progress',
      title: 'Component Wise Progress',
      icon: Icons.pie_chart_outline_rounded,
    ),
    AppModuleItem(
      id: 'progress_table',
      title: 'Progress Table',
      icon: Icons.table_chart_outlined,
    ),
    AppModuleItem(
      id: 'contract_status',
      title: 'Contract Status',
      icon: Icons.assignment_turned_in_outlined,
    ),
    AppModuleItem(
      id: 'issues',
      title: 'Issues',
      icon: Icons.report_problem_outlined,
    ),
    AppModuleItem(
      id: 'structure_wise_shortfall',
      title: 'Structure wise Shortfall',
      icon: Icons.account_tree_outlined,
    ),
    AppModuleItem(
      id: 'dpr_updation_validation',
      title: 'DPR Updation & Validation Status',
      icon: Icons.fact_check_outlined,
    ),
    AppModuleItem(
      id: 'tdc_projections',
      title: 'TDC Projections',
      icon: Icons.trending_up_rounded,
    ),
    AppModuleItem(
      id: 'progress_review_meetings',
      title: 'Progress Review Meetings',
      icon: Icons.groups_outlined,
    ),
  ];
}
