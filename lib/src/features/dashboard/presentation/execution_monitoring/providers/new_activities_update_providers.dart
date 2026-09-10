import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/project_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/new_activity_row.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

final newActivitiesProjectsProvider =
    FutureProvider.autoDispose<List<DropdownOption>>((ref) async {
  final result =
      await ref.watch(projectRepositoryProvider).getNewActivitiesProjects();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final newActivitiesContractsProvider =
    FutureProvider.autoDispose<List<DropdownOption>>((ref) async {
  final result =
      await ref.watch(projectRepositoryProvider).getNewActivitiesContracts();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

final newActivitiesStructureTypesProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, String>((ref, contractId) async {
  if (contractId.isEmpty) {
    return const <DropdownOption>[];
  }
  final result = await ref
      .watch(projectRepositoryProvider)
      .getNewActivitiesStructureTypes(contractId: contractId);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

class NewActivitiesStructuresQuery {
  const NewActivitiesStructuresQuery({
    required this.contractId,
    required this.structureType,
  });

  final String contractId;
  final String structureType;

  @override
  bool operator ==(Object other) {
    return other is NewActivitiesStructuresQuery &&
        other.contractId == contractId &&
        other.structureType == structureType;
  }

  @override
  int get hashCode => Object.hash(contractId, structureType);
}

final newActivitiesStructuresProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, NewActivitiesStructuresQuery>(
        (ref, query) async {
  if (query.contractId.isEmpty || query.structureType.isEmpty) {
    return const <DropdownOption>[];
  }
  final result =
      await ref.watch(projectRepositoryProvider).getNewActivitiesStructures(
            contractId: query.contractId,
            structureType: query.structureType,
          );
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

class NewActivitiesComponentsQuery {
  const NewActivitiesComponentsQuery({
    required this.contractId,
    required this.structureId,
    required this.structureType,
  });

  final String contractId;
  final String structureId;
  final String structureType;

  @override
  bool operator ==(Object other) {
    return other is NewActivitiesComponentsQuery &&
        other.contractId == contractId &&
        other.structureId == structureId &&
        other.structureType == structureType;
  }

  @override
  int get hashCode => Object.hash(contractId, structureId, structureType);
}

final newActivitiesComponentsProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, NewActivitiesComponentsQuery>(
        (ref, query) async {
  if (query.contractId.isEmpty ||
      query.structureId.isEmpty ||
      query.structureType.isEmpty) {
    return const <DropdownOption>[];
  }
  final result =
      await ref.watch(projectRepositoryProvider).getNewActivitiesComponents(
            contractId: query.contractId,
            structureId: query.structureId,
            structureType: query.structureType,
          );
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

class NewActivitiesElementsQuery {
  const NewActivitiesElementsQuery({
    required this.contractId,
    required this.structureId,
    required this.component,
    required this.structureType,
  });

  final String contractId;
  final String structureId;
  final String component;
  final String structureType;

  @override
  bool operator ==(Object other) {
    return other is NewActivitiesElementsQuery &&
        other.contractId == contractId &&
        other.structureId == structureId &&
        other.component == component &&
        other.structureType == structureType;
  }

  @override
  int get hashCode =>
      Object.hash(contractId, structureId, component, structureType);
}

final newActivitiesElementsProvider = FutureProvider.autoDispose
    .family<List<DropdownOption>, NewActivitiesElementsQuery>((ref, query) async {
  if (query.contractId.isEmpty ||
      query.structureId.isEmpty ||
      query.component.isEmpty ||
      query.structureType.isEmpty) {
    return const <DropdownOption>[];
  }
  final result =
      await ref.watch(projectRepositoryProvider).getNewActivitiesElements(
            contractId: query.contractId,
            structureId: query.structureId,
            component: query.component,
            structureType: query.structureType,
          );
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<DropdownOption> data) => data,
  );
});

class NewActivitiesListQuery {
  const NewActivitiesListQuery({
    required this.contractId,
    required this.structureId,
    required this.component,
    required this.structureType,
    this.elementId = '',
  });

  final String contractId;
  final String structureId;
  final String component;
  final String structureType;
  final String elementId;

  bool get isReady =>
      contractId.isNotEmpty &&
      structureId.isNotEmpty &&
      component.isNotEmpty &&
      structureType.isNotEmpty;

  @override
  bool operator ==(Object other) {
    return other is NewActivitiesListQuery &&
        other.contractId == contractId &&
        other.structureId == structureId &&
        other.component == component &&
        other.structureType == structureType &&
        other.elementId == elementId;
  }

  @override
  int get hashCode => Object.hash(
        contractId,
        structureId,
        component,
        structureType,
        elementId,
      );
}

final newActivitiesListProvider = FutureProvider.autoDispose
    .family<List<NewActivityRow>, NewActivitiesListQuery>((ref, query) async {
  if (!query.isReady) {
    return const <NewActivityRow>[];
  }
  final result =
      await ref.watch(projectRepositoryProvider).getNewActivitiesFiltersList(
            contractId: query.contractId,
            structureId: query.structureId,
            component: query.component,
            structureType: query.structureType,
            elementId: query.elementId,
          );
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (List<NewActivityRow> data) => data,
  );
});

final newActivitiesLatestProvider =
    FutureProvider.autoDispose<NewActivitiesLatestInfo?>((ref) async {
  final result =
      await ref.watch(projectRepositoryProvider).getNewActivitiesLatestRow();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (NewActivitiesLatestInfo? data) => data,
  );
});
