import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/project_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

/// Provides dropdown data for the Add/Edit Project form.
final projectFormDataProvider =
    FutureProvider.autoDispose<ProjectFormData>((ref) async {
  final result = await ref.watch(projectRepositoryProvider).getProjectFormData();
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (ProjectFormData data) => data,
  );
});

/// Provides a single project for editing.
final projectByIdProvider =
    FutureProvider.autoDispose.family<ProjectDetail, String>((ref, id) async {
  final result = await ref.watch(projectRepositoryProvider).getProjectById(id);
  return result.fold(
    (Failure f) => throw Exception(f.message),
    (ProjectDetail data) => data,
  );
});
