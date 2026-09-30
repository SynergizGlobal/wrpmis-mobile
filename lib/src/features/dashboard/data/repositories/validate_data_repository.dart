import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/core/result/result.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/validate_data_api_data_source.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/validate_activity_item.dart';

class ValidateDataRepository {
  const ValidateDataRepository(this._api);

  final ValidateDataApiDataSource _api;

  Future<Result<List<DropdownOption>>> contracts(ValidateDataQuery query) =>
      _list(() => _api.fetchContracts(query), 'Failed to load contracts');

  Future<Result<List<DropdownOption>>> structures(ValidateDataQuery query) =>
      _list(() => _api.fetchStructures(query), 'Failed to load structures');

  Future<Result<List<DropdownOption>>> updatedBy(ValidateDataQuery query) =>
      _list(() => _api.fetchUpdatedBy(query), 'Failed to load users');

  Future<Result<List<ValidateActivityItem>>> activities(
    ValidateDataQuery query,
  ) async {
    try {
      return Right(await _api.fetchActivities(query));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load activities'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<String>> approve(ValidateActivityItem item) =>
      _text(() => _api.approve(
            structure: item.structure ?? '',
            progressId: item.progressId,
            contractId: item.contractId ?? '',
          ));

  Future<Result<String>> reject(ValidateActivityItem item) =>
      _text(() => _api.reject(
            structure: item.structure ?? '',
            progressId: item.progressId,
            contractId: item.contractId ?? '',
          ));

  Future<Result<String>> approveMany(List<ValidateActivityItem> items) async {
    final Map<String, List<ValidateActivityItem>> groups =
        <String, List<ValidateActivityItem>>{};
    for (final ValidateActivityItem item in items) {
      final String key = '${item.contractId ?? ''}|${item.structure ?? ''}';
      groups.putIfAbsent(key, () => <ValidateActivityItem>[]).add(item);
    }
    String message = 'Updated.';
    for (final List<ValidateActivityItem> group in groups.values) {
      final Result<String> result = group.length == 1
          ? await approve(group.first)
          : await _text(() => _api.approveMany(group));
      final String? error = result.fold((Failure failure) => failure.message, (_) => null);
      if (error != null) {
        return Left(Failure(error));
      }
      message = result.fold((_) => message, (String text) => text);
    }
    return Right(message);
  }

  Future<Result<String>> rejectMany(List<ValidateActivityItem> items) =>
      _text(() => _api.rejectMany(items));

  Future<Result<List<DropdownOption>>> _list(
    Future<List<DropdownOption>> Function() call,
    String message,
  ) async {
    try {
      return Right(await call());
    } on DioException catch (e) {
      return Left(Failure(e.message ?? message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<String>> _text(Future<String> Function() call) async {
    try {
      return Right(await call());
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Request failed'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}

final validateDataRepositoryProvider = Provider<ValidateDataRepository>((ref) {
  return ValidateDataRepository(ref.watch(validateDataApiDataSourceProvider));
});
