import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/contract_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contract_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

final contractHodFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, ContractFilterQuery>((ref, query) async {
  final result = await ref.watch(contractRepositoryProvider).getHodFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final contractDyHodFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, ContractFilterQuery>((ref, query) async {
  final result =
      await ref.watch(contractRepositoryProvider).getDyHodFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final contractContractorFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, ContractFilterQuery>((ref, query) async {
  final result =
      await ref.watch(contractRepositoryProvider).getContractorFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final contractStatusFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, ContractFilterQuery>((ref, query) async {
  final result =
      await ref.watch(contractRepositoryProvider).getContractStatusFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final contractWorkStatusFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, ContractFilterQuery>((ref, query) async {
  final result =
      await ref.watch(contractRepositoryProvider).getWorkStatusFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final contractListProvider = FutureProvider.autoDispose
    .family<ContractListResult, ContractFilterQuery>((ref, query) async {
  final result =
      await ref.watch(contractRepositoryProvider).getContractsList(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (ContractListResult data) => data,
  );
});
