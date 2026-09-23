import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/design_drawing_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/design_drawing_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

final designContractFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, DesignDrawingFilterQuery>((ref, query) async {
  final result =
      await ref.watch(designDrawingRepositoryProvider).getContractFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final designStructureTypeFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, DesignDrawingFilterQuery>((ref, query) async {
  final result = await ref
      .watch(designDrawingRepositoryProvider)
      .getStructureTypeFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final designDrawingTypeFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, DesignDrawingFilterQuery>((ref, query) async {
  final result = await ref
      .watch(designDrawingRepositoryProvider)
      .getDrawingTypeFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final designListProvider = FutureProvider.autoDispose
    .family<DesignDrawingListResult, DesignDrawingFilterQuery>((ref, query) async {
  final result =
      await ref.watch(designDrawingRepositoryProvider).getDesigns(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (DesignDrawingListResult data) => data,
  );
});

final designUploadsProvider =
    FutureProvider.autoDispose<List<DesignUploadItem>>((ref) async {
  final result = await ref.watch(designDrawingRepositoryProvider).getUploads();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DesignUploadItem> data) => data,
  );
});
