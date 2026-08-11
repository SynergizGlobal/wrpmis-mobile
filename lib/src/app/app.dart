import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/app/config/app_config_provider.dart';
import 'package:wr_pmis_mobile/src/app/router/app_router.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/app/theme/theme_mode_provider.dart';
import 'package:wr_pmis_mobile/src/core/firebase/app_update_gate.dart';
import 'package:wr_pmis_mobile/src/core/firebase/remote_config_service.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    // Wait until the root navigator is attached.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) {
      return;
    }
    try {
      final AppUpdateInfo info =
          await ref.read(remoteConfigServiceProvider).evaluateUpdate();
      await AppUpdateGate.checkAndPrompt(info);
    } catch (error, stackTrace) {
      debugPrint('App update check failed: $error');
      debugPrint('$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
