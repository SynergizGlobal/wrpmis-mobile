import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/project_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_form_edit_detail.dart';

final structureFormEditProvider = FutureProvider.autoDispose
    .family<StructureFormEditDetail, String>((ref, structureId) async {
  final result =
      await ref.watch(projectRepositoryProvider).getStructureFormEdit(structureId);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (StructureFormEditDetail data) => data,
  );
});

final structureFormContractsProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, String>((ref, projectId) async {
  if (projectId.isEmpty) return const <DropdownOption>[];
  final result = await ref
      .watch(projectRepositoryProvider)
      .getContractsForStructureForm(projectId);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final structureFormExecutivesProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, String>((ref, contractId) async {
  if (contractId.isEmpty) return const <DropdownOption>[];
  final result = await ref
      .watch(projectRepositoryProvider)
      .getResponsibleExecutives(contractId);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});
