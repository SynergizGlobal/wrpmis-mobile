import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/constants/app_constants.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_action_card.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:wr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/app_module_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/home_dashboard_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/report_menu_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/update_form_module.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/work_category_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/home/providers/home_dashboard_provider.dart';
import 'package:wr_pmis_mobile/src/features/profile/presentation/pages/profile_page.dart';

enum _HomeSection { home, modules, works, updateForms, reports }

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  static const String routeName = 'home';
  static const String routePath = '/';

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;
  _HomeSection _section = _HomeSection.home;

  void _onBottomSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _section = switch (index) {
        0 => _HomeSection.home,
        1 => _HomeSection.modules,
        2 => _HomeSection.works,
        3 => _HomeSection.updateForms,
        4 => _HomeSection.reports,
        _ => _HomeSection.home,
      };
    });
  }

  String _titleForSection(_HomeSection section) {
    return switch (section) {
      _HomeSection.home => AppConstants.orgName,
      _HomeSection.modules => 'Modules',
      _HomeSection.works => 'Works',
      _HomeSection.updateForms => 'Update Forms',
      _HomeSection.reports => 'Reports',
    };
  }

  @override
  Widget build(BuildContext context) {
    final AuthSession? session = ref.watch(authControllerProvider).valueOrNull;
    final AppPalette palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
    final String initial = _initialFor(session);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: <Widget>[
            ClipOval(
              child: Image.asset(
                'assets/wr_logo.png',
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/app_icon.png',
                  width: 34,
                  height: 34,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _titleForSection(_section),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => context.pushNamed(ProfilePage.routeName),
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: palette.avatarFill,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: palette.avatarText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: switch (_section) {
          _HomeSection.home => const _HomeSectionView(key: ValueKey('home')),
          _HomeSection.modules =>
            const _ModulesSectionView(key: ValueKey('modules')),
          _HomeSection.works =>
            const _WorksSectionView(key: ValueKey('works')),
          _HomeSection.updateForms =>
            const _UpdateFormsSectionView(key: ValueKey('forms')),
          _HomeSection.reports =>
            const _ReportsSectionView(key: ValueKey('reports')),
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.45
                          : 0.55,
                    ),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.26
                            : 0.10,
                      ),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: <Widget>[
                    _bottomItem(
                      index: 0,
                      label: 'Home',
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                    ),
                    _bottomItem(
                      index: 1,
                      label: 'Modules',
                      icon: Icons.grid_view_outlined,
                      selectedIcon: Icons.grid_view_rounded,
                    ),
                    _bottomItem(
                      index: 2,
                      label: 'Works',
                      icon: Icons.engineering_outlined,
                      selectedIcon: Icons.engineering_rounded,
                    ),
                    _bottomItem(
                      index: 3,
                      label: 'Update Forms',
                      icon: Icons.edit_document,
                      selectedIcon: Icons.edit_document,
                    ),
                    _bottomItem(
                      index: 4,
                      label: 'Reports',
                      icon: Icons.bar_chart_outlined,
                      selectedIcon: Icons.bar_chart_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    final bool selected = _selectedIndex == index;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color selectedBackground = isDark
        ? colorScheme.primary.withValues(alpha: 0.42)
        : colorScheme.primary.withValues(alpha: 0.14);
    final Color selectedIconColor =
        isDark ? colorScheme.onPrimary : colorScheme.primary;
    final Color selectedTextColor =
        isDark ? colorScheme.onSurface : colorScheme.primary;
    final Color unselectedIconColor = colorScheme.onSurfaceVariant.withValues(
      alpha: isDark ? 0.96 : 0.86,
    );
    final Color unselectedTextColor = colorScheme.onSurfaceVariant.withValues(
      alpha: isDark ? 0.90 : 0.78,
    );

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _onBottomSelected(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? selectedBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: selected
                      ? Border.all(
                          color: isDark
                              ? colorScheme.primary.withValues(alpha: 0.46)
                              : colorScheme.primary.withValues(alpha: 0.28),
                        )
                      : null,
                ),
                child: Icon(
                  selected ? selectedIcon : icon,
                  color: selected ? selectedIconColor : unselectedIconColor,
                  size: selected ? 22 : 21,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 16,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? selectedTextColor : unselectedTextColor,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initialFor(AuthSession? session) {
    final String source = (session?.userName.trim().isNotEmpty ?? false)
        ? session!.userName.trim()
        : (session?.userId.isNotEmpty ?? false)
            ? session!.userId
            : 'U';
    return source.substring(0, 1).toUpperCase();
  }
}

class _HomeSectionView extends ConsumerWidget {
  const _HomeSectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeDashboardProvider);
    final AppPalette palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.light;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(homeDashboardProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object error, StackTrace stack) => _ErrorCard(
              message: error.toString(),
              onRetry: () => ref.invalidate(homeDashboardProvider),
            ),
            data: (HomeDashboardData data) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _SummaryCard(
                          label: 'Projects',
                          value: '${data.overview.projectsCount}',
                          color: palette.summaryCard,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Length',
                          value:
                              '${data.overview.totalLength.toStringAsFixed(2)} km',
                          color: palette.summaryCard,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Commissioned',
                          value:
                              '${data.overview.commissionedLength.toStringAsFixed(2)} km',
                          color: palette.summaryCard,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Project categories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  if (data.projectTypes.isEmpty)
                    const Text('No project categories available yet.')
                  else
                    ...data.projectTypes.map((HomeProjectType type) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppActionCard(
                          title: '${type.name} (${type.cumulativeCount})',
                          icon: Icons.account_tree_outlined,
                          onTap: () {
                            GlobalDialog.info(
                              '${type.name} — coming next',
                              title: type.name,
                            );
                          },
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportsSectionView extends StatelessWidget {
  const _ReportsSectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        ...ReportMenuItem.catalog.map((ReportMenuItem item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppActionCard(
              title: item.title,
              titleMaxLines: 2,
              icon: item.icon,
              onTap: () {
                GlobalDialog.info(
                  '${item.title} will open here next.',
                  title: item.title,
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

class _WorksSectionView extends StatelessWidget {
  const _WorksSectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        ...WorkCategoryItem.catalog.map((WorkCategoryItem item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppActionCard(
              title: item.title,
              titleMaxLines: 2,
              icon: item.icon,
              onTap: () {
                GlobalDialog.info(
                  '${item.title} will open here next.',
                  title: item.title,
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

class _ModulesSectionView extends StatelessWidget {
  const _ModulesSectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        ...AppModuleItem.catalog.map((AppModuleItem module) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppActionCard(
              title: module.title,
              titleMaxLines: 2,
              icon: module.icon,
              onTap: () {
                GlobalDialog.info(
                  '${module.title} will open here next.',
                  title: module.title,
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

class _UpdateFormsSectionView extends StatelessWidget {
  const _UpdateFormsSectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        ...UpdateFormModule.catalog.map((UpdateFormModule module) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppActionCard(
              title: module.title,
              titleMaxLines: 2,
              leftPlaceholder: _UpdateFormModuleIcon(module: module),
              onTap: () => _openModule(module),
            ),
          );
        }),
      ],
    );
  }

  void _openModule(UpdateFormModule module) {
    GlobalDialog.info(
      '${module.title} forms will open here next.',
      title: module.title,
    );
  }
}

class _UpdateFormModuleIcon extends StatelessWidget {
  const _UpdateFormModuleIcon({required this.module});

  final UpdateFormModule module;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String? asset = module.assetIcon;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colors.primary.withValues(alpha: 0.12),
      ),
      clipBehavior: Clip.antiAlias,
      child: asset == null
          ? Icon(module.icon, color: colors.primary, size: 22)
          : Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                module.icon,
                color: colors.primary,
                size: 22,
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
