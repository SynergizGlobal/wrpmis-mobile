import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/project_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_form_data.dart';

final structureFormDataProvider =
    FutureProvider.autoDispose<StructureFormData>((ref) async {
  final result =
      await ref.watch(projectRepositoryProvider).getStructureFormData();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (StructureFormData data) => data,
  );
});

final structureByIdProvider =
    FutureProvider.autoDispose.family<StructureDetail, String>((ref, id) async {
  final result =
      await ref.watch(projectRepositoryProvider).getStructureById(id);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (StructureDetail data) => data,
  );
});
