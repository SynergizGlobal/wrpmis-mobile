import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/core/result/result.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/project_api_data_source.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/new_activity_row.dart';
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

  Future<Result<Map<String, dynamic>>> exportProjects() async {
    try {
      final Map<String, dynamic> json = await _api.fetchProjectsExport();
      return Right(json);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to export projects'));
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

  Future<Result<String>> uploadP6Data({
    required String apiPath,
    required String projectId,
    required String contractId,
    required String dataDate,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final String msg = await _api.uploadP6Data(
        apiPath: apiPath,
        projectId: projectId,
        contractId: contractId,
        dataDate: dataDate,
        filePath: filePath,
        fileName: fileName,
      );
      return Right(msg);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to upload P6 data'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getNewActivitiesContracts() async {
    try {
      final List<Map<String, dynamic>> rows =
          await _api.fetchNewActivitiesContracts();
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String id =
            (row['contract_id'] ?? row['contract_id_fk'] ?? '').toString().trim();
        final String shortName =
            (row['contract_short_name'] ?? '').toString().trim();
        final String name = (row['contract_name'] ?? '').toString().trim();
        final String projectId =
            (row['project_id_fk'] ?? row['project_id'] ?? '').toString().trim();
        final String label =
            shortName.isNotEmpty ? shortName : (name.isNotEmpty ? name : id);
        return DropdownOption(
          id: id,
          name: label,
          extra: projectId.isEmpty ? null : projectId,
        );
      }).where((DropdownOption o) => o.id.isNotEmpty).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load contracts'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getNewActivitiesProjects() async {
    try {
      final List<Map<String, dynamic>> projectRows =
          await _api.fetchProjectsList();
      final Result<List<DropdownOption>> contractsResult =
          await getNewActivitiesContracts();
      final Set<String> projectIds = <String>{};
      contractsResult.fold(
        (_) {},
        (List<DropdownOption> contracts) {
          for (final DropdownOption c in contracts) {
            final String? pid = c.extra;
            if (pid != null && pid.isNotEmpty) {
              projectIds.add(pid);
            }
          }
        },
      );

      final List<DropdownOption> options =
          projectRows.map((Map<String, dynamic> row) {
        final String id =
            (row['project_id'] ?? row['project_id_fk'] ?? '').toString().trim();
        final String name =
            (row['project_name'] ?? row['projectName'] ?? id).toString().trim();
        return DropdownOption(id: id, name: name.isEmpty ? id : name);
      }).where((DropdownOption o) {
        if (o.id.isEmpty) {
          return false;
        }
        if (projectIds.isEmpty) {
          return true;
        }
        return projectIds.contains(o.id);
      }).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load projects'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getNewActivitiesStructureTypes({
    required String contractId,
  }) async {
    try {
      final List<Map<String, dynamic>> rows =
          await _api.fetchNewActivitiesStructureTypes(contractId: contractId);
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String type = (row['structure_type'] ?? row['structure_type_fk'] ?? '')
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

  Future<Result<List<DropdownOption>>> getNewActivitiesStructures({
    required String contractId,
    required String structureType,
  }) async {
    try {
      final List<Map<String, dynamic>> rows =
          await _api.fetchNewActivitiesStructures(
        contractId: contractId,
        structureType: structureType,
      );
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String id = (row['strip_chart_structure_id_fk'] ??
                row['structure'] ??
                row['strip_chart_structure'] ??
                '')
            .toString()
            .trim();
        return DropdownOption(id: id, name: id);
      }).where((DropdownOption o) => o.id.isNotEmpty).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load structures'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getNewActivitiesComponents({
    required String contractId,
    required String structureId,
    required String structureType,
  }) async {
    try {
      final List<Map<String, dynamic>> rows =
          await _api.fetchNewActivitiesComponents(
        contractId: contractId,
        structureId: structureId,
        structureType: structureType,
      );
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String id = (row['strip_chart_component'] ?? '').toString().trim();
        return DropdownOption(id: id, name: id);
      }).where((DropdownOption o) => o.id.isNotEmpty).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load components'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getNewActivitiesElements({
    required String contractId,
    required String structureId,
    required String component,
    required String structureType,
  }) async {
    try {
      final List<Map<String, dynamic>> rows =
          await _api.fetchNewActivitiesElements(
        contractId: contractId,
        structureId: structureId,
        component: component,
        structureType: structureType,
      );
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String id =
            (row['strip_chart_component_id'] ?? '').toString().trim();
        return DropdownOption(id: id, name: id);
      }).where((DropdownOption o) => o.id.isNotEmpty).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load elements'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<NewActivityRow>>> getNewActivitiesFiltersList({
    required String contractId,
    required String structureId,
    required String component,
    required String structureType,
    String elementId = '',
  }) async {
    try {
      final List<NewActivityRow> rows =
          await _api.fetchNewActivitiesFiltersList(
        contractId: contractId,
        structureId: structureId,
        component: component,
        structureType: structureType,
        elementId: elementId,
      );
      return Right(rows);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load activities'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<DropdownOption>>> getContractStructures({
    required String contractId,
  }) async {
    try {
      final List<Map<String, dynamic>> rows =
          await _api.fetchContractStructures(contractId: contractId);
      final List<DropdownOption> options = rows.map((Map<String, dynamic> row) {
        final String id = (row['strip_chart_structure_id_fk'] ??
                row['strip_chart_structure_id'] ??
                row['structure_id'] ??
                '')
            .toString()
            .trim();
        final String name = (row['strip_chart_structure_name'] ??
                row['structure_name'] ??
                row['strip_chart_structure_id_fk'] ??
                id)
            .toString()
            .trim();
        return DropdownOption(id: id, name: name.isEmpty ? id : name);
      }).where((DropdownOption o) => o.id.isNotEmpty).toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load structures'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<List<NewActivityRow>>> getModifyActualsFiltersList({
    required String contractId,
    String structureId = '',
    String searchStr = '',
  }) async {
    try {
      final List<NewActivityRow> rows =
          await _api.fetchModifyActualsFiltersList(
        contractId: contractId,
        structureId: structureId,
        searchStr: searchStr,
      );
      return Right(rows);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load activities'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Result<NewActivitiesLatestInfo?>> getNewActivitiesLatestRow() async {
    try {
      final NewActivitiesLatestInfo? info =
          await _api.fetchNewActivitiesLatestRow();
      return Right(info);
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Failed to load latest update'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(projectApiDataSourceProvider));
});
