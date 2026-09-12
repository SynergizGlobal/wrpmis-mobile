import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/issue_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/issue_form_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/issue_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

class IssueFormArgs {
  const IssueFormArgs({this.issueId, this.seed});

  final String? issueId;
  final IssueListItem? seed;

  @override
  bool operator ==(Object other) {
    return other is IssueFormArgs &&
        other.issueId == issueId &&
        other.seed?.issueId == seed?.issueId;
  }

  @override
  int get hashCode => Object.hash(issueId, seed?.issueId);
}

final issueFormProvider = FutureProvider.autoDispose
    .family<IssueFormDetail, IssueFormArgs>((ref, args) async {
  final result = await ref.watch(issueRepositoryProvider).getIssueForm(
        issueId: args.issueId,
        seed: args.seed,
      );
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (IssueFormDetail data) => data,
  );
});

final issueFormContractsProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, String>((ref, projectId) async {
  if (projectId.isEmpty) {
    return const <DropdownOption>[];
  }
  final result =
      await ref.watch(issueRepositoryProvider).getFormContracts(projectId);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final issueFormCategoriesProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, String>((ref, contractType) async {
  final result =
      await ref.watch(issueRepositoryProvider).getFormCategories(contractType);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final issueFormTitlesProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, String>((ref, category) async {
  final result =
      await ref.watch(issueRepositoryProvider).getFormTitles(category);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final issueFormStructuresProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, String>((ref, contractId) async {
  if (contractId.isEmpty) {
    return const <DropdownOption>[];
  }
  final result =
      await ref.watch(issueRepositoryProvider).getFormStructures(contractId);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

class IssueComponentQuery {
  const IssueComponentQuery({
    required this.contractId,
    required this.structure,
  });

  final String contractId;
  final String structure;

  @override
  bool operator ==(Object other) {
    return other is IssueComponentQuery &&
        other.contractId == contractId &&
        other.structure == structure;
  }

  @override
  int get hashCode => Object.hash(contractId, structure);
}

final issueFormComponentsProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, IssueComponentQuery>((ref, query) async {
  if (query.contractId.isEmpty) {
    return const <DropdownOption>[];
  }
  final result = await ref.watch(issueRepositoryProvider).getFormComponents(
        contractId: query.contractId,
        structure: query.structure,
      );
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final issueFormStatusesProvider =
    FutureProvider.autoDispose<List<DropdownOption>>((ref) async {
  final result = await ref.watch(issueRepositoryProvider).getFormStatuses();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final issueFormResponsibleProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, String>((ref, departmentName) async {
  final result = await ref
      .watch(issueRepositoryProvider)
      .getResponsiblePersons(departmentName);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final issueFormLaDetailsProvider =
    FutureProvider.autoDispose<List<DropdownOption>>((ref) async {
  final result = await ref.watch(issueRepositoryProvider).getLaDetails();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});
