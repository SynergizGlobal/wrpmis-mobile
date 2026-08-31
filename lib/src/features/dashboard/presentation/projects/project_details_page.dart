import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/home_dashboard_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/projects/providers/project_details_provider.dart';

class ProjectDetailsPage extends ConsumerStatefulWidget {
  const ProjectDetailsPage({super.key, required this.projectTypeName});

  static const String routeName = 'project-details';
  static const String routePath = '/project-details';

  final String projectTypeName;

  @override
  ConsumerState<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends ConsumerState<ProjectDetailsPage> {
  String? _selectedProject;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AsyncValue<ProjectDetailsData> detailsAsync = ref.watch(
      projectDetailsProvider(widget.projectTypeName),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Project Details')),
      body: SafeArea(
        child: detailsAsync.when(
          data: (ProjectDetailsData data) => _content(
            context,
            data,
            palette,
            scheme,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(
                      projectDetailsProvider(widget.projectTypeName),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    ProjectDetailsData data,
    AppPalette palette,
    ColorScheme scheme,
  ) {
    final bool hasProjects = data.projectNames.isNotEmpty;
    if (!hasProjects) {
      _selectedProject = null;
    } else if (_selectedProject == null ||
        !data.projectNames.contains(_selectedProject)) {
      _selectedProject = data.projectNames.first;
    }

    final List<ProjectMajorItem> visibleItems =
        !hasProjects || _selectedProject == null
            ? <ProjectMajorItem>[]
            : data.items
                .where(
                  (ProjectMajorItem item) =>
                      item.projectName == _selectedProject,
                )
                .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Overall Status of Major Items in ${widget.projectTypeName} Projects',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: !hasProjects
                ? Center(
                    child: Text(
                      'No projects available.',
                      style: TextStyle(color: palette.mutedText),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        width: 148,
                        child: _ProjectSidebar(
                          names: data.projectNames,
                          selected: _selectedProject,
                          palette: palette,
                          scheme: scheme,
                          onSelect: (String name) {
                            setState(() => _selectedProject = name);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MajorItemsTable(
                          items: visibleItems,
                          palette: palette,
                          scheme: scheme,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProjectSidebar extends StatelessWidget {
  const _ProjectSidebar({
    required this.names,
    required this.selected,
    required this.palette,
    required this.scheme,
    required this.onSelect,
  });

  final List<String> names;
  final String? selected;
  final AppPalette palette;
  final ColorScheme scheme;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: names.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final String name = names[index];
        final bool isSelected = name == selected;
        return Material(
          color: isSelected
              ? scheme.primary.withValues(alpha: 0.12)
              : palette.cardSurface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onSelect(name),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? scheme.primary : palette.borderSubtle,
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? scheme.primary : scheme.onSurface,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MajorItemsTable extends StatelessWidget {
  const _MajorItemsTable({
    required this.items,
    required this.palette,
    required this.scheme,
  });

  final List<ProjectMajorItem> items;
  final AppPalette palette;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: <Widget>[
            _TableHeader(scheme: scheme),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Major item progress is not in the project list API yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.mutedText),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: palette.borderSubtle,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        return _TableRow(
                          item: items[index],
                          index: index,
                          palette: palette,
                          scheme: scheme,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: <Widget>[
          _HeaderCell('Item', flex: 3, scheme: scheme),
          _HeaderCell('Scope', flex: 2, scheme: scheme),
          _HeaderCell('Completed', flex: 2, scheme: scheme),
          _HeaderCell('Progress', flex: 2, scheme: scheme),
          _HeaderCell('TDC', flex: 2, scheme: scheme),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex, required this.scheme});

  final String label;
  final int flex;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.item,
    required this.index,
    required this.palette,
    required this.scheme,
  });

  final ProjectMajorItem item;
  final int index;
  final AppPalette palette;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final Color rowColor =
        index.isEven ? palette.tableRowEven : palette.tableRowOdd;
    final TextStyle style = Theme.of(context).textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        );

    return ColoredBox(
      color: rowColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _BodyCell(item.item, flex: 3, style: style),
            _BodyCell(
              '${item.scope} ${item.unit}'.trim(),
              flex: 2,
              style: style,
            ),
            _BodyCell(
              '${item.completed} ${item.unit}'.trim(),
              flex: 2,
              style: style,
            ),
            _BodyCell(item.progressPercent, flex: 2, style: style),
            _BodyCell(item.tdc, flex: 2, style: style),
          ],
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.value, {required this.flex, required this.style});

  final String value;
  final int flex;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(value == '-' || value.isEmpty ? '-' : value, style: style),
    );
  }
}
