import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wr_pmis_mobile/src/app/app.dart';
import 'package:wr_pmis_mobile/src/app/config/app_config.dart';
import 'package:wr_pmis_mobile/src/app/config/app_config_provider.dart';
import 'package:wr_pmis_mobile/src/core/config/shared_prefs_provider.dart';
import 'package:wr_pmis_mobile/src/core/firebase/firebase_bootstrap.dart';
import 'package:wr_pmis_mobile/src/core/firebase/remote_config_service.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  final RemoteConfigService remoteConfig = await initializeFirebaseServices();
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: <Override>[
        appConfigProvider.overrideWithValue(config),
        sharedPrefsProvider.overrideWithValue(prefs),
        remoteConfigServiceProvider.overrideWithValue(remoteConfig),
      ],
      child: const App(),
    ),
  );
}
