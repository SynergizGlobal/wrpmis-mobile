import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/core/result/result.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/design_drawing_api_data_source.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/design_drawing_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

class DesignDrawingRepository {
  const DesignDrawingRepository(this._api);

  final DesignDrawingApiDataSource _api;

  Future<Result<List<DropdownOption>>> getContractFilter(
    DesignDrawingFilterQuery query,
  ) async {
    try {
      return Right(await _api.fetchContractFilter(query));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load contracts'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getStructureTypeFilter(
    DesignDrawingFilterQuery query,
  ) async {
    try {
      return Right(await _api.fetchStructureTypeFilter(query));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load structure types'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getDrawingTypeFilter(
    DesignDrawingFilterQuery query,
  ) async {
    try {
      return Right(await _api.fetchDrawingTypeFilter(query));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load drawing types'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<DesignDrawingListResult>> getDesigns(
    DesignDrawingFilterQuery query,
  ) async {
    try {
      return Right(await _api.fetchDesigns(query));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load designs'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DesignUploadItem>>> getUploads() async {
    try {
      return Right(await _api.fetchUploads());
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load uploads'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}

final designDrawingRepositoryProvider = Provider<DesignDrawingRepository>((ref) {
  return DesignDrawingRepository(ref.watch(designDrawingApiDataSourceProvider));
});
