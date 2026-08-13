import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_list_item.dart';

final projectListProvider =
    FutureProvider.autoDispose<List<ProjectListItem>>((ref) async {
  final DashboardRemoteDataSource remote =
      ref.watch(dashboardRemoteDataSourceProvider);
  final List<Map<String, dynamic>> rows = await remote.fetchProjects();

  final Map<String, ProjectListItem> byId = <String, ProjectListItem>{};
  for (final Map<String, dynamic> row in rows) {
    final ProjectListItem item = ProjectListItem.fromJson(row);
    if (item.projectId.isEmpty) {
      continue;
    }
    final ProjectListItem? existing = byId[item.projectId];
    byId[item.projectId] = existing == null ? item : existing.merge(item);
  }

  final List<ProjectListItem> items = byId.values.toList()
    ..sort(
      (ProjectListItem a, ProjectListItem b) =>
          a.projectId.compareTo(b.projectId),
    );
  return items;
});
