import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/project_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/p6_data_history_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

class P6DataHistoryListQuery {
  const P6DataHistoryListQuery({
    this.contractId,
    this.uploadType,
    this.statusFk,
    this.search = '',
    this.page = 0,
    this.pageSize = 10,
  });

  final String? contractId;
  final String? uploadType;
  final String? statusFk;
  final String search;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is P6DataHistoryListQuery &&
        other.contractId == contractId &&
        other.uploadType == uploadType &&
        other.statusFk == statusFk &&
        other.search == search &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
        contractId,
        uploadType,
        statusFk,
        search,
        page,
        pageSize,
      );
}

final p6ContractFilterProvider =
    FutureProvider.autoDispose<List<DropdownOption>>((ref) async {
  final result =
      await ref.watch(projectRepositoryProvider).getP6ContractFilter();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final p6UploadTypeFilterProvider =
    FutureProvider.autoDispose<List<DropdownOption>>((ref) async {
  final result =
      await ref.watch(projectRepositoryProvider).getP6UploadTypeFilter();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final p6StatusFilterProvider =
    FutureProvider.autoDispose<List<DropdownOption>>((ref) async {
  final result =
      await ref.watch(projectRepositoryProvider).getP6StatusFilter();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final p6DataHistoryListProvider = FutureProvider.autoDispose
    .family<P6DataHistoryListResult, P6DataHistoryListQuery>((ref, query) async {
  final result =
      await ref.watch(projectRepositoryProvider).getP6DataHistoryList(
            contractId: query.contractId,
            uploadType: query.uploadType,
            statusFk: query.statusFk,
            search: query.search,
            start: query.page * query.pageSize,
            length: query.pageSize,
          );
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (P6DataHistoryListResult data) => data,
  );
});
