import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/contractor_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contractor_form_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contractor_list_item.dart';

final contractorListProvider = FutureProvider.autoDispose
    .family<ContractorListResult, ContractorFilterQuery>((ref, query) async {
  final result =
      await ref.watch(contractorRepositoryProvider).getContractors(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (ContractorListResult data) => data,
  );
});

final contractorFormProvider = FutureProvider.autoDispose
    .family<ContractorFormDetail, String>((ref, contractorId) async {
  final result = await ref
      .watch(contractorRepositoryProvider)
      .getContractorForm(
        contractorId: contractorId.isEmpty ? null : contractorId,
      );
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (ContractorFormDetail data) => data,
  );
});
