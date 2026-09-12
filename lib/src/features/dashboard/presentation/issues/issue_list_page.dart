import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_global_loader.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_table_pagination_footer.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/issue_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/issues/issue_form_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/issues/providers/issue_list_providers.dart';

/// Update Forms → Issues.
class IssueListPage extends ConsumerStatefulWidget {
  const IssueListPage({super.key});

  static const String routeName = 'issues';
  static const String routePath = '/issues';

  @override
  ConsumerState<IssueListPage> createState() => _IssueListPageState();
}

class _IssueListPageState extends ConsumerState<IssueListPage> {
  static const List<int> _pageSizeOptions = <int>[5, 10, 25, 50, 100];
  static const List<String> _headers = <String>[
    'Contract',
    'Short Description',
    'Location',
    'Responsible Person',
    'Department',
    'Issue Status',
    'Last Update',
    'Action',
  ];

  final TextEditingController _searchController = TextEditingController();
  String? _contractId;
  String? _hod;
  String? _department;
  String? _category;
  String? _status;
  String _searchQuery = '';
  int _pageSize = 10;
  int _currentPage = 0;
  List<DropdownOption> _contractOptions = const <DropdownOption>[];
  List<DropdownOption> _hodOptions = const <DropdownOption>[];
  List<DropdownOption> _departmentOptions = const <DropdownOption>[];
  List<DropdownOption> _categoryOptions = const <DropdownOption>[];
  List<DropdownOption> _statusOptions = const <DropdownOption>[];
  final Map<String, String> _selectedLabels = <String, String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IssueFilterQuery get _query => IssueFilterQuery(
        contractId: _contractId,
        hod: _hod,
        department: _department,
        category: _category,
        status: _status,
        search: _searchQuery,
        page: _currentPage,
        pageSize: _pageSize,
      );

  IssueFilterQuery get _filterQuery => IssueFilterQuery(
        contractId: _contractId,
        hod: _hod,
        department: _department,
        category: _category,
        status: _status,
      );

