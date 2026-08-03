import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
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
    final AsyncValue<ProjectDetailsData> detailsAsync = ref.watch(
      projectDetailsProvider(widget.projectTypeName),
    );
    final String heading =
        'Overall Status of Major Items in ${widget.projectTypeName} Projects';

    return Scaffold(
      appBar: AppBar(title: const Text('Project Details')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: detailsAsync.when(
            data: (ProjectDetailsData data) => _content(context, heading, data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(error.toString(), textAlign: TextAlign.center),
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
    String heading,
    ProjectDetailsData data,
  ) {
    final bool hasProjects = data.projectNames.isNotEmpty;
    final List<String> dropdownItems =
        hasProjects ? data.projectNames : <String>[];
    if (!hasProjects) {
      _selectedProject = null;
    } else if (_selectedProject == null ||
        !dropdownItems.contains(_selectedProject)) {
      _selectedProject = dropdownItems.first;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          heading,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        AppSelectSheetField<String>(
          key: ValueKey<String?>(
            dropdownItems.contains(_selectedProject) ? _selectedProject : null,
          ),
          label: 'Project',
          title: 'Select Project',
          leadingIcon: Icons.work_outline_rounded,
          items: dropdownItems,
          value: dropdownItems.contains(_selectedProject)
              ? _selectedProject
              : null,
          itemLabelBuilder: (String value) => value,
          enabled: hasProjects,
          placeholderText:
              hasProjects ? 'Select project' : 'No projects available',
          onChanged: (String value) => setState(() => _selectedProject = value),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: _selectedProject == null
                ? null
                : () {
                    final String projectId =
                        data.projectIdsByName[_selectedProject!]?.trim() ?? '';
                    GlobalDialog.info(
                      [
                        if (projectId.isNotEmpty) 'ID: $projectId',
                        'Type: ${widget.projectTypeName}',
                        'Project summary tabs will open here next.',
                      ].join('\n'),
                      title: _selectedProject!,
                    );
                  },
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Project Summary'),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: visibleItems.isEmpty
              ? const Center(
                  child: Text('No data available for selected project.'),
                )
              : ListView.separated(
                  itemCount: visibleItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    return _MajorItemCard(item: visibleItems[index]);
                  },
                ),
        ),
      ],
    );
  }
}

class _MajorItemCard extends StatelessWidget {
  const _MajorItemCard({required this.item});

  final ProjectMajorItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              item.item,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _metaRow(context, 'Unit', item.unit),
            _metaRow(context, 'Scope', item.scope),
            _metaRow(context, 'Completed', item.completed),
            _metaRow(context, 'Progress %', item.progressPercent),
            _metaRow(context, 'TDC', item.tdc, isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(
    BuildContext context,
    String label,
    String value, {
    bool isLast = false,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
