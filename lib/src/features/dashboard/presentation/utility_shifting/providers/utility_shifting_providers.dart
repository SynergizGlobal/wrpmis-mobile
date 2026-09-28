import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/utility_shifting_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/utility_shifting_item.dart';

final utilityLocationFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, UtilityShiftingFilterQuery>((ref, query) async {
  final result = await ref
      .watch(utilityShiftingRepositoryProvider)
      .getLocationFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final utilityCategoryFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, UtilityShiftingFilterQuery>((ref, query) async {
  final result = await ref
      .watch(utilityShiftingRepositoryProvider)
      .getCategoryFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final utilityTypeFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, UtilityShiftingFilterQuery>((ref, query) async {
  final result =
      await ref.watch(utilityShiftingRepositoryProvider).getTypeFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final utilityStatusFilterProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, UtilityShiftingFilterQuery>((ref, query) async {
  final result = await ref
      .watch(utilityShiftingRepositoryProvider)
      .getStatusFilter(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final utilityListProvider = FutureProvider.autoDispose
    .family<UtilityShiftingListResult, UtilityShiftingFilterQuery>(
        (ref, query) async {
  final result =
      await ref.watch(utilityShiftingRepositoryProvider).getList(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (UtilityShiftingListResult data) => data,
  );
});

final utilityUploadsProvider =
    FutureProvider.autoDispose<List<UtilityUploadItem>>((ref) async {
  final result = await ref.watch(utilityShiftingRepositoryProvider).getUploads();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<UtilityUploadItem> data) => data,
  );
});
