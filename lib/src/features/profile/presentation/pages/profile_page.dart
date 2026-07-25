import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_action_card.dart';
import 'package:wr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:wr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:wr_pmis_mobile/src/features/auth/presentation/pages/login_page.dart';
import 'package:wr_pmis_mobile/src/features/settings/presentation/pages/settings_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, this.embedded = false});

  static const String routeName = 'profile';
  static const String routePath = '/profile';

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthSession? session = ref.watch(authControllerProvider).valueOrNull;
    final AppPalette palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
    final String initial = _resolveInitial(session);

    final Widget body = SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Center(
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: palette.avatarFill,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: palette.avatarText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _infoCard(
                  context,
                  title: 'Basic Details',
                  rows: <MapEntry<String, String>>[
                    MapEntry('Name', session?.userName ?? '-'),
                    MapEntry('User ID', session?.userId ?? '-'),
                    MapEntry(
                      'Email',
                      session?.emailId.isNotEmpty == true
                          ? session!.emailId
                          : '-',
                    ),
                    MapEntry(
                      'Role',
                      session?.userRoleNameFk.isNotEmpty == true
                          ? session!.userRoleNameFk
                          : '-',
                    ),
                    MapEntry(
                      'Designation',
                      session?.designation.isNotEmpty == true
                          ? session!.designation
                          : '-',
                    ),
                    MapEntry(
                      'Department',
                      session?.departmentFk.isNotEmpty == true
                          ? session!.departmentFk
                          : '-',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppActionCard(
                  title: 'Settings',
                  icon: Icons.settings_outlined,
                  onTap: () => context.pushNamed(SettingsPage.routeName),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder:
                  (BuildContext context, AsyncSnapshot<PackageInfo> snap) {
                final String version = _resolveVersionText(snap);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .logout();
                          if (context.mounted) {
                            context.goNamed(LoginPage.routeName);
                          }
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Log out'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'App Version : $version',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );

    if (embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: body,
    );
  }

  String _resolveVersionText(AsyncSnapshot<PackageInfo> snap) {
    if (snap.hasData) {
      final String version = snap.data!.version.trim();
      final String build = snap.data!.buildNumber.trim();
      final String safeVersion = version.isEmpty ? '1.0.0' : version;
      final String safeBuild = build.isEmpty ? '1' : build;
      return '$safeVersion ($safeBuild)';
    }
    return '1.0.0 (1)';
  }

  String _resolveInitial(AuthSession? session) {
    final String source = (session?.userName.trim().isNotEmpty ?? false)
        ? session!.userName.trim()
        : (session?.userId.isNotEmpty ?? false)
            ? session!.userId
            : 'U';
    return source.substring(0, 1).toUpperCase();
  }

  Widget _infoCard(
    BuildContext context, {
    required String title,
    required List<MapEntry<String, String>> rows,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ...rows.map((MapEntry<String, String> row) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 110,
                      child: Text(
                        row.key,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
