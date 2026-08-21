import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_table_pagination_footer.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/p6_data_history_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/execution_monitoring/providers/p6_data_history_providers.dart';

/// Update Forms → Execution & Monitoring → Structure P6 Updates (web "P6 DATA HISTORY").
class StructureP6UpdatesPage extends ConsumerStatefulWidget {
  const StructureP6UpdatesPage({super.key});

  static const String routeName = 'structure-p6-updates';
  static const String routePath = '/structure-p6-updates';

  @override
  ConsumerState<StructureP6UpdatesPage> createState() =>
      _StructureP6UpdatesPageState();
}

class _StructureP6UpdatesPageState extends ConsumerState<StructureP6UpdatesPage> {
  static const List<int> _pageSizeOptions = <int>[5, 10, 25, 50, 100];

  final TextEditingController _searchController = TextEditingController();
  String? _contractId;
  String? _uploadType;
  String? _statusFk;
  String _searchQuery = '';
  int _pageSize = 10;
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  P6DataHistoryListQuery get _query => P6DataHistoryListQuery(
        contractId: _contractId,
        uploadType: _uploadType,
        statusFk: _statusFk,
        search: _searchQuery,
        page: _currentPage,
        pageSize: _pageSize,
      );

  bool get _hasFilters =>
      _contractId != null ||
      _uploadType != null ||
      _statusFk != null ||
      _searchQuery.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _contractId = null;
      _uploadType = null;
      _statusFk = null;
      _searchQuery = '';
      _currentPage = 0;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AsyncValue<List<DropdownOption>> contractsAsync =
        ref.watch(p6ContractFilterProvider);
    final AsyncValue<List<DropdownOption>> typesAsync =
        ref.watch(p6UploadTypeFilterProvider);
    final AsyncValue<List<DropdownOption>> statusAsync =
        ref.watch(p6StatusFilterProvider);
    final AsyncValue<P6DataHistoryListResult> listAsync =
        ref.watch(p6DataHistoryListProvider(_query));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('P6 DATA HISTORY'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: listAsync.when(
                loading: () => Column(
                  children: <Widget>[
                    _filtersBlock(
                      contractsAsync,
                      typesAsync,
                      statusAsync,
                      scheme,
                    ),
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ),
                error: (Object error, StackTrace _) => Column(
                  children: <Widget>[
                    _filtersBlock(
                      contractsAsync,
                      typesAsync,
                      statusAsync,
                      scheme,
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text('$error', textAlign: TextAlign.center),
                              const SizedBox(height: 10),
                              FilledButton(
                                onPressed: () => ref.invalidate(
                                  p6DataHistoryListProvider(_query),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                data: (P6DataHistoryListResult page) {
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
                        child: CustomScrollView(
                          slivers: <Widget>[
                            SliverToBoxAdapter(
                              child: _filtersBlock(
                                contractsAsync,
                                typesAsync,
                                statusAsync,
                                scheme,
                              ),
                            ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _filtersBlock(
    AsyncValue<List<DropdownOption>> contractsAsync,
    AsyncValue<List<DropdownOption>> typesAsync,
    AsyncValue<List<DropdownOption>> statusAsync,
    ColorScheme scheme,
  ) {
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
                  label: 'Contract',
                  title: 'Select Contract',
                  async: contractsAsync,
                  value: _contractId,
                  onChanged: (String? id) => setState(() {
                    _contractId = id;
                    _currentPage = 0;
                  }),
                  scheme: scheme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _filterField(
                  label: 'Data Type',
                  title: 'Select Data Type',
                  async: typesAsync,
                  value: _uploadType,
                  onChanged: (String? id) => setState(() {
                    _uploadType = id;
                    _currentPage = 0;
                  }),
                  scheme: scheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: _filterField(
                  label: 'Status',
                  title: 'Select Status',
                  async: statusAsync,
                  value: _statusFk,
                  onChanged: (String? id) => setState(() {
                    _statusFk = id;
                    _currentPage = 0;
                  }),
                  scheme: scheme,
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
                onPressed: _hasFilters ? _clearFilters : null,
                child: const Text('Clear Filters'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
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
        ],
      ),
    );
  }

  Widget _tableCard({
    required P6DataHistoryListResult page,
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 860,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                color: scheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: const Row(
                  children: <Widget>[
                    _HeaderCell('Contract ID', flex: 2),
                    _HeaderCell('Data Type', flex: 2),
                    _HeaderCell('Data Date', flex: 2),
                    _HeaderCell('Status', flex: 2),
                    _HeaderCell('Uploaded File', flex: 3),
                    _HeaderCell('Uploaded By', flex: 2),
                    _HeaderCell('Uploaded Date', flex: 2),
                  ],
                ),
              ),
              if (page.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No P6 data found.',
                      style: TextStyle(color: palette.mutedText),
                    ),
                  ),
                )
              else
                for (int index = 0; index < page.items.length; index++)
                  _row(page.items[index], index, palette, scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterField({
    required String label,
    required String title,
    required AsyncValue<List<DropdownOption>> async,
    required String? value,
    required ValueChanged<String?> onChanged,
    required ColorScheme scheme,
  }) {
    return async.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (Object e, StackTrace _) => Text(
        'Unable to load $label: $e',
        style: TextStyle(color: scheme.error, fontSize: 12),
      ),
      data: (List<DropdownOption> options) {
        final List<DropdownOption> items = <DropdownOption>[
          const DropdownOption(id: '', name: 'Select'),
          ...options,
        ];
        return AppSelectSheetField<String>(
          label: label,
          title: title,
          items: items.map((DropdownOption e) => e.id).toList(),
          value: value ?? '',
          itemLabelBuilder: (String id) {
            return items
                .firstWhere(
                  (DropdownOption e) => e.id == id,
                  orElse: () =>
                      const DropdownOption(id: '', name: 'Select'),
                )
                .name;
          },
          onChanged: (String id) => onChanged(id.isEmpty ? null : id),
        );
      },
    );
  }

  Widget _row(
    P6DataHistoryItem item,
    int index,
    AppPalette palette,
    ColorScheme scheme,
  ) {
    final Color bg =
        index.isEven ? palette.tableRowEven : palette.tableRowOdd;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _cell(item.contractId ?? '-', flex: 2, bold: true, scheme: scheme),
          _cell(item.dataType ?? '-', flex: 2, scheme: scheme),
          _cell(item.dataDate ?? '-', flex: 2, scheme: scheme),
          _cell(item.status ?? '-', flex: 2, scheme: scheme),
          _cell(item.uploadedFileDisplay, flex: 3, scheme: scheme),
          _cell(item.uploadedBy ?? '-', flex: 2, scheme: scheme),
          _cell(item.uploadedDate ?? '-', flex: 2, scheme: scheme),
        ],
      ),
    );
  }

  Widget _cell(
    String text, {
    required int flex,
    required ColorScheme scheme,
    bool bold = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            height: 1.25,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
