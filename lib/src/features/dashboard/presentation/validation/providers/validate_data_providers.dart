import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/validate_data_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/validate_activity_item.dart';

final validateContractsProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, ValidateDataQuery>((ref, query) async {
  final result =
      await ref.watch(validateDataRepositoryProvider).contracts(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final validateStructuresProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, ValidateDataQuery>((ref, query) async {
  final result =
      await ref.watch(validateDataRepositoryProvider).structures(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final validateUpdatedByProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, ValidateDataQuery>((ref, query) async {
  final result =
      await ref.watch(validateDataRepositoryProvider).updatedBy(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final validateActivitiesProvider = FutureProvider.autoDispose
    .family<List<ValidateActivityItem>, ValidateDataQuery>((ref, query) async {
  final result =
      await ref.watch(validateDataRepositoryProvider).activities(query);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<ValidateActivityItem> data) => data,
  );
});
