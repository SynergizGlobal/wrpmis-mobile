import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_global_loader.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_table_pagination_footer.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/design_drawing_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/design_drawing/providers/design_drawing_providers.dart';

class DesignDrawingPage extends ConsumerStatefulWidget {
  const DesignDrawingPage({super.key});

  static const String routeName = 'design-drawing';
  static const String routePath = '/design-drawing';

  @override
  ConsumerState<DesignDrawingPage> createState() => _DesignDrawingPageState();
}

class _DesignDrawingPageState extends ConsumerState<DesignDrawingPage>
    with SingleTickerProviderStateMixin {
  static const List<int> _pageSizeOptions = <int>[5, 10, 25, 50, 100];
  static const List<String> _designHeaders = <String>[
    'PMIS Drawing No.',
    'Structure Type',
    'Structure',
    'Title',
    'Drawing Type',
    'Drawing No',
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
  final TextEditingController _designSearchController = TextEditingController();
  final TextEditingController _uploadSearchController = TextEditingController();

  String? _contractId;
  String? _structureType;
  String? _drawingType;
  String _designSearch = '';
  String _uploadSearch = '';
  int _designPageSize = 10;
  int _uploadPageSize = 10;
  int _designPage = 0;
  int _uploadPage = 0;

  List<DropdownOption> _contractOptions = const <DropdownOption>[];
  List<DropdownOption> _structureTypeOptions = const <DropdownOption>[];
  List<DropdownOption> _drawingTypeOptions = const <DropdownOption>[];
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
    _designSearchController.dispose();
    _uploadSearchController.dispose();
    super.dispose();
  }

  DesignDrawingFilterQuery get _filterQuery => DesignDrawingFilterQuery(
        contractId: _contractId,
        structureType: _structureType,
        drawingType: _drawingType,
      );

  DesignDrawingFilterQuery get _listQuery => DesignDrawingFilterQuery(
        contractId: _contractId,
        structureType: _structureType,
        drawingType: _drawingType,
        search: _designSearch,
        page: _designPage,
        pageSize: _designPageSize,
      );

  bool get _hasFilters =>
      _contractId != null ||
      _structureType != null ||
      _drawingType != null ||
      _designSearch.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _contractId = null;
      _structureType = null;
      _drawingType = null;
      _designSearch = '';
      _designPage = 0;
      _designSearchController.clear();
      _selectedLabels.clear();
    });
  }

  List<DropdownOption> _keepOptions(
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

    final AsyncValue<List<DropdownOption>> contractAsync =
        ref.watch(designContractFilterProvider(_filterQuery));
    final AsyncValue<List<DropdownOption>> structureAsync =
        ref.watch(designStructureTypeFilterProvider(_filterQuery));
    final AsyncValue<List<DropdownOption>> drawingAsync =
        ref.watch(designDrawingTypeFilterProvider(_filterQuery));
    final AsyncValue<DesignDrawingListResult> listAsync =
        ref.watch(designListProvider(_listQuery));
    final AsyncValue<List<DesignUploadItem>> uploadsAsync =
        ref.watch(designUploadsProvider);

    final List<DropdownOption> contractOptions = _keepOptions(
      contractAsync.valueOrNull ?? const <DropdownOption>[],
      _contractOptions,
    );
    final List<DropdownOption> structureOptions = _keepOptions(
      structureAsync.valueOrNull ?? const <DropdownOption>[],
      _structureTypeOptions,
    );
    final List<DropdownOption> drawingOptions = _keepOptions(
      drawingAsync.valueOrNull ?? const <DropdownOption>[],
      _drawingTypeOptions,
    );
    if (contractAsync.hasValue) {
      _contractOptions = contractAsync.requireValue;
    }
    if (structureAsync.hasValue) {
      _structureTypeOptions = structureAsync.requireValue;
    }
    if (drawingAsync.hasValue) {
      _drawingTypeOptions = drawingAsync.requireValue;
    }

    final bool loading = (_tabController.index == 0 &&
            (contractAsync.isLoading ||
                structureAsync.isLoading ||
                drawingAsync.isLoading ||
                listAsync.isLoading)) ||
        (_tabController.index == 1 && uploadsAsync.isLoading);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design & Drawing'),
        actions: <Widget>[
          if (_tabController.index == 0) ...<Widget>[
            IconButton(
              tooltip: 'Template',
              onPressed: () => _comingSoon('Template download'),
              icon: const Icon(Icons.download_rounded),
            ),
            IconButton(
              tooltip: 'Upload',
              onPressed: () => _comingSoon('Upload'),
              icon: const Icon(Icons.upload_rounded),
            ),
            IconButton(
              tooltip: 'Add',
              onPressed: () => _comingSoon('Add'),
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
            Tab(text: 'Update Design & Drawing'),
            Tab(text: 'Uploaded Design Data'),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            TabBarView(
              controller: _tabController,
              children: <Widget>[
                _designTab(
                  contractOptions: contractOptions,
                  structureOptions: structureOptions,
                  drawingOptions: drawingOptions,
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

  Widget _designTab({
    required List<DropdownOption> contractOptions,
    required List<DropdownOption> structureOptions,
    required List<DropdownOption> drawingOptions,
    required AsyncValue<DesignDrawingListResult> listAsync,
    required AppPalette palette,
    required ColorScheme scheme,
  }) {
    return listAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _designFilters(
              contractOptions: contractOptions,
              structureOptions: structureOptions,
              drawingOptions: drawingOptions,
            ),
          ),
        ],
      ),
      error: (Object error, StackTrace _) => CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _designFilters(
              contractOptions: contractOptions,
              structureOptions: structureOptions,
              drawingOptions: drawingOptions,
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
                          ref.invalidate(designListProvider(_listQuery)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      data: (DesignDrawingListResult page) {
        final int total = page.filteredRecords;
        final int pageCount = total == 0 ? 1 : (total / _designPageSize).ceil();
        if (_designPage >= pageCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _designPage = pageCount - 1);
            }
          });
        }
        final int start = total == 0 ? 0 : (_designPage * _designPageSize);
        final int end =
            total == 0 ? 0 : (start + page.items.length).clamp(0, total);
        return Column(
          children: <Widget>[
            Expanded(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: _designFilters(
                      contractOptions: contractOptions,
                      structureOptions: structureOptions,
                      drawingOptions: drawingOptions,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    sliver: SliverToBoxAdapter(
                      child: _tableCard(
                        headers: _designHeaders,
                        columnWidth: _designColumnWidth,
                        palette: palette,
                        scheme: scheme,
                        emptyText: 'No designs found.',
                        itemCount: page.items.length,
                        rowBuilder: (int index) => _designRow(
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
                currentPage: _designPage,
                pageCount: pageCount,
                pageSize: _designPageSize,
                pageSizeOptions: _pageSizeOptions,
                onPageSizeChanged: (int value) => setState(() {
                  _designPageSize = value;
                  _designPage = 0;
                }),
                onPrevious: _designPage > 0
                    ? () => setState(() => _designPage--)
                    : null,
                onNext: end < total
                    ? () => setState(() => _designPage++)
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _uploadsTab({
    required AsyncValue<List<DesignUploadItem>> uploadsAsync,
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
                      onPressed: () => ref.invalidate(designUploadsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      data: (List<DesignUploadItem> all) {
        final String q = _uploadSearch.toLowerCase();
        final List<DesignUploadItem> filtered = q.isEmpty
            ? all
            : all.where((DesignUploadItem e) {
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
        final List<DesignUploadItem> pageItems =
            total == 0 ? const <DesignUploadItem>[] : filtered.sublist(start, end);

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
                onNext: end < total
                    ? () => setState(() => _uploadPage++)
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _designFilters({
    required List<DropdownOption> contractOptions,
    required List<DropdownOption> structureOptions,
    required List<DropdownOption> drawingOptions,
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
                  keyName: 'contract',
                  label: 'Contract',
                  title: 'Select Contract',
                  options: contractOptions,
                  value: _contractId,
                  onChanged: (String? id) => setState(() {
                    _contractId = id;
                    _designPage = 0;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _filterField(
                  keyName: 'structureType',
                  label: 'Structure Type',
                  title: 'Select Structure Type',
                  options: structureOptions,
                  value: _structureType,
                  onChanged: (String? id) => setState(() {
                    _structureType = id;
                    _designPage = 0;
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
                  keyName: 'drawingType',
                  label: 'Drawing Type',
                  title: 'Select Drawing Type',
                  options: drawingOptions,
                  value: _drawingType,
                  onChanged: (String? id) => setState(() {
                    _drawingType = id;
                    _designPage = 0;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _hasFilters ? _clearFilters : null,
                style: FilledButton.styleFrom(
                  // Explicit size: theme tab height uses infinite width in Row.
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text('Clear Filters'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _designSearchController,
            onChanged: (String value) => setState(() {
              _designSearch = value.trim();
              _designPage = 0;
            }),
            decoration: InputDecoration(
              labelText: 'Search',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _designSearch.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _designSearchController.clear();
                        setState(() {
                          _designSearch = '';
                          _designPage = 0;
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

  Widget _designRow(
    DesignDrawingItem item,
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
            item.designSeqId ?? '-',
            width: _designColumnWidth('PMIS Drawing No.'),
            bold: true,
          ),
          _cell(
            item.structureType ?? '-',
            width: _designColumnWidth('Structure Type'),
          ),
          _cell(item.structureId ?? '-', width: _designColumnWidth('Structure')),
          _cell(item.title ?? '-', width: _designColumnWidth('Title')),
          _cell(
            item.drawingType ?? '-',
            width: _designColumnWidth('Drawing Type'),
          ),
          _cell(item.drawingNo ?? '-', width: _designColumnWidth('Drawing No')),
          _cell(
            item.modifiedDate ?? '-',
            width: _designColumnWidth('Last Update'),
          ),
          SizedBox(
            width: _designColumnWidth('Action'),
            child: Center(
              child: Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _comingSoon('Edit'),
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
    DesignUploadItem item,
    int index,
    AppPalette palette,
    ColorScheme scheme,
  ) {
    final Color bg =
        index.isEven ? palette.tableRowEven : palette.tableRowOdd;
    final bool failed =
        (item.status ?? '').toLowerCase().contains('fail');
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

  double _designColumnWidth(String header) {
    return switch (header) {
      'PMIS Drawing No.' => 260,
      'Structure Type' => 120,
      'Structure' => 100,
      'Title' => 180,
      'Drawing Type' => 160,
      'Drawing No' => 140,
      'Last Update' => 110,
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
      'Uploaded On' => 160,
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
