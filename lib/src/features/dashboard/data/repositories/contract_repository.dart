import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/core/result/result.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/contract_api_data_source.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contract_form_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contract_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

class ContractRepository {
  const ContractRepository(this._api);

  final ContractApiDataSource _api;

  Future<Result<List<DropdownOption>>> getHodFilter(
    ContractFilterQuery query,
  ) {
    // Web option value is hod_user_id, sent as query param "designation".
    return _mapOptions(
      () => _api.fetchContractFilter(
        path: ApiConstants.contractHodFilterPath,
        params: query.ajaxParams,
      ),
      idKeys: const <String>['hod_user_id', 'hod_user_id_fk'],
      nameKeys: const <String>['designation'],
      error: 'Failed to load HOD filter',
    );
  }

  Future<Result<List<DropdownOption>>> getDyHodFilter(
    ContractFilterQuery query,
  ) {
    // Web option value is dy_hod_user_id, sent as "dy_hod_designation".
    return _mapOptions(
      () => _api.fetchContractFilter(
        path: ApiConstants.contractDyHodFilterPath,
        params: query.ajaxParams,
      ),
      idKeys: const <String>['dy_hod_user_id', 'dy_hod_user_id_fk'],
      nameKeys: const <String>['dy_hod_designation'],
      error: 'Failed to load Dy HOD filter',
    );
  }

  Future<Result<List<DropdownOption>>> getContractorFilter(
    ContractFilterQuery query,
  ) {
    return _mapOptions(
      () => _api.fetchContractFilter(
        path: ApiConstants.contractContractorFilterPath,
        params: query.ajaxParams,
      ),
      idKeys: const <String>['contractor_id_fk', 'contractor_id'],
      nameKeys: const <String>['contractor_name'],
      prefixIdInName: true,
      error: 'Failed to load contractor filter',
    );
  }

  Future<Result<List<DropdownOption>>> getContractStatusFilter(
    ContractFilterQuery query,
  ) {
    return _mapOptions(
      () => _api.fetchContractFilter(
        path: ApiConstants.contractStatusFilterPath,
        params: query.ajaxParams,
      ),
      idKeys: const <String>['contract_status'],
      nameKeys: const <String>['contract_status'],
      error: 'Failed to load contract status',
    );
  }

  Future<Result<List<DropdownOption>>> getWorkStatusFilter(
    ContractFilterQuery query,
  ) {
    return _mapOptions(
      () => _api.fetchContractFilter(
        path: ApiConstants.contractWorkStatusFilterPath,
        params: query.ajaxParams,
      ),
      idKeys: const <String>['contract_status_fk'],
      nameKeys: const <String>['contract_status_fk'],
      error: 'Failed to load status of work',
    );
  }

  Future<Result<ContractListResult>> getContractsList(
    ContractFilterQuery query,
  ) async {
    try {
      final List<ContractListItem> all = await _api.fetchContractsList(
        params: query.ajaxParams,
      );
      final List<ContractListItem> filtered = query.search.trim().isEmpty
          ? all
          : all
              .where((ContractListItem e) => e.matchesSearch(query.search))
              .toList();
      final int start = query.page * query.pageSize;
      final List<ContractListItem> page = query.pageSize <= 0
          ? filtered
          : filtered.skip(start).take(query.pageSize).toList();
      return Right(
        ContractListResult(
          items: page,
          totalRecords: all.length,
          filteredRecords: filtered.length,
        ),
      );
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load contracts'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getHodList() {
    return _mapOptions(
      () => _api.fetchHodList(),
      idKeys: const <String>['hod_user_id_fk', 'user_id'],
      nameKeys: const <String>['designation', 'user_name'],
      combineName: true,
      error: 'Failed to load HOD list',
    );
  }

  Future<Result<List<DropdownOption>>> getDyHodList(String hodUserId) {
    return _mapOptions(
      () => _api.fetchDyHodList(hodUserId),
      idKeys: const <String>['dy_hod_user_id_fk', 'user_name', 'hod_user_id_fk'],
      nameKeys: const <String>['user_name', 'designation'],
      combineName: true,
      error: 'Failed to load Dy HOD list',
    );
  }

  Future<Result<List<DropdownOption>>> getExecutives(String departmentFk) {
    return _mapOptions(
      () => _api.fetchExecutives(departmentFk),
      idKeys: const <String>[
        'hod_user_id_fk',
        'executive_user_id_fk',
        'user_id',
      ],
      nameKeys: const <String>['user_name', 'designation'],
      combineName: true,
      error: 'Failed to load executives',
    );
  }

  Future<Result<List<DropdownOption>>> getFormWorkStatuses(String awarded) {
    return _mapOptions(
      () => _api.fetchFormWorkStatuses(awarded),
      idKeys: const <String>['contract_status_fk'],
      nameKeys: const <String>['contract_status_fk'],
      error: 'Failed to load status of work',
    );
  }

  Future<Result<ContractFormDetail>> getContractForm({String? contractId}) async {
    try {
      final ContractFormDetail detail =
          await _api.fetchContractForm(contractId: contractId);
      return Right(detail);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load contract form'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> _mapOptions(
    Future<List<Map<String, dynamic>>> Function() load, {
    required List<String> idKeys,
    required List<String> nameKeys,
    required String error,
    bool prefixIdInName = false,
    bool combineName = false,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await load();
      final List<DropdownOption> options = <DropdownOption>[];
      final Set<String> seen = <String>{};
      for (final Map<String, dynamic> row in rows) {
        final String id = _first(row, idKeys);
        if (id.isEmpty || !seen.add(id)) {
          continue;
        }
        final String primary = _first(row, nameKeys);
        String label = primary.isEmpty ? id : primary;
        if (combineName && nameKeys.length > 1) {
          final String second = _first(row, nameKeys.sublist(1));
          if (second.isNotEmpty && second != primary) {
            label = '$primary - $second';
          }
        }
        if (prefixIdInName && id != label) {
          label = '$id - $label';
        }
        options.add(DropdownOption(id: id, name: label));
      }
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? error));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  String _first(Map<String, dynamic> row, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = row[key];
      if (value == null) {
        continue;
      }
      final String text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }
}

final contractRepositoryProvider = Provider<ContractRepository>((ref) {
  return ContractRepository(ref.watch(contractApiDataSourceProvider));
});
