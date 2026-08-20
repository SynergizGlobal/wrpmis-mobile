import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_table_pagination_footer.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/structures/providers/structure_list_providers.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/structures/structure_form_page.dart';

/// Update Forms → Works → Structure list (matches web Structure screen).
class StructurePage extends ConsumerStatefulWidget {
  const StructurePage({super.key});

  static const String routeName = 'structure';
  static const String routePath = '/structure';

  @override
  ConsumerState<StructurePage> createState() => _StructurePageState();
}

class _StructurePageState extends ConsumerState<StructurePage> {
  static const List<int> _pageSizeOptions = <int>[5, 10, 25, 50, 100];

  final TextEditingController _searchController = TextEditingController();
  String? _selectedProjectId;
  String _searchQuery = '';
  int _pageSize = 10;
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  StructureListQuery get _query => StructureListQuery(
        projectId: _selectedProjectId,
        search: _searchQuery,
        page: _currentPage,
        pageSize: _pageSize,
      );

  void _clearFilters() {
    setState(() {
      _selectedProjectId = null;
      _searchQuery = '';
      _currentPage = 0;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AsyncValue<List<DropdownOption>> projectsAsync =
        ref.watch(structureProjectFilterProvider);
    final AsyncValue<StructureListResult> listAsync =
        ref.watch(structureListProvider(_query));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Structure'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.brandAppBar,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () async {
                final Object? changed =
                    await context.push(StructureFormPage.routePath);
                if (changed == true && mounted) {
                  ref.invalidate(structureListProvider(_query));
                  ref.invalidate(structureProjectFilterProvider);
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: projectsAsync.when(
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (Object e, StackTrace _) => Text(
                  'Unable to load projects: $e',
                  style: TextStyle(color: scheme.error),
                ),
                data: (List<DropdownOption> projects) {
                  final List<DropdownOption> items = <DropdownOption>[
                    const DropdownOption(id: '', name: 'Select'),
                    ...projects,
                  ];
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: AppSelectSheetField<String>(
                          label: 'Project',
                          title: 'Select Project',
                          items: items.map((DropdownOption e) => e.id).toList(),
                          value: _selectedProjectId ?? '',
                          itemLabelBuilder: (String id) {
                            return items
                                .firstWhere(
                                  (DropdownOption e) => e.id == id,
                                  orElse: () =>
                                      const DropdownOption(id: '', name: 'Select'),
                                )
                                .name;
                          },
                          onChanged: (String id) {
                            setState(() {
                              _selectedProjectId = id.isEmpty ? null : id;
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onPressed: (_selectedProjectId != null ||
                                _searchQuery.isNotEmpty)
                            ? _clearFilters
                            : null,
                        child: const Text('Clear Filters'),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (String value) {
                  setState(() {
                    _searchQuery = value.trim();
                    _currentPage = 0;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: () => setState(() {
                            _searchQuery = '';
                            _currentPage = 0;
                            _searchController.clear();
                          }),
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: listAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (Object error, StackTrace _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '$error',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: () =>
                                ref.invalidate(structureListProvider(_query)),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (StructureListResult page) {
                    final int total = page.filteredRecords;
                    final int pageCount =
                        total == 0 ? 1 : (total / _pageSize).ceil();
                    if (_currentPage >= pageCount) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _currentPage = pageCount - 1);
                        }
                      });
                    }
                    final int start =
                        total == 0 ? 0 : (_currentPage * _pageSize);
                    final int end = total == 0
                        ? 0
                        : (start + page.items.length).clamp(0, total);

                    return Column(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: palette.cardSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: palette.borderSubtle),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: <Widget>[
                                Container(
                                  color: scheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      _headerCell('Project', flex: 2),
                                      _headerCell('Structures', flex: 5),
                                      _headerCell('Action', flex: 1),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: page.items.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No structures found.',
                                            style: TextStyle(
                                              color: palette.mutedText,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: page.items.length,
                                          itemBuilder: (
                                            BuildContext context,
                                            int index,
                                          ) {
                                            return _row(
                                              context,
                                              page.items[index],
                                              index,
                                              palette,
                                              scheme,
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppTablePaginationFooter(
                          total: total,
                          startIndex: start,
                          endIndex: end,
                          currentPage: _currentPage,
                          pageCount: pageCount,
                          pageSize: _pageSize,
                          pageSizeOptions: _pageSizeOptions,
                          onPageSizeChanged: (int value) => setState(() {
                            _pageSize = value;
                            _currentPage = 0;
                          }),
                          onPrevious: _currentPage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                          onNext: end < total
                              ? () => setState(() => _currentPage++)
                              : null,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    StructureListItem item,
    int index,
    AppPalette palette,
    ColorScheme scheme,
  ) {
    final Color bg =
        index.isEven ? palette.tableRowEven : palette.tableRowOdd;
    final List<String> lines = item.structureLines;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              item.projectId,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: lines.isEmpty
                ? Text('-', style: TextStyle(color: palette.mutedText))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: lines
                        .map(
                          (String line) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              line,
                              style: TextStyle(
                                color: scheme.onSurface,
                                height: 1.25,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    final Object? changed = await context.push(
                      StructureFormPage.routePath,
                      extra: item.structureId,
                    );
                    if (changed == true && mounted) {
                      ref.invalidate(structureListProvider(_query));
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
