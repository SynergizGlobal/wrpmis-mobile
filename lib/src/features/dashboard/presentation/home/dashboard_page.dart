import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/constants/app_constants.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_action_card.dart';
import 'package:wr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:wr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/home_dashboard_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/update_form_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/home/providers/home_dashboard_provider.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/home/providers/update_forms_provider.dart';
import 'package:wr_pmis_mobile/src/features/profile/presentation/pages/profile_page.dart';

enum _HomeSection { home, updateForms, profile }

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  static const String routeName = 'home';
  static const String routePath = '/';

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  _HomeSection _section = _HomeSection.home;

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
                AppConstants.orgName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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
          _HomeSection.updateForms =>
            const _UpdateFormsSectionView(key: ValueKey('forms')),
          _HomeSection.profile =>
            const ProfilePage(embedded: true, key: ValueKey('profile')),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _section.index,
        onDestinationSelected: (int index) {
          setState(() => _section = _HomeSection.values[index]);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note_rounded),
            label: 'Update Forms',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
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
          Row(
            children: <Widget>[
              Image.asset('assets/wr_logo.png', width: 42, height: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppConstants.orgName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              SvgPicture.asset(
                'assets/world_map.svg',
                width: 28,
                height: 28,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${type.name} — coming next'),
                              ),
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

class _UpdateFormsSectionView extends ConsumerWidget {
  const _UpdateFormsSectionView({super.key});

  static const Map<String, IconData> _iconHints = <String, IconData>{
    'project': Icons.folder_special_outlined,
    'work': Icons.engineering_outlined,
    'contract': Icons.description_outlined,
    'tender': Icons.description_outlined,
    'execution': Icons.timeline_outlined,
    'design': Icons.architecture_outlined,
    'drawing': Icons.architecture_outlined,
    'issue': Icons.report_problem_outlined,
    'land': Icons.landscape_outlined,
    'utility': Icons.electrical_services_outlined,
    'validate': Icons.verified_outlined,
    'alert': Icons.notifications_active_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(updateFormsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(updateFormsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Text(
            'Update Forms',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Forms from Western Railways PMIS',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object error, StackTrace stack) => _ErrorCard(
              message: error.toString(),
              onRetry: () => ref.invalidate(updateFormsProvider),
            ),
            data: (List<UpdateFormItem> items) {
              if (items.isEmpty) {
                return const _PlaceholderForms();
              }
              return Column(
                children: items.map((UpdateFormItem item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppActionCard(
                      title: item.formName,
                      subtitle: item.hasSubMenus
                          ? '${item.orderedSubMenus.length} sub forms'
                          : null,
                      icon: _iconFor(item.formName),
                      onTap: () => _openForm(context, item),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    final String lower = name.toLowerCase();
    for (final MapEntry<String, IconData> entry in _iconHints.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return Icons.edit_note_outlined;
  }

  void _openForm(BuildContext context, UpdateFormItem item) {
    if (!item.hasSubMenus) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.formName} — native form coming soon')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              Text(
                item.formName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              ...item.orderedSubMenus.map((UpdateFormSubItem sub) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.article_outlined),
                  title: Text(sub.formName),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${sub.formName} — native form coming soon',
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _PlaceholderForms extends StatelessWidget {
  const _PlaceholderForms();

  static const List<String> _defaults = <String>[
    'Projects',
    'Works',
    'Contracts/Tenders',
    'Execution & Monitoring',
    'Design & Drawing',
    'Issues',
    'Land Acquisition',
    'Utility Shifting',
    'Validate Data',
    'Alerts',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Showing reference modules (API empty / offline)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        ..._defaults.map((String name) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppActionCard(
              title: name,
              icon: Icons.edit_note_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name — native form coming soon')),
                );
              },
            ),
          );
        }),
      ],
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
