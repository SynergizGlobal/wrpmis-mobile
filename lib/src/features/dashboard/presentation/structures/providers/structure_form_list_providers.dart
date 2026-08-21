import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/project_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_form_list_item.dart';

class StructureFormListQuery {
  const StructureFormListQuery({
    this.contractId,
    this.structureType,
    this.workStatus,
    this.search = '',
    this.page = 0,
    this.pageSize = 10,
  });

  final String? contractId;
  final String? structureType;
  final String? workStatus;
  final String search;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is StructureFormListQuery &&
        other.contractId == contractId &&
        other.structureType == structureType &&
        other.workStatus == workStatus &&
        other.search == search &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
        contractId,
        structureType,
        workStatus,
        search,
        page,
        pageSize,
      );
}

final structureFormContractFilterProvider =
    FutureProvider.autoDispose<List<DropdownOption>>((ref) async {
  final result = await ref
      .watch(projectRepositoryProvider)
      .getStructureFormContractFilter();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final structureFormTypeFilterProvider =
    FutureProvider.autoDispose<List<DropdownOption>>((ref) async {
  final result =
      await ref.watch(projectRepositoryProvider).getStructureFormTypeFilter();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final structureFormWorkStatusFilterProvider =
    FutureProvider.autoDispose<List<DropdownOption>>((ref) async {
  final result = await ref
      .watch(projectRepositoryProvider)
      .getStructureFormWorkStatusFilter();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final structureFormListProvider = FutureProvider.autoDispose
    .family<StructureFormListResult, StructureFormListQuery>((ref, query) async {
  final result =
      await ref.watch(projectRepositoryProvider).getStructureFormList(
            contractId: query.contractId,
            structureType: query.structureType,
            workStatus: query.workStatus,
            search: query.search,
            start: query.page * query.pageSize,
            length: query.pageSize,
          );
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (StructureFormListResult data) => data,
  );
});
