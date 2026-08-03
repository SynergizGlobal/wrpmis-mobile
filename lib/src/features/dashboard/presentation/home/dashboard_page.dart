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
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/projects/add_project_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/projects/project_details_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/structures/structure_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/structures/technical_assistance_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/structures/update_structure_page.dart';
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

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(homeDashboardProvider),
      child: async.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const <Widget>[
            SizedBox(height: 120),
            Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (Object error, StackTrace stack) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            _ErrorCard(
              message: error.toString(),
              onRetry: () => ref.invalidate(homeDashboardProvider),
            ),
          ],
        ),
        data: (HomeDashboardData data) {
          final int derivedProjectsCount = data.projectTypes.fold<int>(
            0,
            (int sum, HomeProjectType type) => sum + type.cumulativeCount,
          );
          final int totalProjects = data.overview.projectsCount > 0
              ? data.overview.projectsCount
              : derivedProjectsCount;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: <Widget>[
                _HomeSummaryStats(
                  projectsCount: totalProjects,
                  totalLength: data.overview.totalLength,
                  commissionedLength: data.overview.commissionedLength,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: data.projectTypes.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const <Widget>[
                            AppActionCard(
                              title: 'No project categories available yet.',
                              showLeading: false,
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: data.projectTypes.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (BuildContext context, int index) {
                            final HomeProjectType type =
                                data.projectTypes[index];
                            return AppActionCard(
                              title:
                                  '${type.name} (${type.cumulativeCount})',
                              showLeading: false,
                              titleMaxLines: 2,
                              onTap: () {
                                context.pushNamed(
                                  ProjectDetailsPage.routeName,
                                  extra: type.name,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
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
              onTap: () => _openModule(context, module),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _openModule(
    BuildContext context,
    UpdateFormModule module,
  ) async {
    final List<UpdateFormSubItem> subItems = module.subItems;
    if (subItems.isEmpty) {
      GlobalDialog.info(
        '${module.title} forms will open here next.',
        title: module.title,
      );
      return;
    }

    if (subItems.length == 1) {
      _openSubItem(context, subItems.first);
      return;
    }

    final UpdateFormSubItem? selected =
        await showModalBottomSheet<UpdateFormSubItem>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: subItems.length,
            separatorBuilder: (BuildContext context, int _) => Divider(
              height: 1,
              thickness: 0.8,
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.55),
            ),
            itemBuilder: (BuildContext context, int index) {
              final UpdateFormSubItem sub = subItems[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(sub.icon),
                title: Text(sub.title),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).pop(sub),
              );
            },
          ),
        );
      },
    );
    if (!context.mounted || selected == null) {
      return;
    }
    _openSubItem(context, selected);
  }

  void _openSubItem(BuildContext context, UpdateFormSubItem item) {
    switch (item.id) {
      case 'add_project':
        context.pushNamed(AddProjectPage.routeName);
        return;
      case 'structure':
        context.pushNamed(StructurePage.routeName);
        return;
      case 'update_structure':
        context.pushNamed(UpdateStructurePage.routeName);
        return;
      case 'technical_assistance':
        context.pushNamed(TechnicalAssistancePage.routeName);
        return;
      default:
        GlobalDialog.info(
          '${item.title} will open here next.',
          title: item.title,
        );
    }
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

class _HomeSummaryStats extends StatelessWidget {
  const _HomeSummaryStats({
    required this.projectsCount,
    required this.totalLength,
    required this.commissionedLength,
  });

  final int projectsCount;
  final double totalLength;
  final double commissionedLength;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _SummaryStatCard(
            label: 'Projects',
            value: projectsCount.toString(),
            icon: Icons.approval_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryStatCard(
            label: 'Length',
            value: '${totalLength.toStringAsFixed(2)} km',
            icon: Icons.straighten_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryStatCard(
            label: 'Commissioned',
            value: '${commissionedLength.toStringAsFixed(2)} km',
            icon: Icons.track_changes_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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
