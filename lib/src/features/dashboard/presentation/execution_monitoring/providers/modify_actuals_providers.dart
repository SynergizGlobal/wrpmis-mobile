import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/project_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/new_activity_row.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/execution_monitoring/providers/new_activities_update_providers.dart';

/// Reuse New Activities Update contracts list (short name).
final modifyActualsContractsProvider = newActivitiesContractsProvider;

final modifyActualsStructuresProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, String>((ref, contractId) async {
  if (contractId.isEmpty) {
    return const <DropdownOption>[];
  }
  final result = await ref
      .watch(projectRepositoryProvider)
      .getContractStructures(contractId: contractId);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

enum ModifyActualsAction {
  completedScopeZero,
  deleteByTaskCode,
  deleteByContract,
}

extension ModifyActualsActionX on ModifyActualsAction {
  String get label {
    switch (this) {
      case ModifyActualsAction.completedScopeZero:
        return 'Completed Scope / Actual Zero by Task Code';
      case ModifyActualsAction.deleteByTaskCode:
        return 'Delete activities by task code';
      case ModifyActualsAction.deleteByContract:
        return 'Delete activities by contract';
    }
  }

  bool get requiresStructure => this == ModifyActualsAction.deleteByContract;
}

class ModifyActualsListQuery {
  const ModifyActualsListQuery({
    required this.action,
    required this.contractId,
    this.structureId = '',
    this.searchStr = '',
  });

  final ModifyActualsAction? action;
  final String contractId;
  final String structureId;
  final String searchStr;

  bool get isReady {
    if (action == null || contractId.isEmpty) {
      return false;
    }
    if (action!.requiresStructure && structureId.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    return other is ModifyActualsListQuery &&
        other.action == action &&
        other.contractId == contractId &&
        other.structureId == structureId &&
        other.searchStr == searchStr;
  }

  @override
  int get hashCode => Object.hash(action, contractId, structureId, searchStr);
}

final modifyActualsListProvider = FutureProvider.autoDispose
    .family<List<NewActivityRow>, ModifyActualsListQuery>((ref, query) async {
  if (!query.isReady) {
    return const <NewActivityRow>[];
  }
  final result =
      await ref.watch(projectRepositoryProvider).getModifyActualsFiltersList(
            contractId: query.contractId,
            structureId: query.action!.requiresStructure ? query.structureId : '',
            searchStr: query.searchStr,
          );
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<NewActivityRow> data) => data,
  );
});
