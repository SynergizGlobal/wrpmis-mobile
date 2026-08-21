import 'package:flutter/material.dart';

/// Western Railways Update Forms modules (web menu reference).
class UpdateFormModule {
  const UpdateFormModule({
    required this.id,
    required this.title,
    required this.icon,
    this.assetIcon,
    this.subItems = const <UpdateFormSubItem>[],
  });

  final String id;
  final String title;
  final IconData icon;
  final String? assetIcon;
  final List<UpdateFormSubItem> subItems;

  static const List<UpdateFormModule> catalog = <UpdateFormModule>[
    UpdateFormModule(
      id: 'projects',
      title: 'Projects',
      icon: Icons.folder_special_outlined,
      assetIcon: 'assets/update_forms_icons/projects.png',
      subItems: <UpdateFormSubItem>[
        UpdateFormSubItem(
          id: 'add_project',
          title: 'Add Project',
          icon: Icons.add_box_outlined,
        ),
      ],
    ),
    UpdateFormModule(
      id: 'works',
      title: 'Works',
      icon: Icons.engineering_outlined,
      assetIcon: 'assets/update_forms_icons/works.png',
      subItems: <UpdateFormSubItem>[
        UpdateFormSubItem(
          id: 'structure',
          title: 'Structure',
          icon: Icons.account_tree_outlined,
        ),
        UpdateFormSubItem(
          id: 'update_structure',
          title: 'Update Structure',
          icon: Icons.edit_note_rounded,
        ),
        UpdateFormSubItem(
          id: 'technical_assistance',
          title: 'Technical Assistance',
          icon: Icons.support_agent_outlined,
        ),
      ],
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
      subItems: <UpdateFormSubItem>[
        UpdateFormSubItem(
          id: 'structure_p6_updates',
          title: 'Structure P6 Updates',
          icon: Icons.history_edu_outlined,
        ),
        UpdateFormSubItem(
          id: 'new_activities_update',
          title: 'New Activities Update',
          icon: Icons.playlist_add_check_outlined,
        ),
        UpdateFormSubItem(
          id: 'modify_actuals',
          title: 'Modify Actuals',
          icon: Icons.tune_outlined,
        ),
      ],
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

class UpdateFormSubItem {
  const UpdateFormSubItem({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;
}
