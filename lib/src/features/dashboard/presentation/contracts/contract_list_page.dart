import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_global_loader.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_table_pagination_footer.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contract_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/contracts/contract_form_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/contracts/providers/contract_list_providers.dart';

/// Update Forms → Contracts/Tenders → Contract.
class ContractListPage extends ConsumerStatefulWidget {
  const ContractListPage({super.key});

  static const String routeName = 'contracts';
  static const String routePath = '/contracts';

  @override
  ConsumerState<ContractListPage> createState() => _ContractListPageState();
}

class _ContractListPageState extends ConsumerState<ContractListPage> {
  static const List<int> _pageSizeOptions = <int>[5, 10, 25, 50, 100];
  static const List<String> _headers = <String>[
    'Project',
    'Contract ID',
    'Contract Name',
    'Contractor Name',
    'Department',
    'HOD',
    'Dy HOD',
    'Last Update',
    'Action',
  ];

  final TextEditingController _searchController = TextEditingController();
  String? _designation;
  String? _dyHodDesignation;
  String? _contractorId;
  String? _contractStatus;
  String? _workStatus;
  String _searchQuery = '';
  int _pageSize = 10;
  int _currentPage = 0;
  List<DropdownOption> _hodOptions = const <DropdownOption>[];
  List<DropdownOption> _dyHodOptions = const <DropdownOption>[];
  List<DropdownOption> _contractorOptions = const <DropdownOption>[];
  List<DropdownOption> _statusOptions = const <DropdownOption>[];
  List<DropdownOption> _workStatusOptions = const <DropdownOption>[];
  final Map<String, String> _selectedLabels = <String, String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ContractFilterQuery get _query => ContractFilterQuery(
        designation: _designation,
        dyHodDesignation: _dyHodDesignation,
        contractorId: _contractorId,
        contractStatus: _contractStatus,
        workStatus: _workStatus,
        search: _searchQuery,
        page: _currentPage,
        pageSize: _pageSize,
      );

  bool get _hasFilters =>
      _designation != null ||
      _dyHodDesignation != null ||
      _contractorId != null ||
      _contractStatus != null ||
      _workStatus != null ||
      _searchQuery.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _designation = null;
      _dyHodDesignation = null;
      _contractorId = null;
      _contractStatus = null;
      _workStatus = null;
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

  Future<void> _openForm({String? contractId}) async {
    final Object? changed = await context.pushNamed(
      ContractFormPage.routeName,
      extra: contractId,
    );
    if (changed == true && mounted) {
      ref.invalidate(contractListProvider(_query));
    }
  }

  double get _tableWidth =>
      _headers.fold<double>(0, (double sum, String h) => sum + _columnWidth(h));

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ContractFilterQuery filterQuery = ContractFilterQuery(
      designation: _designation,
      dyHodDesignation: _dyHodDesignation,
      contractorId: _contractorId,
      contractStatus: _contractStatus,
      workStatus: _workStatus,
    );

    final AsyncValue<List<DropdownOption>> hodAsync =
        ref.watch(contractHodFilterProvider(filterQuery));
    final AsyncValue<List<DropdownOption>> dyHodAsync =
        ref.watch(contractDyHodFilterProvider(filterQuery));
    final AsyncValue<List<DropdownOption>> contractorAsync =
        ref.watch(contractContractorFilterProvider(filterQuery));
    final AsyncValue<List<DropdownOption>> statusAsync =
        ref.watch(contractStatusFilterProvider(filterQuery));
    final AsyncValue<List<DropdownOption>> workStatusAsync =
        ref.watch(contractWorkStatusFilterProvider(filterQuery));
    final AsyncValue<ContractListResult> listAsync =
        ref.watch(contractListProvider(_query));

