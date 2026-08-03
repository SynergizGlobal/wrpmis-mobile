import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/core/result/result.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/home_dashboard_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/update_form_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._remote);

  final DashboardRemoteDataSource _remote;

  @override
  Future<Result<HomeDashboardData>> getHomeDashboardData() async {
    try {
      final List<Map<String, dynamic>> apiRows = await _remote.fetchProjects();
      List<Map<String, dynamic>> summaryRows = const <Map<String, dynamic>>[];
      try {
        summaryRows = await _remote.fetchHomeProjectSummaries();
      } catch (_) {
        // Home HTML parse is optional; `/api/projects` remains the fallback.
      }

      final List<HomeProjectItem> projects = _uniqueProjects(
        summaryRows.isNotEmpty ? summaryRows : apiRows,
      );

      return Right(
        HomeDashboardData(
          overview: _buildOverview(projects),
          projectTypes: _buildProjectTypes(projects),
          projects: projects,
        ),
      );
    } on DioException catch (error) {
      return Left(
        Failure(error.message ?? 'Unable to load home dashboard'),
      );
    } catch (error) {
      return Left(Failure(error.toString()));
    }
  }

  @override
  Future<Result<List<UpdateFormItem>>> getUpdateForms() async {
    try {
      final Map<String, dynamic> json = await _remote.fetchUpdateForms();
      final List<dynamic> rows = _extractList(json);
      final List<UpdateFormItem> items = rows
          .whereType<Map>()
          .map((Map entry) {
            final Map<String, dynamic> map = entry.map(
              (dynamic key, dynamic value) => MapEntry(key.toString(), value),
            );
            return UpdateFormItem.fromJson(map);
          })
          .where((UpdateFormItem item) => item.showInMobile)
          .toList()
        ..sort(
          (UpdateFormItem a, UpdateFormItem b) =>
              a.priority.compareTo(b.priority),
        );
      return Right(items);
    } on DioException catch (error) {
      return Left(Failure(error.message ?? 'Unable to load update forms'));
    } catch (error) {
      return Left(Failure(error.toString()));
    }
  }

  @override
  Future<Result<ProjectDetailsData>> getProjectDetailsByType(
    String projectTypeName,
  ) async {
    try {
      final List<Map<String, dynamic>> apiRows = await _remote.fetchProjects();
      List<Map<String, dynamic>> summaryRows = const <Map<String, dynamic>>[];
      try {
        summaryRows = await _remote.fetchHomeProjectSummaries();
      } catch (_) {}

      final String target = projectTypeName.trim().toLowerCase();
      bool matchesType(Map<String, dynamic> row) {
        final String rowTypeName =
            (row['project_type_name'] ?? row['projectTypeName'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
        if (rowTypeName == target) {
          return true;
        }
        final String rowTypeId =
            (row['project_type_id'] ?? row['projectTypeId'] ?? '')
                .toString()
                .trim();
        for (final ({String id, String name}) category
            in HomeDashboardData.canonicalCategories) {
          if (category.name.toLowerCase() == target) {
            return rowTypeId == category.id;
          }
        }
        return false;
      }

      final List<Map<String, dynamic>> filteredItems =
          apiRows.where(matchesType).toList();
      final List<Map<String, dynamic>> filteredSummaries =
          summaryRows.where(matchesType).toList();

      final List<String> projectNames = <String>[];
      final Set<String> seen = <String>{};
      final Map<String, String> projectIdsByName = <String, String>{};

      void collectName(Map<String, dynamic> row) {
        final String name =
            (row['project_name'] ?? row['projectName'] ?? '').toString().trim();
        final String id =
            (row['project_id'] ?? row['projectId'] ?? '').toString().trim();
        if (name.isNotEmpty && seen.add(name)) {
          projectNames.add(name);
        }
        if (name.isNotEmpty && id.isNotEmpty) {
          projectIdsByName[name] = id;
        }
      }

      for (final Map<String, dynamic> row in filteredSummaries) {
        collectName(row);
      }
      for (final Map<String, dynamic> row in filteredItems) {
        collectName(row);
      }

      final List<ProjectMajorItem> items = filteredItems.map((
        Map<String, dynamic> row,
      ) {
        final String scope = (row['scope'] ?? '-').toString();
        final String completed = (row['completed'] ?? '-').toString();
        return ProjectMajorItem(
          projectName:
              (row['project_name'] ?? row['projectName'] ?? 'Unknown Project')
                  .toString()
                  .trim(),
          item: (row['structure_type'] ?? row['structureType'] ?? '-').toString(),
          unit: _unitFrom(scope, completed),
          scope: _stripUnit(scope),
          completed: _stripUnit(completed),
          progressPercent: _progressLabel(
            row['physical_progress'] ??
                row['physicalProgress'] ??
                row['financial_progress'] ??
                row['financialProgress'] ??
                row['progress'],
          ),
          tdc: (row['revised_target_date'] ??
                  row['revisedTargetDate'] ??
                  '-')
              .toString(),
        );
      }).toList();

      if (projectNames.isEmpty) {
        for (final ProjectMajorItem item in items) {
          if (item.projectName.isNotEmpty &&
              seen.add(item.projectName)) {
            projectNames.add(item.projectName);
          }
        }
      }

      return Right(
        ProjectDetailsData(
          projectTypeName: projectTypeName,
          projectNames: projectNames,
          items: items,
          projectIdsByName: projectIdsByName,
        ),
      );
    } on DioException catch (error) {
      return Left(
        Failure(error.message ?? 'Unable to load project details'),
      );
    } catch (_) {
      return const Left(
        Failure('Something went wrong while loading project details.'),
      );
    }
  }

  String _unitFrom(String scope, String completed) {
    final RegExp unitPattern = RegExp(r'\s+([A-Za-z/%]+)\s*$');
    final RegExpMatch? fromScope = unitPattern.firstMatch(scope.trim());
    if (fromScope != null) {
      return fromScope.group(1)!;
    }
    final RegExpMatch? fromCompleted = unitPattern.firstMatch(completed.trim());
    return fromCompleted?.group(1) ?? '-';
  }

  String _stripUnit(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '-') {
      return '-';
    }
    return trimmed.replaceFirst(RegExp(r'\s+[A-Za-z/%]+\s*$'), '').trim();
  }

  String _progressLabel(dynamic value) {
    if (value == null) {
      return '-';
    }
    final double? parsed = double.tryParse(
      value.toString().replaceAll('%', '').replaceAll(',', '').trim(),
    );
    if (parsed == null) {
      return value.toString();
    }
    final double percent = parsed.abs() <= 1 ? parsed * 100 : parsed;
    return '${percent.toStringAsFixed(2)} %';
  }

  /// `/api/projects` returns major-item rows; collapse to one row per project.
  List<HomeProjectItem> _uniqueProjects(List<Map<String, dynamic>> rows) {
    final Map<String, HomeProjectItem> byId = <String, HomeProjectItem>{};
    for (final Map<String, dynamic> row in rows) {
      final HomeProjectItem item = HomeProjectItem.fromJson(row);
      if (item.projectId.trim().isEmpty) {
        continue;
      }
      final HomeProjectItem? existing = byId[item.projectId];
      if (existing == null) {
        byId[item.projectId] = item;
        continue;
      }
      byId[item.projectId] = HomeProjectItem(
        projectId: existing.projectId,
        projectName: existing.projectName.isNotEmpty
            ? existing.projectName
            : item.projectName,
        projectTypeId: existing.projectTypeId ?? item.projectTypeId,
        projectTypeName: existing.projectTypeName ?? item.projectTypeName,
        length: existing.length ?? item.length,
        commissionedLength: _maxNullable(
          existing.commissionedLength,
          item.commissionedLength,
        ),
        physicalProgress: existing.physicalProgress ?? item.physicalProgress,
        financialProgress: existing.financialProgress ?? item.financialProgress,
      );
    }
    return byId.values.toList()
      ..sort(
        (HomeProjectItem a, HomeProjectItem b) =>
            a.projectId.compareTo(b.projectId),
      );
  }

  HomeOverview _buildOverview(List<HomeProjectItem> projects) {
    double totalLength = 0;
    double commissioned = 0;
    for (final HomeProjectItem project in projects) {
      totalLength += project.length ?? 0;
      commissioned += project.commissionedLength ?? 0;
    }

    return HomeOverview(
      projectsCount: projects.length,
      totalLength: totalLength,
      commissionedLength: commissioned,
    );
  }

  List<HomeProjectType> _buildProjectTypes(List<HomeProjectItem> projects) {
    final Map<String, int> byName = <String, int>{};
    final Map<String, int> byId = <String, int>{};
    for (final HomeProjectItem project in projects) {
      final String? name = project.projectTypeName?.trim();
      final String? id = project.projectTypeId?.trim();
      if (name != null && name.isNotEmpty) {
        byName[name.toLowerCase()] = (byName[name.toLowerCase()] ?? 0) + 1;
      }
      if (id != null && id.isNotEmpty) {
        byId[id] = (byId[id] ?? 0) + 1;
      }
    }

    return HomeDashboardData.canonicalCategories.map((
      ({String id, String name}) category,
    ) {
      final int count = byId[category.id] ??
          byName[category.name.toLowerCase()] ??
          0;
      return HomeProjectType(
        id: category.id,
        name: category.name,
        cumulativeCount: count,
      );
    }).toList();
  }

  double? _maxNullable(double? a, double? b) {
    if (a == null) {
      return b;
    }
    if (b == null) {
      return a;
    }
    return a >= b ? a : b;
  }

  List<dynamic> _extractList(Map<String, dynamic> json) {
    for (final String key in <String>[
      'data',
      'result',
      'list',
      'rows',
      'projectTypes',
      'forms',
      'updateForms',
    ]) {
      final dynamic value = json[key];
      if (value is List) {
        return value;
      }
    }
    for (final dynamic value in json.values) {
      if (value is List) {
        return value;
      }
    }
    return const <dynamic>[];
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});
