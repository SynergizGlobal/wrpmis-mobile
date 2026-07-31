import 'package:flutter/material.dart';

/// Western Railways Reports menu items (web reference).
class ReportMenuItem {
  const ReportMenuItem({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;

  static const List<ReportMenuItem> catalog = <ReportMenuItem>[
    ReportMenuItem(
      id: 'contracts',
      title: 'Contracts',
      icon: Icons.description_outlined,
    ),
    ReportMenuItem(
      id: 'contract_wise_activities',
      title: 'Contract-wise Activities',
      icon: Icons.playlist_add_check_outlined,
    ),
    ReportMenuItem(
      id: 'progress_report',
      title: 'Progress Report',
      icon: Icons.bar_chart_rounded,
    ),
    ReportMenuItem(
      id: 'issues',
      title: 'Issues',
      icon: Icons.report_problem_outlined,
    ),
    ReportMenuItem(
      id: 'land_acquisition',
      title: 'Land Acquisition',
      icon: Icons.landscape_outlined,
    ),
    ReportMenuItem(
      id: 'utility_shifting',
      title: 'Utility Shifting',
      icon: Icons.electrical_services_outlined,
    ),
  ];
}
