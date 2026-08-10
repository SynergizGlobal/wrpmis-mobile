import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_table_pagination_footer.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_list_item.dart';
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
    'ID',
    'Name',
    'Status',
    'Type',
    'Railway Zone',
    'Plan Head No.',
    'Sanctioned Amount',
    'Sanctioned Year',
    'Sanctioned Date',
    'Division',
    'Section',
    'Remarks',
    'Action',
  ];

  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedType;
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
    final List<String> statusOptions = _options(
      rows,
      (ProjectListItem row) => row.projectStatus ?? '',
    );
    final List<String> typeOptions = _options(
      rows,
      (ProjectListItem row) => row.projectTypeName ?? '',
    );
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double tableWidth = _headers.fold<double>(
      0,
      (double sum, String header) => sum + _columnWidth(header),
    );

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: AppSelectSheetField<String>(
                  label: 'Project Status',
                  title: 'Select Project Status',
                  items: <String>['All', ...statusOptions],
                  value: _selectedStatus ?? 'All',
                  itemLabelBuilder: (String value) => value,
                  onChanged: (String value) {
                    setState(() {
                      _selectedStatus = value == 'All' ? null : value;
                      _currentPage = 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppSelectSheetField<String>(
                  label: 'Project Type',
                  title: 'Select Project Type',
                  items: <String>['All', ...typeOptions],
                  value: _selectedType ?? 'All',
                  itemLabelBuilder: (String value) => value,
                  onChanged: (String value) {
                    setState(() {
                      _selectedType = value == 'All' ? null : value;
                      _currentPage = 0;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: <Widget>[
              Expanded(
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                style: _rowButtonStyle,
                onPressed: (_selectedStatus != null ||
                        _selectedType != null ||
                        _searchQuery.isNotEmpty)
                    ? () => setState(() {
                          _selectedStatus = null;
                          _selectedType = null;
                          _searchQuery = '';
                          _currentPage = 0;
                          _searchController.clear();
                        })
                    : null,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Clear'),
              ),
            ],
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
                            'Excel export will be connected next.',
                            title: 'Excel',
                          ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Excel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: _outlinedRowButtonStyle,
                  onPressed: filtered.isEmpty
                      ? null
                      : () => GlobalDialog.info(
                            'PDF export will be connected next.',
                            title: 'PDF',
                          ),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('PDF'),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 132,
              child: FilledButton.icon(
                style: _rowButtonStyle,
                onPressed: () {
                  GlobalDialog.info(
                    'Add Project form will open here next.',
                    title: 'Add Project',
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ),
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
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outlineVariant),
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
                                _tableHeader(context),
                                Expanded(
                                  child: pageRows.isEmpty
                                      ? const Center(
                                          child: Text('No projects found.'),
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
    return rows.where((ProjectListItem row) {
      if (_selectedStatus != null &&
          (row.projectStatus ?? '').toLowerCase() !=
              _selectedStatus!.toLowerCase()) {
        return false;
      }
      if (_selectedType != null &&
          (row.projectTypeName ?? '').toLowerCase() !=
              _selectedType!.toLowerCase()) {
        return false;
      }
      if (q.isEmpty) {
        return true;
      }
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

  List<String> _options(
    List<ProjectListItem> rows,
    String Function(ProjectListItem) getter,
  ) {
    final Set<String> values = <String>{};
    for (final ProjectListItem row in rows) {
      final String value = getter(row).trim();
      if (value.isNotEmpty && value != '-') {
        values.add(value);
      }
    }
    final List<String> list = values.toList()..sort();
    return list;
  }

  Widget _tableHeader(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: _headers
            .map(
              (String title) => _cell(
                title,
                width: _columnWidth(title),
                color: colorScheme.onPrimary,
                weight: FontWeight.w700,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _tableRow(BuildContext context, ProjectListItem row, int index) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color bg = index.isEven
        ? colorScheme.primary.withValues(alpha: 0.08)
        : colorScheme.surface;
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          _cell(_display(row.projectId), width: _columnWidth('ID')),
          _cell(_display(row.projectName), width: _columnWidth('Name')),
          _cell(_display(row.projectStatus), width: _columnWidth('Status')),
          _cell(_display(row.projectTypeName), width: _columnWidth('Type')),
          _cell(
            _display(row.railwayZone),
            width: _columnWidth('Railway Zone'),
          ),
          _cell(
            _display(row.planHeadNumber),
            width: _columnWidth('Plan Head No.'),
          ),
          _cell(
            _display(row.sanctionedAmount),
            width: _columnWidth('Sanctioned Amount'),
          ),
          _cell(
            _display(row.sanctionedYear),
            width: _columnWidth('Sanctioned Year'),
          ),
          _cell(
            _display(row.sanctionedCompletionDate),
            width: _columnWidth('Sanctioned Date'),
          ),
          _cell(_display(row.division), width: _columnWidth('Division')),
          _cell(_display(row.sections), width: _columnWidth('Section')),
          _cell(_display(row.remarks), width: _columnWidth('Remarks')),
          SizedBox(
            width: _columnWidth('Action'),
            child: Center(
              child: IconButton(
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
                visualDensity: VisualDensity.compact,
                splashRadius: 16,
                onPressed: () {
                  GlobalDialog.info(
                    'Edit Project form will open here next.',
                    title: row.projectName,
                  );
                },
                icon: Icon(
                  Icons.edit_square,
                  size: 18,
                  color: colorScheme.primary,
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
          style: TextStyle(color: color, fontWeight: weight),
        ),
      ),
    );
  }

  String _display(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }
    return value.trim();
  }

  double _columnWidth(String header) {
    return switch (header) {
      'ID' => 56,
      'Name' => 210,
      'Status' => 96,
      'Type' => 140,
      'Railway Zone' => 120,
      'Plan Head No.' => 120,
      'Sanctioned Amount' => 155,
      'Sanctioned Year' => 130,
      'Sanctioned Date' => 130,
      'Division' => 96,
      'Section' => 110,
      'Remarks' => 160,
      'Action' => 64,
      _ => 100,
    };
  }
}
