import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wr_pmis_mobile/src/app/router/go_router_refresh.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:wr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:wr_pmis_mobile/src/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:wr_pmis_mobile/src/features/auth/presentation/pages/login_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/home/dashboard_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/projects/add_project_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/projects/project_details_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/projects/project_form_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/structures/structure_form_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/structures/structure_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/structures/technical_assistance_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/structures/update_structure_page.dart';
import 'package:wr_pmis_mobile/src/features/profile/presentation/pages/profile_page.dart';
import 'package:wr_pmis_mobile/src/features/settings/presentation/pages/settings_page.dart';

final goRouterRefreshProvider = Provider<GoRouterRefresh>((ref) {
  final GoRouterRefresh notifier = GoRouterRefresh();
  ref.listen<AsyncValue<AuthSession?>>(authControllerProvider, (
    AsyncValue<AuthSession?>? previous,
    AsyncValue<AuthSession?> next,
  ) {
    notifier.notifyAuthChanged();
  });
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final GoRouterRefresh refresh = ref.watch(goRouterRefreshProvider);
  return GoRouter(
    navigatorKey: GlobalDialog.navigatorKey,
    initialLocation: LoginPage.routePath,
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final ProviderContainer container = ProviderScope.containerOf(context);
      final bool loggedIn =
          container.read(authControllerProvider).valueOrNull != null;
      final String loc = state.matchedLocation;

      final bool isPublic = loc == LoginPage.routePath ||
          loc == ForgotPasswordPage.routePath;
      if (!loggedIn && !isPublic) {
        return LoginPage.routePath;
      }
      if (loggedIn && loc == LoginPage.routePath) {
        return DashboardPage.routePath;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: LoginPage.routePath,
        name: LoginPage.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPage(),
      ),
      GoRoute(
        path: ForgotPasswordPage.routePath,
        name: ForgotPasswordPage.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const ForgotPasswordPage(),
      ),
      GoRoute(
        path: DashboardPage.routePath,
        name: DashboardPage.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const DashboardPage(),
      ),
      GoRoute(
        path: ProjectDetailsPage.routePath,
        name: ProjectDetailsPage.routeName,
        builder: (BuildContext context, GoRouterState state) {
          final String projectTypeName =
              state.extra is String ? state.extra! as String : 'Projects';
          return ProjectDetailsPage(projectTypeName: projectTypeName);
        },
      ),
      GoRoute(
        path: AddProjectPage.routePath,
        name: AddProjectPage.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const AddProjectPage(),
      ),
      GoRoute(
        path: ProjectFormPage.routePath,
        name: ProjectFormPage.routeName,
        builder: (BuildContext context, GoRouterState state) {
          final String? projectId =
              state.extra is String ? state.extra as String : null;
          return ProjectFormPage(projectId: projectId);
        },
      ),
      GoRoute(
        path: StructureFormPage.routePath,
        name: StructureFormPage.routeName,
        builder: (BuildContext context, GoRouterState state) {
          final String? structureId =
              state.extra is String ? state.extra as String : null;
          return StructureFormPage(structureId: structureId);
        },
      ),
      GoRoute(
        path: StructurePage.routePath,
        name: StructurePage.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const StructurePage(),
      ),
      GoRoute(
        path: UpdateStructurePage.routePath,
        name: UpdateStructurePage.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const UpdateStructurePage(),
      ),
      GoRoute(
        path: TechnicalAssistancePage.routePath,
        name: TechnicalAssistancePage.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const TechnicalAssistancePage(),
      ),
      GoRoute(
        path: ProfilePage.routePath,
        name: ProfilePage.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const ProfilePage(),
      ),
      GoRoute(
        path: SettingsPage.routePath,
        name: SettingsPage.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsPage(),
      ),
    ],
  );
});
