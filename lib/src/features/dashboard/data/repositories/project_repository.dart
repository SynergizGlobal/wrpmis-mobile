import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/core/result/result.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/project_api_data_source.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/p6_data_history_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_form_edit_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_form_list_item.dart';
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
      final StructureDetail detail = await _api.fetchStructureById(structureId);
      return Right(detail);
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

  Future<Result<StructureFormListResult>> getStructureFormList({
    String? contractId,
    String? structureType,
    String? workStatus,
    String search = '',
    int start = 0,
    int length = 10,
  }) async {
    try {
      final StructureFormListResult page = await _api.fetchStructureFormList(
        contractId: contractId,
        structureType: structureType,
        workStatus: workStatus,
        search: search,
        start: start,
        length: length,
      );
      return Right(page);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load structure form list'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getStructureFormContractFilter({
    String? contractId,
    String? workStatus,
    String? structureType,
  }) async {
    try {
      final List<Map<String, dynamic>> rows =
          await _api.fetchStructureFormContractFilter(
        contractId: contractId,
        workStatus: workStatus,
        structureType: structureType,
      );
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String id = (row['contract_id_fk'] ?? row['contract_id'] ?? '')
            .toString()
            .trim();
        final String shortName =
            (row['contract_short_name'] ?? '').toString().trim();
        final String name = (row['contract_name'] ?? '').toString().trim();
        final String label =
            shortName.isNotEmpty ? shortName : (name.isNotEmpty ? name : id);
        return DropdownOption(id: id, name: label);
      }).where((DropdownOption o) => o.id.isNotEmpty).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load contracts'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getStructureFormTypeFilter({
    String? contractId,
    String? structureType,
  }) async {
    try {
      final List<Map<String, dynamic>> rows =
          await _api.fetchStructureFormTypeFilter(
        contractId: contractId,
        structureType: structureType,
      );
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String type = (row['structure_type'] ??
                row['structure_type_fk'] ??
                '')
            .toString()
            .trim();
        return DropdownOption(id: type, name: type);
      }).where((DropdownOption o) => o.id.isNotEmpty).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load structure types'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getStructureFormWorkStatusFilter({
    String? workStatus,
    String? contractId,
    String? structureType,
  }) async {
    try {
      final List<Map<String, dynamic>> rows =
          await _api.fetchStructureFormWorkStatusFilter(
        workStatus: workStatus,
        contractId: contractId,
        structureType: structureType,
      );
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String status =
            (row['work_status_fk'] ?? row['work_status'] ?? '').toString().trim();
        return DropdownOption(id: status, name: status);
      }).where((DropdownOption o) => o.id.isNotEmpty).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load work statuses'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<StructureFormEditDetail>> getStructureFormEdit(
    String structureId,
  ) async {
    try {
      final StructureFormEditDetail detail =
          await _api.fetchStructureFormEdit(structureId);
      return Right(detail);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load structure form'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<String>> updateStructureForm(FormData formData) async {
    try {
      final String msg = await _api.updateStructureForm(formData);
      return Right(msg);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to update structure form'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getContractsForStructureForm(
    String projectId,
  ) async {
    try {
      final List<Map<String, dynamic>> rows =
          await _api.fetchContractsForStructureForm(projectId: projectId);
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String id =
            (row['contract_id_fk'] ?? row['contract_id'] ?? '').toString().trim();
        final String shortName =
            (row['contract_short_name'] ?? '').toString().trim();
        final String name = (row['contract_name'] ?? '').toString().trim();
        final String label =
            shortName.isNotEmpty ? shortName : (name.isNotEmpty ? name : id);
        return DropdownOption(id: id, name: label);
      }).where((DropdownOption o) => o.id.isNotEmpty).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load contracts'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getResponsibleExecutives(
    String contractId,
  ) async {
    try {
      final List<Map<String, dynamic>> rows =
          await _api.fetchResponsibleExecutives(contractId: contractId);
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String id = (row['user_id'] ?? '').toString().trim();
        final String designation = (row['designation'] ?? '').toString().trim();
        final String userName = (row['user_name'] ?? '').toString().trim();
        final String label = designation.isNotEmpty && userName.isNotEmpty
            ? '$designation-$userName'
            : (userName.isNotEmpty
                ? userName
                : (designation.isNotEmpty ? designation : id));
        return DropdownOption(id: id, name: label);
      }).where((DropdownOption o) => o.id.isNotEmpty).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load executives'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getP6ContractFilter({
    String? contractId,
    String? uploadType,
    String? statusFk,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _api.fetchP6ContractFilter(
        contractId: contractId,
        uploadType: uploadType,
        statusFk: statusFk,
      );
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String id =
            (row['contract_id'] ?? row['contract_id_fk'] ?? '').toString().trim();
        final String shortName =
            (row['contract_short_name'] ?? '').toString().trim();
        final String name = (row['contract_name'] ?? '').toString().trim();
        final String label =
            shortName.isNotEmpty ? shortName : (name.isNotEmpty ? name : id);
        return DropdownOption(id: id, name: label);
      }).where((DropdownOption o) => o.id.isNotEmpty).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load contracts'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getP6UploadTypeFilter({
    String? contractId,
    String? uploadType,
    String? statusFk,
  }) async {
    try {
      final List<Map<String, dynamic>> rows =
          await _api.fetchP6UploadTypeFilter(
        contractId: contractId,
        uploadType: uploadType,
        statusFk: statusFk,
      );
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String type =
            (row['upload_type'] ?? '').toString().trim();
        return DropdownOption(id: type, name: type);
      }).where((DropdownOption o) => o.id.isNotEmpty).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load data types'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getP6StatusFilter({
    String? contractId,
    String? uploadType,
    String? statusFk,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _api.fetchP6StatusFilter(
        contractId: contractId,
        uploadType: uploadType,
        statusFk: statusFk,
      );
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String status =
            (row['soft_delete_status_fk'] ?? row['status_fk'] ?? '')
                .toString()
                .trim();
        return DropdownOption(id: status, name: status);
      }).where((DropdownOption o) => o.id.isNotEmpty).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load statuses'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<P6DataHistoryListResult>> getP6DataHistoryList({
    String? contractId,
    String? uploadType,
    String? statusFk,
    String search = '',
    int start = 0,
    int length = 10,
  }) async {
    try {
      final P6DataHistoryListResult page = await _api.fetchP6DataHistoryList(
        contractId: contractId,
        uploadType: uploadType,
        statusFk: statusFk,
        search: search,
        start: start,
        length: length,
      );
      return Right(page);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load P6 data history'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(projectApiDataSourceProvider));
});
