import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/home_dashboard_data.dart';

final homeDashboardProvider =
    FutureProvider.autoDispose<HomeDashboardData>((ref) async {
  final result =
      await ref.watch(dashboardRepositoryProvider).getHomeDashboardData();
  return result.fold(
    (Failure failure) => throw Exception(failure.message),
    (HomeDashboardData data) => data,
  );
});
