import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/update_form_item.dart';

final updateFormsProvider =
    FutureProvider.autoDispose<List<UpdateFormItem>>((ref) async {
  final result = await ref.watch(dashboardRepositoryProvider).getUpdateForms();
  return result.fold(
    (Failure failure) => throw Exception(failure.message),
    (List<UpdateFormItem> items) => items,
  );
});
