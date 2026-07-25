import 'package:wr_pmis_mobile/src/core/config/env.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_hosts.dart';

export 'package:wr_pmis_mobile/src/core/config/env.dart';

class Environment {
  Environment._();

  static late Env _env;

  static void init(Env env) {
    _env = env;
  }

  static Env get current => _env;

  static bool get isQa => _env == Env.qa;

  static String get wrBaseUrl {
    switch (_env) {
      case Env.qa:
        return ApiHosts.qaBaseUrl;
      case Env.prod:
        return ApiHosts.prodBaseUrl;
    }
  }

  static Uri get wrOriginUri => ApiHosts.originUriFor(wrBaseUrl);
}
