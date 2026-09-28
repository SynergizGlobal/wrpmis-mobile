import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_global_loader.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_table_pagination_footer.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/utility_shifting_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/utility_shifting/providers/utility_shifting_providers.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/utility_shifting/utility_shifting_form_page.dart';

class UtilityShiftingPage extends ConsumerStatefulWidget {
  const UtilityShiftingPage({super.key});

  static const String routeName = 'utility-shifting';
  static const String routePath = '/utility-shifting';

  @override
  ConsumerState<UtilityShiftingPage> createState() =>
      _UtilityShiftingPageState();
}

class _UtilityShiftingPageState extends ConsumerState<UtilityShiftingPage>
    with SingleTickerProviderStateMixin {
  static const List<int> _pageSizeOptions = <int>[5, 10, 25, 50, 100];
  static const List<String> _listHeaders = <String>[
    'ID',
    'Description',
    'Utility type',
    'Custodian',
    'HOD',
    'Execution agency',
    'Status',
    'Last Update',
    'Action',
  ];
  static const List<String> _uploadHeaders = <String>[
    'Uploaded File',
    'Status',
    'Remarks',
    'Uploaded by',
    'Uploaded On',
  ];

  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _uploadSearchController = TextEditingController();

  String? _location;
  String? _category;
  String? _utilityType;
  String? _status;
  String _search = '';
  String _uploadSearch = '';
  int _pageSize = 10;
  int _uploadPageSize = 10;
  int _page = 0;
  int _uploadPage = 0;

  List<DropdownOption> _locationOptions = const <DropdownOption>[];
  List<DropdownOption> _categoryOptions = const <DropdownOption>[];
  List<DropdownOption> _typeOptions = const <DropdownOption>[];
  List<DropdownOption> _statusOptions = const <DropdownOption>[];
  final Map<String, String> _selectedLabels = <String, String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging && mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _uploadSearchController.dispose();
    super.dispose();
  }

  UtilityShiftingFilterQuery get _filterQuery => UtilityShiftingFilterQuery(
        location: _location,
        category: _category,
        utilityType: _utilityType,
        status: _status,
      );

  UtilityShiftingFilterQuery get _listQuery => UtilityShiftingFilterQuery(
        location: _location,
        category: _category,
        utilityType: _utilityType,
        status: _status,
        search: _search,
        page: _page,
        pageSize: _pageSize,
      );

  bool get _hasFilters =>
      _location != null ||
      _category != null ||
      _utilityType != null ||
      _status != null ||
      _search.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _location = null;
      _category = null;
      _utilityType = null;
      _status = null;
      _search = '';
      _page = 0;
      _searchController.clear();
      _selectedLabels.clear();
    });
  }

  List<DropdownOption> _keep(
    List<DropdownOption> latest,
    List<DropdownOption> previous,
  ) {
    return latest.isNotEmpty ? latest : previous;
  }

  void _comingSoon(String action) {
    GlobalDialog.info(
      '$action will be connected when the API is available.',
      title: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    final Color appBarFg =
        theme.appBarTheme.foregroundColor ?? scheme.onPrimary;

    final AsyncValue<List<DropdownOption>> locationAsync =
        ref.watch(utilityLocationFilterProvider(_filterQuery));
    final AsyncValue<List<DropdownOption>> categoryAsync =
        ref.watch(utilityCategoryFilterProvider(_filterQuery));
    final AsyncValue<List<DropdownOption>> typeAsync =
        ref.watch(utilityTypeFilterProvider(_filterQuery));
    final AsyncValue<List<DropdownOption>> statusAsync =
        ref.watch(utilityStatusFilterProvider(_filterQuery));
    final AsyncValue<UtilityShiftingListResult> listAsync =
        ref.watch(utilityListProvider(_listQuery));
    final AsyncValue<List<UtilityUploadItem>> uploadsAsync =
        ref.watch(utilityUploadsProvider);

    final List<DropdownOption> locationOptions =
        _keep(locationAsync.valueOrNull ?? const [], _locationOptions);
    final List<DropdownOption> categoryOptions =
        _keep(categoryAsync.valueOrNull ?? const [], _categoryOptions);
    final List<DropdownOption> typeOptions =
        _keep(typeAsync.valueOrNull ?? const [], _typeOptions);
    final List<DropdownOption> statusOptions =
        _keep(statusAsync.valueOrNull ?? const [], _statusOptions);
    if (locationAsync.hasValue) {
      _locationOptions = locationAsync.requireValue;
    }
    if (categoryAsync.hasValue) {
      _categoryOptions = categoryAsync.requireValue;
    }
    if (typeAsync.hasValue) {
      _typeOptions = typeAsync.requireValue;
    }
    if (statusAsync.hasValue) {
      _statusOptions = statusAsync.requireValue;
    }

    final bool loading = (_tabController.index == 0 &&
            (locationAsync.isLoading ||
                categoryAsync.isLoading ||
                typeAsync.isLoading ||
                statusAsync.isLoading ||
                listAsync.isLoading)) ||
        (_tabController.index == 1 && uploadsAsync.isLoading);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utility Shifting'),
        actions: <Widget>[
          if (_tabController.index == 0) ...<Widget>[
            IconButton(
              tooltip: 'Upload',
              onPressed: () => _comingSoon('Upload'),
              icon: const Icon(Icons.upload_rounded),
            ),
            IconButton(
              tooltip: 'Add',
              onPressed: () => context.pushNamed(UtilityShiftingFormPage.routeName),
              icon: const Icon(Icons.add_rounded),
            ),
            IconButton(
              tooltip: 'Export',
              onPressed: () => _comingSoon('Export'),
              icon: const Icon(Icons.file_download_outlined),
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: appBarFg,
          unselectedLabelColor: appBarFg.withValues(alpha: 0.72),
          indicatorColor: appBarFg,
          dividerColor: appBarFg.withValues(alpha: 0.22),
          tabs: const <Tab>[
            Tab(text: 'Utility Shifting'),
            Tab(text: 'Uploaded Utility Data'),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            TabBarView(
              controller: _tabController,
              children: <Widget>[
                _listTab(
                  locationOptions: locationOptions,
                  categoryOptions: categoryOptions,
                  typeOptions: typeOptions,
                  statusOptions: statusOptions,
                  listAsync: listAsync,
                  palette: palette,
                  scheme: scheme,
                ),
                _uploadsTab(
                  uploadsAsync: uploadsAsync,
                  palette: palette,
                  scheme: scheme,
                ),
              ],
            ),
            if (loading) const AppGlobalLoader(),
          ],
        ),
      ),
    );
  }

  Widget _listTab({
    required List<DropdownOption> locationOptions,
    required List<DropdownOption> categoryOptions,
    required List<DropdownOption> typeOptions,
    required List<DropdownOption> statusOptions,
    required AsyncValue<UtilityShiftingListResult> listAsync,
    required AppPalette palette,
    required ColorScheme scheme,
  }) {
    return listAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _filters(
              locationOptions: locationOptions,
              categoryOptions: categoryOptions,
              typeOptions: typeOptions,
              statusOptions: statusOptions,
            ),
          ),
        ],
      ),
      error: (Object error, StackTrace _) => CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _filters(
              locationOptions: locationOptions,
              categoryOptions: categoryOptions,
              typeOptions: typeOptions,
              statusOptions: statusOptions,
            ),
          ),
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
                          ref.invalidate(utilityListProvider(_listQuery)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      data: (UtilityShiftingListResult page) {
        final int total = page.filteredRecords;
        final int pageCount = total == 0 ? 1 : (total / _pageSize).ceil();
        if (_page >= pageCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _page = pageCount - 1);
            }
          });
        }
        final int start = total == 0 ? 0 : (_page * _pageSize);
        final int end =
            total == 0 ? 0 : (start + page.items.length).clamp(0, total);
        return Column(
          children: <Widget>[
            Expanded(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: _filters(
                      locationOptions: locationOptions,
                      categoryOptions: categoryOptions,
                      typeOptions: typeOptions,
                      statusOptions: statusOptions,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    sliver: SliverToBoxAdapter(
                      child: _tableCard(
                        headers: _listHeaders,
                        columnWidth: _listColumnWidth,
                        palette: palette,
                        scheme: scheme,
                        emptyText: 'No utility shifting records found.',
                        itemCount: page.items.length,
                        rowBuilder: (int index) => _listRow(
                          page.items[index],
                          index,
                          palette,
                          scheme,
                        ),
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
                currentPage: _page,
                pageCount: pageCount,
                pageSize: _pageSize,
                pageSizeOptions: _pageSizeOptions,
                onPageSizeChanged: (int value) => setState(() {
                  _pageSize = value;
                  _page = 0;
                }),
                onPrevious:
                    _page > 0 ? () => setState(() => _page--) : null,
                onNext: end < total ? () => setState(() => _page++) : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _uploadsTab({
    required AsyncValue<List<UtilityUploadItem>> uploadsAsync,
    required AppPalette palette,
    required ColorScheme scheme,
  }) {
    return uploadsAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: _uploadSearchBar()),
        ],
      ),
      error: (Object error, StackTrace _) => CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: _uploadSearchBar()),
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
                      onPressed: () => ref.invalidate(utilityUploadsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      data: (List<UtilityUploadItem> all) {
        final String q = _uploadSearch.toLowerCase();
        final List<UtilityUploadItem> filtered = q.isEmpty
            ? all
            : all.where((UtilityUploadItem e) {
                return (e.uploadedFile ?? '').toLowerCase().contains(q) ||
                    (e.status ?? '').toLowerCase().contains(q) ||
                    (e.remarks ?? '').toLowerCase().contains(q) ||
                    (e.uploadedBy ?? '').toLowerCase().contains(q) ||
                    (e.uploadedOn ?? '').toLowerCase().contains(q);
              }).toList();
        final int total = filtered.length;
        final int pageCount =
            total == 0 ? 1 : (total / _uploadPageSize).ceil();
        if (_uploadPage >= pageCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _uploadPage = pageCount - 1);
            }
          });
        }
        final int start = total == 0 ? 0 : (_uploadPage * _uploadPageSize);
        final int end = total == 0
            ? 0
            : (start + _uploadPageSize).clamp(0, total);
        final List<UtilityUploadItem> pageItems = total == 0
            ? const <UtilityUploadItem>[]
            : filtered.sublist(start, end);
        return Column(
          children: <Widget>[
            Expanded(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(child: _uploadSearchBar()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    sliver: SliverToBoxAdapter(
                      child: _tableCard(
                        headers: _uploadHeaders,
                        columnWidth: _uploadColumnWidth,
                        palette: palette,
                        scheme: scheme,
                        emptyText: 'No uploads found.',
                        itemCount: pageItems.length,
                        rowBuilder: (int index) => _uploadRow(
                          pageItems[index],
                          index,
                          palette,
                          scheme,
                        ),
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
                currentPage: _uploadPage,
                pageCount: pageCount,
                pageSize: _uploadPageSize,
                pageSizeOptions: _pageSizeOptions,
                onPageSizeChanged: (int value) => setState(() {
                  _uploadPageSize = value;
                  _uploadPage = 0;
                }),
                onPrevious: _uploadPage > 0
                    ? () => setState(() => _uploadPage--)
                    : null,
                onNext:
                    end < total ? () => setState(() => _uploadPage++) : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filters({
    required List<DropdownOption> locationOptions,
    required List<DropdownOption> categoryOptions,
    required List<DropdownOption> typeOptions,
    required List<DropdownOption> statusOptions,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _filterField(
                  keyName: 'location',
                  label: 'Location',
                  title: 'Select Location',
                  options: locationOptions,
                  value: _location,
                  onChanged: (String? id) => setState(() {
                    _location = id;
                    _page = 0;
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
                    _page = 0;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: _filterField(
                  keyName: 'utilityType',
                  label: 'Utility Type',
                  title: 'Select Utility Type',
                  options: typeOptions,
                  value: _utilityType,
                  onChanged: (String? id) => setState(() {
                    _utilityType = id;
                    _page = 0;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _filterField(
                  keyName: 'status',
                  label: 'Status',
                  title: 'Select Status',
                  options: statusOptions,
                  value: _status,
                  onChanged: (String? id) => setState(() {
                    _status = id;
                    _page = 0;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _hasFilters ? _clearFilters : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text('Clear Filters'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (String value) => setState(() {
              _search = value.trim();
              _page = 0;
            }),
            decoration: InputDecoration(
              labelText: 'Search',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _search = '';
                          _page = 0;
                        });
                      },
                      icon: const Icon(Icons.clear_rounded),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: TextField(
        controller: _uploadSearchController,
        onChanged: (String value) => setState(() {
          _uploadSearch = value.trim();
          _uploadPage = 0;
        }),
        decoration: InputDecoration(
          labelText: 'Search',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _uploadSearch.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _uploadSearchController.clear();
                    setState(() {
                      _uploadSearch = '';
                      _uploadPage = 0;
                    });
                  },
                  icon: const Icon(Icons.clear_rounded),
                ),
        ),
      ),
    );
  }

  Widget _tableCard({
    required List<String> headers,
    required double Function(String) columnWidth,
    required AppPalette palette,
    required ColorScheme scheme,
    required String emptyText,
    required int itemCount,
    required Widget Function(int index) rowBuilder,
  }) {
    final double tableWidth = headers.fold<double>(
      0,
      (double sum, String h) => sum + columnWidth(h),
    );
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
              : tableWidth;
          final double width = tableWidth < maxWidth ? maxWidth : tableWidth;
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
                      children: headers
                          .map(
                            (String title) => _cell(
                              title,
                              width: columnWidth(title),
                              color: scheme.onPrimary,
                              weight: FontWeight.w700,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (itemCount == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        emptyText,
                        style: TextStyle(color: palette.mutedText),
                      ),
                    )
                  else
                    for (int index = 0; index < itemCount; index++)
                      rowBuilder(index),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _listRow(
    UtilityShiftingItem item,
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
          _cell(
            item.utilityShiftingId ?? item.id,
            width: _listColumnWidth('ID'),
            bold: true,
          ),
          _cell(item.description ?? '-', width: _listColumnWidth('Description')),
          _cell(item.utilityType ?? '-', width: _listColumnWidth('Utility type')),
          _cell(item.custodian ?? '-', width: _listColumnWidth('Custodian')),
          _cell(item.hod ?? '-', width: _listColumnWidth('HOD')),
          _cell(
            item.executionAgency ?? '-',
            width: _listColumnWidth('Execution agency'),
          ),
          _cell(item.status ?? '-', width: _listColumnWidth('Status')),
          _cell(item.lastUpdate ?? '-', width: _listColumnWidth('Last Update')),
          SizedBox(
            width: _listColumnWidth('Action'),
            child: Center(
              child: Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.pushNamed(
                    UtilityShiftingFormPage.routeName,
                    extra: item,
                  ),
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

  Widget _uploadRow(
    UtilityUploadItem item,
    int index,
    AppPalette palette,
    ColorScheme scheme,
  ) {
    final Color bg =
        index.isEven ? palette.tableRowEven : palette.tableRowOdd;
    final bool failed = (item.status ?? '').toLowerCase().contains('fail');
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          _cell(
            item.uploadedFile ?? '-',
            width: _uploadColumnWidth('Uploaded File'),
            color: scheme.primary,
            bold: true,
          ),
          _cell(
            item.status ?? '-',
            width: _uploadColumnWidth('Status'),
            color: failed ? scheme.error : null,
            bold: true,
          ),
          _cell(item.remarks ?? '-', width: _uploadColumnWidth('Remarks')),
          _cell(
            item.uploadedBy ?? '-',
            width: _uploadColumnWidth('Uploaded by'),
          ),
          _cell(
            item.uploadedOn ?? '-',
            width: _uploadColumnWidth('Uploaded On'),
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

  double _listColumnWidth(String header) {
    return switch (header) {
      'ID' => 130,
      'Description' => 140,
      'Utility type' => 180,
      'Custodian' => 100,
      'HOD' => 120,
      'Execution agency' => 140,
      'Status' => 110,
      'Last Update' => 120,
      'Action' => 72,
      _ => 120,
    };
  }

  double _uploadColumnWidth(String header) {
    return switch (header) {
      'Uploaded File' => 280,
      'Status' => 100,
      'Remarks' => 320,
      'Uploaded by' => 120,
      'Uploaded On' => 170,
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
        DropdownOption(id: value, name: _selectedLabels[keyName] ?? value),
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
