import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_table_pagination_footer.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/projects/project_form_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/projects/providers/project_list_provider.dart';

class AddProjectPage extends ConsumerStatefulWidget {
  const AddProjectPage({super.key});

  static const String routeName = 'add-project';
  static const String routePath = '/add-project';

  @override
  ConsumerState<AddProjectPage> createState() => _AddProjectPageState();
}

class _AddProjectPageState extends ConsumerState<AddProjectPage> {
  static const List<int> _pageSizeOptions = <int>[5, 10, 25, 50, 100];
  static const List<String> _headers = <String>[
    'Project ID',
    'Project Name',
    'Project Status',
    'Project Type',
    'Railway Zone',
    'Plan Head Number',
    'Sanctioned Year',
    'Sanctioned Amount',
    'Sanctioned Commis',
    'Division',
    'Sections',
    'Remarks',
    'Action',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _pageSize = 10;
  int _currentPage = 0;

  static final ButtonStyle _rowButtonStyle = FilledButton.styleFrom(
    minimumSize: const Size(0, 44),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  static final ButtonStyle _outlinedRowButtonStyle = OutlinedButton.styleFrom(
    minimumSize: const Size(0, 44),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ProjectListItem>> async =
        ref.watch(projectListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Project')),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: async.when(
            data: (List<ProjectListItem> rows) => _content(context, rows),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => ref.invalidate(projectListProvider),
                      child: const Text('Retry'),
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

  Widget _content(BuildContext context, List<ProjectListItem> rows) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<ProjectListItem> filtered = _filtered(rows);
    final int total = filtered.length;
    final int pageCount = total == 0 ? 1 : (total / _pageSize).ceil();
    if (_currentPage >= pageCount) {
      _currentPage = pageCount - 1;
    }
    final int start = total == 0 ? 0 : (_currentPage * _pageSize);
    final int end = total == 0 ? 0 : (start + _pageSize).clamp(0, total);
    final List<ProjectListItem> pageRows =
        total == 0 ? const <ProjectListItem>[] : filtered.sublist(start, end);
    final double tableWidth = _headers.fold<double>(
      0,
      (double sum, String header) => sum + _columnWidth(header),
    );

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (String value) {
              setState(() {
                _searchQuery = value.trim();
                _currentPage = 0;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search...',
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
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  style: _outlinedRowButtonStyle,
                  onPressed: filtered.isEmpty
                      ? null
                      : () => GlobalDialog.info(
                            'Export will be connected next.',
                            title: 'Export',
                          ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: _rowButtonStyle.copyWith(
                    backgroundColor:
                        WidgetStatePropertyAll<Color>(scheme.primary),
                    foregroundColor:
                        WidgetStatePropertyAll<Color>(scheme.onPrimary),
                  ),
                  onPressed: () {
                    context.push(ProjectFormPage.routePath);
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.borderSubtle),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (
                        BuildContext context,
                        BoxConstraints constraints,
                      ) {
                        final double width = tableWidth < constraints.maxWidth
                            ? constraints.maxWidth
                            : tableWidth;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: width,
                            child: Column(
                              children: <Widget>[
                                _tableHeader(context, scheme),
                                Expanded(
                                  child: pageRows.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No projects found.',
                                            style: TextStyle(
                                              color: palette.mutedText,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: pageRows.length,
                                          itemBuilder: (
                                            BuildContext context,
                                            int index,
                                          ) {
                                            return _tableRow(
                                              context,
                                              pageRows[index],
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
                        );
                      },
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
                  onNext:
                      end < total ? () => setState(() => _currentPage++) : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<ProjectListItem> _filtered(List<ProjectListItem> rows) {
    final String q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return rows;
    }
    return rows.where((ProjectListItem row) {
      final String haystack = <String?>[
        row.projectId,
        row.projectName,
        row.projectStatus,
        row.projectTypeName,
        row.railwayZone,
        row.planHeadNumber,
        row.sanctionedAmount,
        row.sanctionedYear,
        row.sanctionedCompletionDate,
        row.division,
        row.sections,
        row.remarks,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  Widget _tableHeader(BuildContext context, ColorScheme scheme) {
    return Container(
      color: scheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: _headers
            .map(
              (String title) => _cell(
                title,
                width: _columnWidth(title),
                color: scheme.onPrimary,
                weight: FontWeight.w700,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _tableRow(
    BuildContext context,
    ProjectListItem row,
    int index,
    AppPalette palette,
    ColorScheme scheme,
  ) {
    final Color bg =
        index.isEven ? palette.tableRowEven : palette.tableRowOdd;
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          _cell(_display(row.projectId), width: _columnWidth('Project ID')),
          _cell(_display(row.projectName), width: _columnWidth('Project Name')),
          _cell(
            _display(row.projectStatus),
            width: _columnWidth('Project Status'),
          ),
          _cell(
            _display(row.projectTypeName),
            width: _columnWidth('Project Type'),
          ),
          _cell(
            _display(row.railwayZone),
            width: _columnWidth('Railway Zone'),
          ),
          _cell(
            _display(row.planHeadNumber),
            width: _columnWidth('Plan Head Number'),
          ),
          _cell(
            _display(row.sanctionedYear),
            width: _columnWidth('Sanctioned Year'),
          ),
          _cell(
            _formatAmount(row.sanctionedAmount),
            width: _columnWidth('Sanctioned Amount'),
          ),
          _cell(
            _display(row.sanctionedCompletionDate),
            width: _columnWidth('Sanctioned Commis'),
          ),
          _cell(_display(row.division), width: _columnWidth('Division')),
          _cell(_display(row.sections), width: _columnWidth('Sections')),
          _cell(_display(row.remarks), width: _columnWidth('Remarks')),
          SizedBox(
            width: _columnWidth('Action'),
            child: Center(
              child: Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    context.push(
                      ProjectFormPage.routePath,
                      extra: row.projectId,
                    );
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

  Widget _cell(
    String value, {
    required double width,
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color ?? Theme.of(context).colorScheme.onSurface,
            fontWeight: weight,
          ),
        ),
      ),
    );
  }

  String _display(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }
    return value.trim();
  }

  String _formatAmount(String? value) {
    final String raw = _display(value);
    if (raw.isEmpty) {
      return '';
    }
    final double? amount = double.tryParse(raw.replaceAll(',', ''));
    if (amount == null) {
      return raw;
    }
    final List<String> parts = amount.toStringAsFixed(2).split('.');
    final String whole = parts.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
    return '$whole.${parts.last}';
  }

  double _columnWidth(String header) {
    return switch (header) {
      'Project ID' => 92,
      'Project Name' => 230,
      'Project Status' => 120,
      'Project Type' => 170,
      'Railway Zone' => 120,
      'Plan Head Number' => 140,
      'Sanctioned Year' => 130,
      'Sanctioned Amount' => 160,
      'Sanctioned Commis' => 150,
      'Division' => 96,
      'Sections' => 110,
      'Remarks' => 180,
      'Action' => 72,
      _ => 100,
    };
  }
}
