import 'package:flutter/material.dart';

/// Western Railways Update Forms modules (web menu reference).
class UpdateFormModule {
  const UpdateFormModule({
    required this.id,
    required this.title,
    required this.icon,
    this.assetIcon,
  });

  final String id;
  final String title;
  final IconData icon;
  final String? assetIcon;

  static const List<UpdateFormModule> catalog = <UpdateFormModule>[
    UpdateFormModule(
      id: 'projects',
      title: 'Projects',
      icon: Icons.folder_special_outlined,
      assetIcon: 'assets/update_forms_icons/projects.png',
    ),
    UpdateFormModule(
      id: 'works',
      title: 'Works',
      icon: Icons.engineering_outlined,
      assetIcon: 'assets/update_forms_icons/works.png',
    ),
    UpdateFormModule(
      id: 'contracts_tenders',
      title: 'Contracts/Tenders',
      icon: Icons.description_outlined,
      assetIcon: 'assets/update_forms_icons/contracts_tenders.png',
    ),
    UpdateFormModule(
      id: 'execution_monitoring',
      title: 'Execution & Monitoring',
      icon: Icons.timeline_outlined,
      assetIcon: 'assets/update_forms_icons/execution_monitoring.png',
    ),
    UpdateFormModule(
      id: 'design_drawing',
      title: 'Design & Drawing',
      icon: Icons.architecture_outlined,
      assetIcon: 'assets/update_forms_icons/design_drawing.png',
    ),
    UpdateFormModule(
      id: 'issues',
      title: 'Issues',
      icon: Icons.report_problem_outlined,
      assetIcon: 'assets/update_forms_icons/issues.png',
    ),
    UpdateFormModule(
      id: 'land_acquisition',
      title: 'Land Acquisition',
      icon: Icons.landscape_outlined,
      assetIcon: 'assets/update_forms_icons/land_acquisition.png',
    ),
    UpdateFormModule(
      id: 'utility_shifting',
      title: 'Utility Shifting',
      icon: Icons.electrical_services_outlined,
      assetIcon: 'assets/update_forms_icons/utility_shifting.png',
    ),
    UpdateFormModule(
      id: 'validate_data',
      title: 'Validate Data',
      icon: Icons.verified_outlined,
      assetIcon: 'assets/update_forms_icons/validate_data.png',
    ),
    UpdateFormModule(
      id: 'alerts',
      title: 'Alerts',
      icon: Icons.notifications_active_outlined,
    ),
  ];
}
