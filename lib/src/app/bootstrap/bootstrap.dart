import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wr_pmis_mobile/src/app/app.dart';
import 'package:wr_pmis_mobile/src/app/config/app_config.dart';
import 'package:wr_pmis_mobile/src/app/config/app_config_provider.dart';
import 'package:wr_pmis_mobile/src/core/config/shared_prefs_provider.dart';
import 'package:wr_pmis_mobile/src/core/firebase/firebase_bootstrap.dart';
import 'package:wr_pmis_mobile/src/core/firebase/remote_config_service.dart';
import 'package:wr_pmis_mobile/src/core/network/dio_client.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  final RemoteConfigService remoteConfig = await initializeFirebaseServices();
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      appConfigProvider.overrideWithValue(config),
      sharedPrefsProvider.overrideWithValue(prefs),
      remoteConfigServiceProvider.overrideWithValue(remoteConfig),
    ],
  );

  // Cookie jar must exist before any Dio call — otherwise an anonymous
  // JSESSIONID can be issued and later overwrite a real login session.
  await container.read(sessionCookieManagerProvider.future);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );
}
