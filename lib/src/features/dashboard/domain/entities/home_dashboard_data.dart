class HomeOverview {
  const HomeOverview({
    required this.projectsCount,
    required this.totalLength,
    required this.commissionedLength,
  });

  final int projectsCount;
  final double totalLength;
  final double commissionedLength;
}

class HomeProjectType {
  const HomeProjectType({
    required this.id,
    required this.name,
    required this.cumulativeCount,
  });

  final String id;
  final String name;
  final int cumulativeCount;
}

class HomeProjectItem {
  const HomeProjectItem({
    required this.projectId,
    required this.projectName,
    this.projectTypeId,
    this.projectTypeName,
    this.length,
    this.commissionedLength,
    this.physicalProgress,
    this.financialProgress,
  });

  final String projectId;
  final String projectName;
  final String? projectTypeId;
  final String? projectTypeName;
  final double? length;
  final double? commissionedLength;
  final double? physicalProgress;
  final double? financialProgress;

  factory HomeProjectItem.fromJson(Map<String, dynamic> json) {
    return HomeProjectItem(
      projectId: (json['project_id'] ?? json['projectId'] ?? '').toString(),
      projectName:
          (json['project_name'] ?? json['projectName'] ?? 'Untitled Project')
              .toString(),
      projectTypeId: _nullableString(
        json['project_type_id'] ?? json['projectTypeId'],
      ),
      projectTypeName: _nullableString(
        json['project_type_name'] ?? json['projectTypeName'],
      ),
      length: _nullableDouble(
        json['length'] ?? json['total_length'] ?? json['proposed_length'],
      ),
      commissionedLength: _nullableDouble(
        json['commissioned_length'] ??
            json['project_commissioned_total'] ??
            json['commission_completed_length'],
      ),
      physicalProgress: _nullableDouble(
        json['physical_progress'] ?? json['physicalProgress'],
      ),
      financialProgress: _nullableDouble(
        json['financial_progress'] ?? json['financialProgress'],
      ),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    final String text = value.toString().trim();
    return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value.toString().replaceAll(',', ''));
  }
}

class HomeDashboardData {
  const HomeDashboardData({
    required this.overview,
    required this.projectTypes,
    this.projects = const <HomeProjectItem>[],
  });

  final HomeOverview overview;
  final List<HomeProjectType> projectTypes;
  final List<HomeProjectItem> projects;

  /// Fixed WR home category order (matches web dashboard).
  static const List<({String id, String name})> canonicalCategories =
      <({String id, String name})>[
    (id: '1', name: 'New Line'),
    (id: '2', name: 'Doubling/Multitracking'),
    (id: '4', name: 'Gauge Conversion'),
    (id: '10', name: 'Station Redevelopment'),
  ];
}

class ProjectMajorItem {
  const ProjectMajorItem({
    required this.projectName,
    required this.item,
    required this.unit,
    required this.scope,
    required this.completed,
    required this.progressPercent,
    required this.tdc,
  });

  final String projectName;
  final String item;
  final String unit;
  final String scope;
  final String completed;
  final String progressPercent;
  final String tdc;
}

class ProjectDetailsData {
  const ProjectDetailsData({
    required this.projectTypeName,
    required this.projectNames,
    required this.items,
    required this.projectIdsByName,
  });

  final String projectTypeName;
  final List<String> projectNames;
  final List<ProjectMajorItem> items;
  final Map<String, String> projectIdsByName;
}
