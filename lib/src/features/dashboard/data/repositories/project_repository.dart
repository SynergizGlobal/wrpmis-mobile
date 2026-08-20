import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/core/result/result.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/project_api_data_source.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_list_item.dart';

class ProjectRepository {
  const ProjectRepository(this._api);
  final ProjectApiDataSource _api;

  Future<Result<ProjectFormData>> getProjectFormData() async {
    try {
      final json = await _api.fetchProjectFormData();
      return Right(ProjectFormData.fromJson(json));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load form data'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<ProjectDetail>> getProjectById(String projectId) async {
    try {
      final json = await _api.fetchProjectById(projectId);
      return Right(ProjectDetail.fromJson(json));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load project'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<String>> addProject(Map<String, dynamic> payload) async {
    try {
      final msg = await _api.addProject(payload);
      return Right(msg);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to add project'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<String>> updateProject(Map<String, dynamic> payload) async {
    try {
      final msg = await _api.updateProject(payload);
      return Right(msg);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to update project'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<StructureFormData>> getStructureFormData() async {
    try {
      final json = await _api.fetchStructureFormData();
      return Right(StructureFormData.fromJson(json));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load structure form data'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<StructureDetail>> getStructureById(String structureId) async {
    try {
      final json = await _api.fetchStructureById(structureId);
      return Right(StructureDetail.fromJson(json));
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load structure'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<String>> addStructures(Map<String, dynamic> payload) async {
    try {
      final msg = await _api.addStructures(payload);
      return Right(msg);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to add structure'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<String>> updateStructures(Map<String, dynamic> payload) async {
    try {
      final msg = await _api.updateStructures(payload);
      return Right(msg);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to update structure'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<StructureListResult>> getStructureList({
    String? projectId,
    String search = '',
    int start = 0,
    int length = 10,
  }) async {
    try {
      final StructureListResult page = await _api.fetchStructureList(
        projectId: projectId,
        search: search,
        start: start,
        length: length,
      );
      return Right(page);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load structures'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getStructureProjectFilter() async {
    try {
      final List<Map<String, dynamic>> rows =
          await _api.fetchStructureProjectFilter();
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String id =
            (row['project_id_fk'] ?? row['project_id'] ?? '').toString();
        final String name =
            (row['project_name'] ?? row['projectName'] ?? id).toString();
        return DropdownOption(id: id, name: name);
      }).where((DropdownOption o) => o.id.isNotEmpty).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load project filter'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(projectApiDataSourceProvider));
});
