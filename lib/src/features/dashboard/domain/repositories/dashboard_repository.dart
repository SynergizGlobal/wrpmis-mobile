import 'package:wr_pmis_mobile/src/core/result/result.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/home_dashboard_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/update_form_item.dart';

abstract class DashboardRepository {
  Future<Result<HomeDashboardData>> getHomeDashboardData();
  Future<Result<ProjectDetailsData>> getProjectDetailsByType(
    String projectTypeName,
  );
  Future<Result<List<UpdateFormItem>>> getUpdateForms();
}
