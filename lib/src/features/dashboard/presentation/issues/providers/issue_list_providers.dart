import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/issue_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/issue_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

final issueContractFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, IssueFilterQuery>((ref, query) async {
  final result =
      await ref.watch(issueRepositoryProvider).getContractFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final issueHodFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, IssueFilterQuery>((ref, query) async {
  final result = await ref.watch(issueRepositoryProvider).getHodFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final issueDepartmentFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, IssueFilterQuery>((ref, query) async {
  final result =
      await ref.watch(issueRepositoryProvider).getDepartmentFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final issueCategoryFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, IssueFilterQuery>((ref, query) async {
  final result =
      await ref.watch(issueRepositoryProvider).getCategoryFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final issueStatusFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, IssueFilterQuery>((ref, query) async {
  final result =
      await ref.watch(issueRepositoryProvider).getStatusFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final issueListProvider = FutureProvider.autoDispose
    .family<IssueListResult, IssueFilterQuery>((ref, query) async {
  final result = await ref.watch(issueRepositoryProvider).getIssuesList(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (IssueListResult data) => data,
  );
});
