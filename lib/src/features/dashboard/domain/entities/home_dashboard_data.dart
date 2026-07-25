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
  const HomeProjectType({required this.name, required this.cumulativeCount});

  final String name;
  final int cumulativeCount;
}

class HomeDashboardData {
  const HomeDashboardData({required this.overview, required this.projectTypes});

  final HomeOverview overview;
  final List<HomeProjectType> projectTypes;
}
