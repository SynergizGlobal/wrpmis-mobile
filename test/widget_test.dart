import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wr_pmis_mobile/src/app/app.dart';
import 'package:wr_pmis_mobile/src/app/config/app_config.dart';
import 'package:wr_pmis_mobile/src/app/config/app_config_provider.dart';
import 'package:wr_pmis_mobile/src/core/config/shared_prefs_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App boots to login', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appConfigProvider.overrideWithValue(
            const AppConfig(
              appName: 'WR PMIS',
              baseUrl: 'http://203.153.40.44:90/wrpmis/',
            ),
          ),
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('SIGN IN'), findsOneWidget);
  });
}
