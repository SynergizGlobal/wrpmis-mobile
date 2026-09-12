import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_global_loader.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_table_pagination_footer.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contractor_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/contracts/contractor_form_page.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/contracts/providers/contractor_providers.dart';

/// Update Forms → Contracts/Tenders → Contractor.
class ContractorPage extends ConsumerStatefulWidget {
  const ContractorPage({super.key});

  static const String routeName = 'contractors';
  static const String routePath = '/contractors';

  @override
  ConsumerState<ContractorPage> createState() => _ContractorPageState();
}

class _ContractorPageState extends ConsumerState<ContractorPage> {
  static const List<int> _pageSizeOptions = <int>[5, 10, 25, 50, 100];
  static const List<String> _headers = <String>[
    'Contractor ID',
    'Contractor Name',
    'PAN Number',
    'Specialization',
    'Address',
    'Primary Contact',
    'Phone Number',
    'Email',
    'Action',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _pageSize = 10;
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ContractorFilterQuery get _query => ContractorFilterQuery(
        search: _searchQuery,
        page: _currentPage,
        pageSize: _pageSize,
      );

  Future<void> _openForm({String? contractorId}) async {
    final Object? changed = await context.pushNamed(
      ContractorFormPage.routeName,
      extra: contractorId,
    );
    if (changed == true && mounted) {
      ref.invalidate(contractorListProvider(_query));
    }
  }

  double get _tableWidth =>
      _headers.fold<double>(0, (double sum, String h) => sum + _columnWidth(h));

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AsyncValue<ContractorListResult> listAsync =
        ref.watch(contractorListProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor'),
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
                  SliverToBoxAdapter(child: _searchBar()),
                ],
              ),
              error: (Object error, StackTrace _) => CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(child: _searchBar()),
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
                                  ref.invalidate(contractorListProvider(_query)),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              data: (ContractorListResult page) {
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
                          SliverToBoxAdapter(child: _searchBar()),
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
            if (listAsync.isLoading) const AppGlobalLoader(),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: TextField(
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
    );
  }

  Widget _tableCard({
    required ContractorListResult page,
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
                        'No contractors found.',
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
    ContractorListItem item,
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
          _cell(item.contractorId, width: _columnWidth('Contractor ID'), bold: true),
          _cell(item.contractorName ?? '-', width: _columnWidth('Contractor Name')),
          _cell(item.panNumber ?? '-', width: _columnWidth('PAN Number')),
          _cell(item.specialization ?? '-', width: _columnWidth('Specialization')),
          _cell(item.address ?? '-', width: _columnWidth('Address')),
          _cell(item.primaryContact ?? '-', width: _columnWidth('Primary Contact')),
          _cell(item.phoneNumber ?? '-', width: _columnWidth('Phone Number')),
          _cell(item.email ?? '-', width: _columnWidth('Email')),
          SizedBox(
            width: _columnWidth('Action'),
            child: Center(
              child: Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _openForm(contractorId: item.contractorId),
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
      'Contractor ID' => 120,
      'Contractor Name' => 260,
      'PAN Number' => 120,
      'Specialization' => 160,
      'Address' => 240,
      'Primary Contact' => 140,
      'Phone Number' => 130,
      'Email' => 180,
      'Action' => 72,
      _ => 120,
    };
  }
}
