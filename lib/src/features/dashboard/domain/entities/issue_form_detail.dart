import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/issue_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

class IssueHistoryRow {
  const IssueHistoryRow({
    this.updatedBy,
    this.updateDate,
    this.remarks,
  });

  final String? updatedBy;
  final String? updateDate;
  final String? remarks;
}

class IssueFormDetail {
  const IssueFormDetail({
    this.issueId,
    this.projectId,
    this.projectLabel,
    this.contractId,
    this.contractLabel,
    this.contractType,
    this.structure,
    this.component,
    this.category,
    this.shortDescription,
    this.priority,
    this.description,
    this.deadline,
    this.location,
    this.responsibleOrganization,
    this.responsiblePersonName,
    this.responsiblePersonDesignation,
    this.reportedBy,
    this.status,
    this.remarks,
    this.history = const <IssueHistoryRow>[],
    this.projects = const <DropdownOption>[],
    this.priorities = const <DropdownOption>[],
    this.organizations = const <DropdownOption>[],
    this.fileTypes = const <DropdownOption>[],
  });

  final String? issueId;
  final String? projectId;
  final String? projectLabel;
  final String? contractId;
  final String? contractLabel;
  final String? contractType;
  final String? structure;
  final String? component;
  final String? category;
  final String? shortDescription;
  final String? priority;
  final String? description;
  final String? deadline;
  final String? location;
  final String? responsibleOrganization;
  final String? responsiblePersonName;
  final String? responsiblePersonDesignation;
  final String? reportedBy;
  final String? status;
  final String? remarks;
  final List<IssueHistoryRow> history;
  final List<DropdownOption> projects;
  final List<DropdownOption> priorities;
  final List<DropdownOption> organizations;
  final List<DropdownOption> fileTypes;

  static const List<DropdownOption> fallbackPriorities = <DropdownOption>[
    DropdownOption(id: 'High', name: 'High'),
    DropdownOption(id: 'Medium', name: 'Medium'),
    DropdownOption(id: 'Low', name: 'Low'),
  ];

  static const List<DropdownOption> fallbackOrganizations = <DropdownOption>[
    DropdownOption(id: 'Western Railway', name: 'Western Railway'),
    DropdownOption(id: 'Contractor', name: 'Contractor'),
    DropdownOption(id: 'Other Organization', name: 'Other Organization'),
  ];

  static const List<DropdownOption> fallbackFileTypes = <DropdownOption>[
    DropdownOption(id: 'Document', name: 'Document'),
    DropdownOption(id: 'Drawing', name: 'Drawing'),
    DropdownOption(id: 'Photograph', name: 'Photograph'),
    DropdownOption(id: 'Report', name: 'Report'),
    DropdownOption(id: 'Other', name: 'Other'),
  ];

  IssueFormDetail mergeSeed(IssueListItem? seed) {
    if (seed == null) {
      return this;
    }
    return IssueFormDetail(
      issueId: issueId ?? seed.issueId,
      projectId: projectId ?? seed.projectId,
      projectLabel: projectLabel ?? seed.projectName,
      contractId: contractId ?? seed.contractId,
      contractLabel: contractLabel ?? seed.contractDisplay,
      contractType: contractType ?? seed.contractType,
      structure: structure ?? seed.structure,
      component: component ?? seed.component,
      category: category ?? seed.category,
      shortDescription: shortDescription ?? seed.shortDescription,
      priority: priority ?? seed.priority,
      description: description ?? seed.description,
      deadline: deadline ?? seed.deadline,
      location: location ?? seed.location,
      responsibleOrganization:
          responsibleOrganization ?? seed.responsibleOrganization,
      responsiblePersonName: responsiblePersonName ?? seed.responsiblePerson,
      responsiblePersonDesignation:
          responsiblePersonDesignation ?? seed.responsiblePersonDesignation,
      reportedBy: reportedBy ?? seed.reportedBy,
      status: status ?? seed.status,
      remarks: remarks ?? seed.remarks,
      history: history,
      projects: projects,
      priorities: priorities.isEmpty ? fallbackPriorities : priorities,
      organizations:
          organizations.isEmpty ? fallbackOrganizations : organizations,
      fileTypes: fileTypes.isEmpty ? fallbackFileTypes : fileTypes,
    );
  }

  IssueFormDetail withProjects(List<DropdownOption> next) {
    return IssueFormDetail(
      issueId: issueId,
      projectId: projectId,
      projectLabel: projectLabel,
      contractId: contractId,
      contractLabel: contractLabel,
      contractType: contractType,
      structure: structure,
      component: component,
      category: category,
      shortDescription: shortDescription,
      priority: priority,
      description: description,
      deadline: deadline,
      location: location,
      responsibleOrganization: responsibleOrganization,
      responsiblePersonName: responsiblePersonName,
      responsiblePersonDesignation: responsiblePersonDesignation,
      reportedBy: reportedBy,
      status: status,
      remarks: remarks,
      history: history,
      projects: next.isEmpty ? projects : next,
      priorities: priorities.isEmpty ? fallbackPriorities : priorities,
      organizations:
          organizations.isEmpty ? fallbackOrganizations : organizations,
      fileTypes: fileTypes.isEmpty ? fallbackFileTypes : fileTypes,
    );
  }
}
