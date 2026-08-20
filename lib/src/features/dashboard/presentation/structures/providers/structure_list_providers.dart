import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/project_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_list_item.dart';

class StructureListQuery {
  const StructureListQuery({
    this.projectId,
    this.search = '',
    this.page = 0,
    this.pageSize = 10,
  });

  final String? projectId;
  final String search;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is StructureListQuery &&
        other.projectId == projectId &&
        other.search == search &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(projectId, search, page, pageSize);
}

final structureProjectFilterProvider =
    FutureProvider.autoDispose<List<DropdownOption>>((ref) async {
  final result =
      await ref.watch(projectRepositoryProvider).getStructureProjectFilter();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final structureListProvider = FutureProvider.autoDispose
    .family<StructureListResult, StructureListQuery>((ref, query) async {
  final result = await ref.watch(projectRepositoryProvider).getStructureList(
        projectId: query.projectId,
        search: query.search,
        start: query.page * query.pageSize,
        length: query.pageSize,
      );
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (StructureListResult data) => data,
  );
});
