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
      final Map<String, dynamic> projectTypesJson =
          await _remote.fetchProjectTypes();
      final Map<String, dynamic> overviewJson =
          await _remote.fetchProjectList();
      final List<HomeProjectType> projectTypes =
          _parseProjectTypes(projectTypesJson);
      final HomeOverview overview = _parseOverview(overviewJson, projectTypes);
      return Right(
        HomeDashboardData(overview: overview, projectTypes: projectTypes),
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

  HomeOverview _parseOverview(
    Map<String, dynamic> json,
    List<HomeProjectType> projectTypes,
  ) {
    final List<dynamic> rows = _extractList(json);
    int projects = projectTypes.fold<int>(
      0,
      (int sum, HomeProjectType type) => sum + type.cumulativeCount,
    );
    double totalLength = 0;
    double commissioned = 0;

    for (final dynamic row in rows) {
      if (row is! Map) {
        continue;
      }
      final Map<String, dynamic> map = row.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );
      totalLength += _toDouble(
        map['totalLength'] ?? map['length'] ?? map['projectLength'],
      );
      commissioned += _toDouble(
        map['commissionedLength'] ?? map['commissioned'],
      );
      if (projects == 0) {
        projects = rows.length;
      }
    }

    if (projects == 0 && rows.isNotEmpty) {
      projects = rows.length;
    }

    return HomeOverview(
      projectsCount: projects,
      totalLength: totalLength,
      commissionedLength: commissioned,
    );
  }

  List<HomeProjectType> _parseProjectTypes(Map<String, dynamic> json) {
    final List<dynamic> rows = _extractList(json);
    final List<HomeProjectType> types = <HomeProjectType>[];
    for (final dynamic row in rows) {
      if (row is! Map) {
        continue;
      }
      final Map<String, dynamic> map = row.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );
      final String name = (map['projectTypeName'] ??
              map['typeName'] ??
              map['name'] ??
              map['projectType'] ??
              '')
          .toString()
          .trim();
      if (name.isEmpty) {
        continue;
      }
      final int count = int.tryParse(
            (map['cumulativeCount'] ??
                    map['count'] ??
                    map['projectCount'] ??
                    map['total'] ??
                    '0')
                .toString(),
          ) ??
          0;
      types.add(HomeProjectType(name: name, cumulativeCount: count));
    }
    return types;
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

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    return double.tryParse(value.toString().replaceAll(',', '')) ?? 0;
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});
