import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/core/result/result.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/contractor_api_data_source.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contractor_form_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contractor_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

class ContractorRepository {
  const ContractorRepository(this._api);

  final ContractorApiDataSource _api;

  Future<Result<ContractorListResult>> getContractors(
    ContractorFilterQuery query,
  ) async {
    try {
      return Right(await _api.fetchContractors(query));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load contractors'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getSpecializations() async {
    try {
      return Right(await _api.fetchSpecializations());
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load specializations'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<ContractorFormDetail>> getContractorForm({
    String? contractorId,
  }) async {
    try {
      return Right(await _api.fetchContractorForm(contractorId: contractorId));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load contractor form'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<bool>> isPanTaken(
    String panNumber, {
    String? ignoreContractorId,
  }) async {
    try {
      return Right(
        await _api.isPanTaken(
          panNumber,
          ignoreContractorId: ignoreContractorId,
        ),
      );
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to verify PAN'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<String>> saveContractor(ContractorFormDetail detail) async {
    try {
      final Map<String, dynamic> payload = detail.toSubmitMap();
      final bool editing =
          detail.contractorId != null && detail.contractorId!.isNotEmpty;
      final String message = editing
          ? await _api.updateContractor(payload)
          : await _api.addContractor(payload);
      return Right(message);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to save contractor'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}

final contractorRepositoryProvider = Provider<ContractorRepository>((ref) {
  return ContractorRepository(ref.watch(contractorApiDataSourceProvider));
});