  bool get _hasFilters =>
      _contractId != null ||
      _hod != null ||
      _department != null ||
      _category != null ||
      _status != null ||
      _searchQuery.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _contractId = null;
      _hod = null;
      _department = null;
      _category = null;
      _status = null;
      _searchQuery = '';
      _currentPage = 0;
      _searchController.clear();
      _selectedLabels.clear();
    });
  }

  List<DropdownOption> _keepOptions(
    List<DropdownOption> latest,
    List<DropdownOption> previous,
  ) {
    return latest.isNotEmpty ? latest : previous;
  }

  Future<void> _openForm({IssueListItem? item}) async {
    final Object? changed = await context.pushNamed(
      IssueFormPage.routeName,
      extra: item,
    );
    if (changed == true && mounted) {
      ref.invalidate(issueListProvider(_query));
    }
  }

  double get _tableWidth =>
      _headers.fold<double>(0, (double sum, String h) => sum + _columnWidth(h));

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final IssueFilterQuery filterQuery = _filterQuery;

    final AsyncValue<List<DropdownOption>> contractAsync =
        ref.watch(issueContractFilterProvider(filterQuery));
    final AsyncValue<List<DropdownOption>> hodAsync =
        ref.watch(issueHodFilterProvider(filterQuery));
    final AsyncValue<List<DropdownOption>> departmentAsync =
        ref.watch(issueDepartmentFilterProvider(filterQuery));
    final AsyncValue<List<DropdownOption>> categoryAsync =
        ref.watch(issueCategoryFilterProvider(filterQuery));
    final AsyncValue<List<DropdownOption>> statusAsync =
        ref.watch(issueStatusFilterProvider(filterQuery));
    final AsyncValue<IssueListResult> listAsync =
        ref.watch(issueListProvider(_query));

    final List<DropdownOption> contractOptions = _keepOptions(
      contractAsync.valueOrNull ?? const <DropdownOption>[],
      _contractOptions,
    );
    final List<DropdownOption> hodOptions = _keepOptions(
      hodAsync.valueOrNull ?? const <DropdownOption>[],
      _hodOptions,
    );
    final List<DropdownOption> departmentOptions = _keepOptions(
      departmentAsync.valueOrNull ?? const <DropdownOption>[],
      _departmentOptions,
    );
    final List<DropdownOption> categoryOptions = _keepOptions(
      categoryAsync.valueOrNull ?? const <DropdownOption>[],
      _categoryOptions,
    );
    final List<DropdownOption> statusOptions = _keepOptions(
      statusAsync.valueOrNull ?? const <DropdownOption>[],
      _statusOptions,
    );
    if (contractAsync.hasValue) {
      _contractOptions = contractAsync.requireValue;
    }
    if (hodAsync.hasValue) {
      _hodOptions = hodAsync.requireValue;
    }
    if (departmentAsync.hasValue) {
      _departmentOptions = departmentAsync.requireValue;
    }
    if (categoryAsync.hasValue) {
      _categoryOptions = categoryAsync.requireValue;
    }
    if (statusAsync.hasValue) {
      _statusOptions = statusAsync.requireValue;
    }

    final bool loading = contractAsync.isLoading ||
        hodAsync.isLoading ||
        departmentAsync.isLoading ||
        categoryAsync.isLoading ||
        statusAsync.isLoading ||
        listAsync.isLoading;

    final Widget filterBlock = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: _filters(
        contractOptions: contractOptions,
        hodOptions: hodOptions,
        departmentOptions: departmentOptions,
        categoryOptions: categoryOptions,
        statusOptions: statusOptions,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issues'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Export',
            onPressed: () => GlobalDialog.info(
              'Export will be connected when the API is available.',
              title: 'Export',
            ),
            icon: const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: 'Add',
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            listAsync.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
              loading: () => CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(child: filterBlock),
                ],
              ),
              error: (Object error, StackTrace _) => CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(child: filterBlock),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text('$error', textAlign: TextAlign.center),
                            const SizedBox(height: 10),
                            FilledButton(
                              onPressed: () =>
                                  ref.invalidate(issueListProvider(_query)),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              data: (IssueListResult page) {
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
                final int start = total == 0 ? 0 : (_currentPage * _pageSize);
                final int end = total == 0
                    ? 0
                    : (start + page.items.length).clamp(0, total);
                return Column(
                  children: <Widget>[
                    Expanded(
                      child: CustomScrollView(
                        slivers: <Widget>[
                          SliverToBoxAdapter(child: filterBlock),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            sliver: SliverToBoxAdapter(
                              child: _tableCard(
                                page: page,
                                palette: palette,
                                scheme: scheme,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: AppTablePaginationFooter(
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
                    ),
                  ],
                );
              },
            ),
            if (loading) const AppGlobalLoader(),
          ],
        ),
      ),
    );
  }

  Widget _filters({
    required List<DropdownOption> contractOptions,
    required List<DropdownOption> hodOptions,
    required List<DropdownOption> departmentOptions,
    required List<DropdownOption> categoryOptions,
    required List<DropdownOption> statusOptions,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _filterField(
                keyName: 'contract',
                label: 'Contract',
                title: 'Select Contract',
                options: contractOptions,
                value: _contractId,
                onChanged: (String? id) => setState(() {
                  _contractId = id;
                  _currentPage = 0;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _filterField(
                keyName: 'hod',
                label: 'HOD',
                title: 'Select HOD',
                options: hodOptions,
                value: _hod,
                onChanged: (String? id) => setState(() {
                  _hod = id;
                  _currentPage = 0;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _filterField(
                keyName: 'department',
                label: 'Department',
                title: 'Select Department',
                options: departmentOptions,
                value: _department,
                onChanged: (String? id) => setState(() {
                  _department = id;
                  _currentPage = 0;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _filterField(
                keyName: 'category',
                label: 'Category',
                title: 'Select Category',
                options: categoryOptions,
                value: _category,
                onChanged: (String? id) => setState(() {
                  _category = id;
                  _currentPage = 0;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _filterField(
          keyName: 'status',
          label: 'Status',
          title: 'Select Status',
          options: statusOptions,
          value: _status,
          onChanged: (String? id) => setState(() {
            _status = id;
            _currentPage = 0;
          }),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          onChanged: (String value) => setState(() {
            _searchQuery = value.trim();
            _currentPage = 0;
          }),
          decoration: InputDecoration(
            labelText: 'Search',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _currentPage = 0;
                      });
                    },
                    icon: const Icon(Icons.clear_rounded),
                  ),
          ),
        ),
        if (_hasFilters) ...<Widget>[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _tableCard({
    required IssueListResult page,
    required AppPalette palette,
    required ColorScheme scheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : _tableWidth;
          final double width = _tableWidth < maxWidth ? maxWidth : _tableWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
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
                  ),
                  if (page.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'No issues found.',
                        style: TextStyle(color: palette.mutedText),
                      ),
                    )
                  else
                    for (int index = 0; index < page.items.length; index++)
                      _tableRow(
                        page.items[index],
                        index,
                        palette,
                        scheme,
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tableRow(
    IssueListItem item,
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
          _cell(item.contractDisplay, width: _columnWidth('Contract')),
          _cell(
            item.shortDescription ?? '-',
            width: _columnWidth('Short Description'),
          ),
          _cell(item.location ?? '-', width: _columnWidth('Location')),
          _cell(
            item.responsiblePerson ?? '-',
            width: _columnWidth('Responsible Person'),
          ),
          _cell(item.departmentDisplay, width: _columnWidth('Department')),
          _cell(item.status ?? '-', width: _columnWidth('Issue Status')),
          _cell(item.lastUpdate ?? '-', width: _columnWidth('Last Update')),
          SizedBox(
            width: _columnWidth('Action'),
            child: Center(
              child: Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _openForm(item: item),
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
    FontWeight weight = FontWeight.w400,
    bool bold = false,
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
            fontSize: 12,
            height: 1.25,
            color: color ?? Theme.of(context).colorScheme.onSurface,
            fontWeight: bold ? FontWeight.w700 : weight,
          ),
        ),
      ),
    );
  }

  double _columnWidth(String header) {
    return switch (header) {
      'Contract' => 260,
      'Short Description' => 160,
      'Location' => 140,
      'Responsible Person' => 180,
      'Department' => 150,
      'Issue Status' => 110,
      'Last Update' => 110,
      'Action' => 72,
      _ => 120,
    };
  }

  Widget _filterField({
    required String keyName,
    required String label,
    required String title,
    required List<DropdownOption> options,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final List<DropdownOption> items = <DropdownOption>[
      const DropdownOption(id: '', name: 'Select'),
      ...options,
    ];
    if (value != null &&
        value.isNotEmpty &&
        !items.any((DropdownOption e) => e.id == value)) {
      items.add(
        DropdownOption(
          id: value,
          name: _selectedLabels[keyName] ?? value,
        ),
      );
    }
    return AppSelectSheetField<String>(
      label: label,
      title: title,
      items: items.map((DropdownOption e) => e.id).toList(),
      value: value,
      itemLabelBuilder: (String id) {
        if (id.isEmpty) {
          return 'Select';
        }
        return items
            .firstWhere(
              (DropdownOption e) => e.id == id,
              orElse: () => DropdownOption(
                id: id,
                name: _selectedLabels[keyName] ?? id,
              ),
            )
            .name;
      },
      onChanged: (String id) {
        if (id.isEmpty) {
          _selectedLabels.remove(keyName);
          onChanged(null);
          return;
        }
        final String name = items
            .firstWhere(
              (DropdownOption e) => e.id == id,
              orElse: () => DropdownOption(id: id, name: id),
            )
            .name;
        _selectedLabels[keyName] = name;
        onChanged(id);
      },
    );
  }
}