    final List<DropdownOption> hodOptions =
        _keepOptions(hodAsync.valueOrNull ?? const <DropdownOption>[], _hodOptions);
    final List<DropdownOption> dyHodOptions = _keepOptions(
      dyHodAsync.valueOrNull ?? const <DropdownOption>[],
      _dyHodOptions,
    );
    final List<DropdownOption> contractorOptions = _keepOptions(
      contractorAsync.valueOrNull ?? const <DropdownOption>[],
      _contractorOptions,
    );
    final List<DropdownOption> statusOptions = _keepOptions(
      statusAsync.valueOrNull ?? const <DropdownOption>[],
      _statusOptions,
    );
    final List<DropdownOption> workStatusOptions = _keepOptions(
      workStatusAsync.valueOrNull ?? const <DropdownOption>[],
      _workStatusOptions,
    );
    if (hodAsync.hasValue) {
      _hodOptions = hodAsync.requireValue;
    }
    if (dyHodAsync.hasValue) {
      _dyHodOptions = dyHodAsync.requireValue;
    }
    if (contractorAsync.hasValue) {
      _contractorOptions = contractorAsync.requireValue;
    }
    if (statusAsync.hasValue) {
      _statusOptions = statusAsync.requireValue;
    }
    if (workStatusAsync.hasValue) {
      _workStatusOptions = workStatusAsync.requireValue;
    }

    final bool loading = hodAsync.isLoading ||
        dyHodAsync.isLoading ||
        contractorAsync.isLoading ||
        statusAsync.isLoading ||
        workStatusAsync.isLoading ||
        listAsync.isLoading;

    final Widget filterBlock = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: _filters(
        hodOptions: hodOptions,
        dyHodOptions: dyHodOptions,
        contractorOptions: contractorOptions,
        statusOptions: statusOptions,
        workStatusOptions: workStatusOptions,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract'),
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
                                  ref.invalidate(contractListProvider(_query)),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              data: (ContractListResult page) {
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
    required List<DropdownOption> hodOptions,
    required List<DropdownOption> dyHodOptions,
    required List<DropdownOption> contractorOptions,
    required List<DropdownOption> statusOptions,
    required List<DropdownOption> workStatusOptions,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _filterField(
                keyName: 'hod',
                label: 'HOD',
                title: 'Select HOD',
                options: hodOptions,
                value: _designation,
                onChanged: (String? id) => setState(() {
                  _designation = id;
                  _currentPage = 0;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _filterField(
                keyName: 'dyHod',
                label: 'Dy HOD',
                title: 'Select Dy HOD',
                options: dyHodOptions,
                value: _dyHodDesignation,
                onChanged: (String? id) => setState(() {
                  _dyHodDesignation = id;
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
                keyName: 'contractor',
                label: 'Contractor',
                title: 'Select Contractor',
                options: contractorOptions,
                value: _contractorId,
                onChanged: (String? id) => setState(() {
                  _contractorId = id;
                  _currentPage = 0;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _filterField(
                keyName: 'status',
                label: 'Contract Status',
                title: 'Select Contract Status',
                options: statusOptions,
                value: _contractStatus,
                onChanged: (String? id) => setState(() {
                  _contractStatus = id;
                  _currentPage = 0;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _filterField(
          keyName: 'workStatus',
          label: 'Status of Work',
          title: 'Select Status of Work',
          options: workStatusOptions,
          value: _workStatus,
          onChanged: (String? id) => setState(() {
            _workStatus = id;
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
    required ContractListResult page,
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
                        'No contracts found.',
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
    ContractListItem item,
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
          _cell(item.projectDisplay, width: _columnWidth('Project')),
          _cell(item.contractId, width: _columnWidth('Contract ID'), bold: true),
          _cell(item.title, width: _columnWidth('Contract Name')),
          _cell(
            item.contractorName ?? '-',
            width: _columnWidth('Contractor Name'),
          ),
          _cell(item.departmentName ?? '-', width: _columnWidth('Department')),
          _cell(item.hodDesignation ?? '-', width: _columnWidth('HOD')),
          _cell(item.dyHodDesignation ?? '-', width: _columnWidth('Dy HOD')),
          _cell(item.modifiedDate ?? '-', width: _columnWidth('Last Update')),
          SizedBox(
            width: _columnWidth('Action'),
            child: Center(
              child: Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _openForm(contractId: item.contractId),
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
      'Project' => 150,
      'Contract ID' => 110,
      'Contract Name' => 260,
      'Contractor Name' => 220,
      'Department' => 120,
      'HOD' => 120,
      'Dy HOD' => 130,
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
