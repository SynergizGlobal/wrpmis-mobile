import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/core/result/result.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/issue_api_data_source.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/issue_form_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/issue_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

class IssueRepository {
  const IssueRepository(this._api);

  final IssueApiDataSource _api;

  Future<Result<List<DropdownOption>>> getContractFilter(
    IssueFilterQuery query,
  ) {
    return _mapFilter(
      () => _api.fetchIssueFilter(
        path: ApiConstants.issueContractFilterPath,
        params: query.ajaxParams,
      ),
      idKeys: const <String>['contract_id_fk', 'contract_id'],
      nameKeys: const <String>['contract_short_name', 'contract_name'],
      error: 'Failed to load contract filter',
    );
  }

  Future<Result<List<DropdownOption>>> getHodFilter(IssueFilterQuery query) {
    return _mapFilter(
      () => _api.fetchIssueFilter(
        path: ApiConstants.issueHodFilterPath,
        params: query.ajaxParams,
      ),
      idKeys: const <String>['designation', 'hod', 'hod_user_id_fk'],
      nameKeys: const <String>['designation', 'hod'],
      error: 'Failed to load HOD filter',
    );
  }

  Future<Result<List<DropdownOption>>> getDepartmentFilter(
    IssueFilterQuery query,
  ) {
    return _mapFilter(
      () => _api.fetchIssueFilter(
        path: ApiConstants.issueDepartmentFilterPath,
        params: query.ajaxParams,
      ),
      idKeys: const <String>['department_fk', 'department'],
      nameKeys: const <String>['department_name', 'department'],
      error: 'Failed to load department filter',
    );
  }

  Future<Result<List<DropdownOption>>> getCategoryFilter(
    IssueFilterQuery query,
  ) {
    return _mapFilter(
      () => _api.fetchIssueFilter(
        path: ApiConstants.issueCategoryFilterPath,
        params: query.ajaxParams,
      ),
      idKeys: const <String>['category_fk', 'category'],
      nameKeys: const <String>['category', 'category_fk'],
      error: 'Failed to load category filter',
    );
  }

  Future<Result<List<DropdownOption>>> getStatusFilter(
    IssueFilterQuery query,
  ) {
    return _mapFilter(
      () => _api.fetchIssueFilter(
        path: ApiConstants.issueStatusFilterPath,
        params: query.ajaxParams,
      ),
      idKeys: const <String>['status_fk', 'status'],
      nameKeys: const <String>['status', 'status_fk'],
      error: 'Failed to load status filter',
    );
  }

  Future<Result<IssueListResult>> getIssuesList(IssueFilterQuery query) async {
    try {
      final List<IssueListItem> all = await _api.fetchIssuesList(
        params: query.ajaxParams,
      );
      final List<IssueListItem> filtered = query.search.trim().isEmpty
          ? all
          : all
              .where((IssueListItem e) => e.matchesSearch(query.search))
              .toList();
      final int start = query.page * query.pageSize;
      final List<IssueListItem> page = query.pageSize <= 0
          ? filtered
          : filtered.skip(start).take(query.pageSize).toList();
      return Right(
        IssueListResult(
          items: page,
          totalRecords: all.length,
          filteredRecords: filtered.length,
        ),
      );
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load issues'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<IssueFormDetail>> getIssueForm({
    String? issueId,
    IssueListItem? seed,
  }) async {
    try {
      IssueFormDetail detail = await _api.fetchIssueForm(issueId: issueId);
      if (detail.projects.isEmpty) {
        final List<DropdownOption> projects = await _api.fetchProjects();
        detail = detail.withProjects(projects);
      }
      return Right(detail.mergeSeed(seed));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load issue form'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getFormContracts(String projectId) {
    return _wrap(
      () => _api.fetchFormContracts(projectId),
      'Failed to load contracts',
    );
  }

  Future<Result<List<DropdownOption>>> getFormCategories(String contractType) {
    return _wrap(
      () => _api.fetchFormCategories(contractType),
      'Failed to load categories',
    );
  }

  Future<Result<List<DropdownOption>>> getFormTitles(String category) {
    return _wrap(
      () => _api.fetchFormTitles(category),
      'Failed to load short descriptions',
    );
  }

  Future<Result<List<DropdownOption>>> getFormStructures(String contractId) {
    return _wrap(
      () => _api.fetchFormStructures(contractId),
      'Failed to load structures',
    );
  }

  Future<Result<List<DropdownOption>>> getFormComponents({
    required String contractId,
    required String structure,
  }) {
    return _wrap(
      () => _api.fetchFormComponents(
        contractId: contractId,
        structure: structure,
      ),
      'Failed to load components',
    );
  }

  Future<Result<List<DropdownOption>>> getFormStatuses() {
    return _wrap(() => _api.fetchFormStatuses(), 'Failed to load statuses');
  }

  Future<Result<List<DropdownOption>>> getResponsiblePersons(
    String departmentName,
  ) {
    return _wrap(
      () => _api.fetchResponsiblePersons(departmentName),
      'Failed to load responsible persons',
    );
  }

  Future<Result<List<DropdownOption>>> getLaDetails() {
    return _wrap(() => _api.fetchLaDetails(), 'Failed to load LA details');
  }

  Future<Result<List<DropdownOption>>> _wrap(
    Future<List<DropdownOption>> Function() load,
    String error,
  ) async {
    try {
      return Right(await load());
    } on DioException catch (e) {
      return Left(Failure(e.message ?? error));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> _mapFilter(
    Future<List<Map<String, dynamic>>> Function() load, {
    required List<String> idKeys,
    required List<String> nameKeys,
    required String error,
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
        final String name = _first(row, nameKeys);
        options.add(DropdownOption(id: id, name: name.isEmpty ? id : name));
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

final issueRepositoryProvider = Provider<IssueRepository>((ref) {
  return IssueRepository(ref.watch(issueApiDataSourceProvider));
});
