import 'package:wr_pmis_mobile/src/app/bootstrap/bootstrap.dart';
import 'package:wr_pmis_mobile/src/app/config/app_config.dart';
import 'package:wr_pmis_mobile/src/core/config/environment.dart';
import 'package:wr_pmis_mobile/src/core/constants/app_constants.dart';

Future<void> main() async {
  Environment.init(Env.qa);

  await bootstrap(
    AppConfig(
      appName: Environment.isQa
          ? '${AppConstants.appName} (QA)'
          : AppConstants.appName,
      baseUrl: Environment.wrBaseUrl,
    ),
  );
}
