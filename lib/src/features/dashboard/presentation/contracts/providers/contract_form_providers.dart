import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/contract_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contract_form_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

final contractFormProvider = FutureProvider.autoDispose
    .family<ContractFormDetail, String>((ref, contractId) async {
  final result = await ref
      .watch(contractRepositoryProvider)
      .getContractForm(contractId: contractId.isEmpty ? null : contractId);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (ContractFormDetail data) => data,
  );
});

final contractHodListProvider =
    FutureProvider.autoDispose<List<DropdownOption>>((ref) async {
  final result = await ref.watch(contractRepositoryProvider).getHodList();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final contractDyHodListProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, String>((ref, hodUserId) async {
  if (hodUserId.isEmpty) {
    return const <DropdownOption>[];
  }
  final result =
      await ref.watch(contractRepositoryProvider).getDyHodList(hodUserId);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final contractExecutivesProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, String>((ref, departmentFk) async {
  if (departmentFk.isEmpty) {
    return const <DropdownOption>[];
  }
  final result =
      await ref.watch(contractRepositoryProvider).getExecutives(departmentFk);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final contractFormWorkStatusProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, String>((ref, awarded) async {
  final result =
      await ref.watch(contractRepositoryProvider).getFormWorkStatuses(awarded);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});
