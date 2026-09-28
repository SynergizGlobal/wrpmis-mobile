import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/core/result/result.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/utility_shifting_api_data_source.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/utility_shifting_item.dart';

class UtilityShiftingRepository {
  const UtilityShiftingRepository(this._api);

  final UtilityShiftingApiDataSource _api;

  Future<Result<List<DropdownOption>>> getLocationFilter(
    UtilityShiftingFilterQuery query,
  ) async {
    try {
      return Right(await _api.fetchLocationFilter(query));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load locations'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getCategoryFilter(
    UtilityShiftingFilterQuery query,
  ) async {
    try {
      return Right(await _api.fetchCategoryFilter(query));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load categories'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getTypeFilter(
    UtilityShiftingFilterQuery query,
  ) async {
    try {
      return Right(await _api.fetchTypeFilter(query));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load utility types'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getStatusFilter(
    UtilityShiftingFilterQuery query,
  ) async {
    try {
      return Right(await _api.fetchStatusFilter(query));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load statuses'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<UtilityShiftingListResult>> getList(
    UtilityShiftingFilterQuery query,
  ) async {
    try {
      return Right(await _api.fetchList(query));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load utility shifting'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getImpactedContracts(
    String projectId,
  ) async {
    try {
      return Right(await _api.fetchImpactedContracts(projectId));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load contracts'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getRequirementStages(
    String contractId,
  ) async {
    try {
      return Right(await _api.fetchRequirementStages(contractId));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load requirement stages'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getImpactedElements({
    required String contractId,
    required String stage,
  }) async {
    try {
      return Right(
        await _api.fetchImpactedElements(contractId: contractId, stage: stage),
      );
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load impacted elements'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<Map<String, List<DropdownOption>>>> getAddFormOptions() async {
    try {
      return Right(await _api.fetchAddFormOptions());
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load form'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<UtilityShiftingItem?>> getDetail({
    required String id,
    required String utilityShiftingId,
  }) async {
    try {
      return Right(
        await _api.fetchDetail(id: id, utilityShiftingId: utilityShiftingId),
      );
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load record'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<String>> save(Map<String, dynamic> fields) async {
    try {
      return Right(await _api.save(fields));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to save'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<UtilityUploadItem>>> getUploads() async {
    try {
      return Right(await _api.fetchUploads());
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load uploads'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}

final utilityShiftingRepositoryProvider =
    Provider<UtilityShiftingRepository>((ref) {
  return UtilityShiftingRepository(
    ref.watch(utilityShiftingApiDataSourceProvider),
  );
});
