import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/result/result.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_global_loader.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_table_pagination_footer.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/validate_data_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/validate_activity_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/validation/providers/validate_data_providers.dart';

class ValidateDataPage extends ConsumerStatefulWidget {
  const ValidateDataPage({super.key});

  static const String routeName = 'validate-data';
  static const String routePath = '/validate-data';

  @override
  ConsumerState<ValidateDataPage> createState() => _ValidateDataPageState();
}

class _ValidateDataPageState extends ConsumerState<ValidateDataPage>
    with SingleTickerProviderStateMixin {
  static const List<String> _statuses = <String>[
    'Pending',
    'Approved',
    'Rejected',
  ];
  static const List<int> _pageSizeOptions = <int>[10, 25, 50, 100];
  static const List<_Column> _columns = <_Column>[
    _Column('Task Code', 120),
    _Column('Structure', 130),
    _Column('Component', 140),
    _Column('Element', 160),
    _Column('Activity Name', 130),
    _Column('Unit', 70),
    _Column('Scope', 90),
    _Column('Last activity', 110, group: 'Progress till last update'),
    _Column('Last component', 120, group: 'Progress till last update'),
    _Column('Last structure', 120, group: 'Progress till last update'),
    _Column('Reporting', 140),
    _Column('Actual / updated', 130, group: 'After accepting'),
    _Column('After activity', 110, group: 'After accepting'),
    _Column('After component', 120, group: 'After accepting'),
    _Column('After structure', 120, group: 'After accepting'),
    _Column('Updated on', 120),
    _Column('Action', 96),
  ];

  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _selectedLabels = <String, String>{};

  String? _contractId;
  String? _structure;
  String? _updatedBy;
  String _search = '';
  int _pageSize = 10;
  int _page = 0;
  final Set<String> _selected = <String>{};
  List<ValidateActivityItem> _selectedItems = const <ValidateActivityItem>[];
  bool _acting = false;

  List<DropdownOption> _contractOptions = const <DropdownOption>[];
  List<DropdownOption> _structureOptions = const <DropdownOption>[];
  List<DropdownOption> _updatedByOptions = const <DropdownOption>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging || !mounted) {
          return;
        }
        setState(() {
          _contractId = null;
          _structure = null;
          _updatedBy = null;
          _search = '';
          _page = 0;
          _selected.clear();
          _searchController.clear();
          _selectedLabels.clear();
        });
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String get _status => _statuses[_tabController.index];

  bool get _isPending => _status == 'Pending';

  ValidateDataQuery get _query => ValidateDataQuery(
        status: _status,
        contractId: _contractId,
        structure: _structure,
        updatedBy: _updatedBy,
      );

  bool get _hasFilters =>
      _contractId != null || _structure != null || _updatedBy != null;

  void _clearFilters() {
    setState(() {
      _contractId = null;
      _structure = null;
      _updatedBy = null;
      _page = 0;
      _selected.clear();
      _selectedLabels.clear();
    });
  }

  List<DropdownOption> _keep(
    List<DropdownOption> latest,
    List<DropdownOption> previous,
  ) {
    return latest.isNotEmpty ? latest : previous;
  }

  String _cellText(ValidateActivityItem item, String header) {
    String value(String? text) =>
        (text == null || text.trim().isEmpty) ? '-' : text;
    return switch (header) {
      'Task Code' => value(item.taskCode),
      'Structure' => value(item.structure),
      'Component' => value(item.component),
      'Element' => value(item.element),
      'Activity Name' => value(item.activityName),
      'Unit' => value(item.unit),
      'Scope' => value(item.scope),
      'Last activity' => value(item.priorActivity),
      'Last component' => value(item.priorComponent),
      'Last structure' => value(item.priorStructure),
      'Reporting' => value(item.reporting),
      'Actual / updated' => item.actualUpdatedLabel,
      'After activity' => value(item.postActivity),
      'After component' => value(item.postComponent),
      'After structure' => value(item.postStructure),
      'Updated on' => value(_statusDate(item)),
      _ => '-',
    };
  }

  String? _statusDate(ValidateActivityItem item) {
    if (_status == 'Approved') {
      return item.approvedOn ?? item.updatedOn;
    }
    if (_status == 'Rejected') {
      return item.rejectedOn ?? item.updatedOn;
    }
    return item.updatedOn;
  }

  List<ValidateActivityItem> _visible(List<ValidateActivityItem> items) {
    final String query = _search.toLowerCase();
    if (query.isEmpty) {
      return items;
    }
    return items.where((ValidateActivityItem item) {
      return _columns.any((_Column column) {
        return _cellText(item, column.title).toLowerCase().contains(query);
      });
    }).toList();
  }

  Future<void> _runAction({
    required String title,
    required String message,
    required Future<Result<String>> Function() action,
  }) async {
    final bool ok = await GlobalDialog.confirm(
      title: title,
      message: message,
      confirmLabel: title,
    );
    if (!ok || !mounted) {
      return;
    }
    setState(() => _acting = true);
    final result = await action();
    if (!mounted) {
      return;
    }
    setState(() {
      _acting = false;
      _selected.clear();
    });
    result.fold(
      (failure) => GlobalDialog.error(failure.message, title: title),
      (String text) {
        ref.invalidate(validateActivitiesProvider);
        ref.invalidate(validateContractsProvider);
        ref.invalidate(validateStructuresProvider);
        ref.invalidate(validateUpdatedByProvider);
        GlobalDialog.success(text, title: title);
      },
    );
  }

  Future<void> _approve(List<ValidateActivityItem> items) {
    return _runAction(
      title: 'Approve',
      message: items.length == 1
          ? 'Approve progress for ${items.first.taskCode ?? 'this activity'}?'
          : 'Approve ${items.length} selected activities?',
      action: () {
        final repo = ref.read(validateDataRepositoryProvider);
        if (items.length == 1) {
          return repo.approve(items.first);
        }
        return repo.approveMany(items);
      },
    );
  }

  Future<void> _reject(List<ValidateActivityItem> items) {
    return _runAction(
      title: 'Reject',
      message: items.length == 1
          ? 'Reject progress for ${items.first.taskCode ?? 'this activity'}?'
          : 'Reject ${items.length} selected activities?',
      action: () {
        final repo = ref.read(validateDataRepositoryProvider);
        if (items.length == 1) {
          return repo.reject(items.first);
        }
        return repo.rejectMany(items);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    final Color appBarFg =
        theme.appBarTheme.foregroundColor ?? scheme.onPrimary;

    final AsyncValue<List<DropdownOption>> contractsAsync =
        ref.watch(validateContractsProvider(_query));
    final AsyncValue<List<DropdownOption>> structuresAsync =
        ref.watch(validateStructuresProvider(_query));
    final AsyncValue<List<DropdownOption>> updatedByAsync =
        ref.watch(validateUpdatedByProvider(_query));
    final AsyncValue<List<ValidateActivityItem>> activitiesAsync =
        ref.watch(validateActivitiesProvider(_query));

    final List<DropdownOption> contracts =
        _keep(contractsAsync.valueOrNull ?? const [], _contractOptions);
    final List<DropdownOption> structures =
        _keep(structuresAsync.valueOrNull ?? const [], _structureOptions);
    final List<DropdownOption> updatedBy =
        _keep(updatedByAsync.valueOrNull ?? const [], _updatedByOptions);
    if (contractsAsync.hasValue) {
      _contractOptions = contractsAsync.requireValue;
    }
    if (structuresAsync.hasValue) {
      _structureOptions = structuresAsync.requireValue;
    }
    if (updatedByAsync.hasValue) {
      _updatedByOptions = updatedByAsync.requireValue;
    }

    final bool loading = _acting ||
        contractsAsync.isLoading ||
        structuresAsync.isLoading ||
        updatedByAsync.isLoading ||
        activitiesAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approve Activity Progress'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: appBarFg,
          unselectedLabelColor: appBarFg.withValues(alpha: 0.72),
          indicatorColor: appBarFg,
          dividerColor: appBarFg.withValues(alpha: 0.22),
          tabs: _statuses.map((String status) => Tab(text: status)).toList(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            TabBarView(
              controller: _tabController,
              children: _statuses.map((String status) {
                return _tabBody(
                  palette: palette,
                  scheme: scheme,
                  contracts: contracts,
                  structures: structures,
                  updatedBy: updatedBy,
                  activitiesAsync: activitiesAsync,
                  enabled: status == _status,
                );
              }).toList(),
            ),
            if (loading) const AppGlobalLoader(),
          ],
        ),
      ),
    );
  }

  Widget _tabBody({
    required AppPalette palette,
    required ColorScheme scheme,
    required List<DropdownOption> contracts,
    required List<DropdownOption> structures,
    required List<DropdownOption> updatedBy,
    required AsyncValue<List<ValidateActivityItem>> activitiesAsync,
    required bool enabled,
  }) {
    if (!enabled) {
      return const SizedBox.shrink();
    }
    final List<ValidateActivityItem> items = _visible(
      activitiesAsync.valueOrNull ?? const <ValidateActivityItem>[],
    );
    _selectedItems = items
        .where((ValidateActivityItem item) => _selected.contains(item.progressId))
        .toList();
    final int pageCount = items.isEmpty ? 1 : ((items.length - 1) ~/ _pageSize) + 1;
    final int page = _page.clamp(0, pageCount - 1);
    final int start = page * _pageSize;
    final int end = (start + _pageSize).clamp(0, items.length);
    final List<ValidateActivityItem> pageItems = items.sublist(start, end);
    final String? error = activitiesAsync.hasError
        ? activitiesAsync.error.toString().replaceFirst('Exception: ', '')
        : null;

    return Column(
      children: <Widget>[
        _filters(
          contracts: contracts,
          structures: structures,
          updatedBy: updatedBy,
        ),
        Expanded(
          child: activitiesAsync.hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(error ?? 'Failed to load activities'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: <Widget>[
                    _table(
                      palette: palette,
                      scheme: scheme,
                      items: pageItems,
                      pageStart: start,
                    ),
                    const SizedBox(height: 8),
                    AppTablePaginationFooter(
                      total: items.length,
                      startIndex: items.isEmpty ? 0 : start,
                      endIndex: end,
                      currentPage: page,
                      pageCount: pageCount,
                      pageSize: _pageSize,
                      pageSizeOptions: _pageSizeOptions,
                      onPageSizeChanged: (int size) => setState(() {
                        _pageSize = size;
                        _page = 0;
                      }),
                      onPrevious: page > 0
                          ? () => setState(() => _page = page - 1)
                          : null,
                      onNext: page < pageCount - 1
                          ? () => setState(() => _page = page + 1)
                          : null,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _filters({
    required List<DropdownOption> contracts,
    required List<DropdownOption> structures,
    required List<DropdownOption> updatedBy,
  }) {
    final List<ValidateActivityItem> selected = _selectedItems;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: <Widget>[
          _filterField(
            keyName: 'contract',
            label: 'Contract',
            title: 'Select Contract',
            options: contracts,
            value: _contractId,
            onChanged: (String? id) => setState(() {
              _contractId = id;
              _page = 0;
              _selected.clear();
            }),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _filterField(
                  keyName: 'structure',
                  label: 'Structure',
                  title: 'Select Structure',
                  options: structures,
                  value: _structure,
                  onChanged: (String? id) => setState(() {
                    _structure = id;
                    _page = 0;
                    _selected.clear();
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _filterField(
                  keyName: 'updatedBy',
                  label: 'Updated By',
                  title: 'Select Updated By',
                  options: updatedBy,
                  value: _updatedBy,
                  onChanged: (String? id) => setState(() {
                    _updatedBy = id;
                    _page = 0;
                    _selected.clear();
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
          if (_isPending) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: selected.isEmpty ? null : () => _approve(selected),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: selected.isEmpty ? null : () => _reject(selected),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                ),
                OutlinedButton.icon(
                  onPressed: () => GlobalDialog.info(
                    'Enable completed activities will be connected when that request is available.',
                    title: 'Enable completed activities',
                  ),
                  icon: const Icon(Icons.lock_outline_rounded, size: 18),
                  label: const Text('Enable completed'),
                ),
              ],
            ),
          ],
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
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _table({
    required AppPalette palette,
    required ColorScheme scheme,
    required List<ValidateActivityItem> items,
    required int pageStart,
  }) {
    const double selectWidth = 44;
    final double tableWidth = _columns.fold<double>(
      _isPending ? selectWidth : 0,
      (double sum, _Column column) =>
          sum + (column.title == 'Action' && !_isPending ? 0 : column.width),
    );
    final List<_Column> columns = _columns
        .where((_Column column) => _isPending || column.title != 'Action')
        .toList();

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
                children: <Widget>[
                  _header(scheme, columns, items),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text('No records found.'),
                    )
                  else
                    for (int index = 0; index < items.length; index++)
                      _row(
                        items[index],
                        pageStart + index,
                        palette,
                        scheme,
                        columns,
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(
    ColorScheme scheme,
    List<_Column> columns,
    List<ValidateActivityItem> items,
  ) {
    final int selectedOnPage = items
        .where((ValidateActivityItem item) => _selected.contains(item.progressId))
        .length;
    final bool? checked = items.isEmpty || selectedOnPage == 0
        ? false
        : selectedOnPage == items.length
            ? true
            : null;
    return Container(
      color: scheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          if (_isPending)
            SizedBox(
              width: 44,
              child: Checkbox(
                value: checked,
                tristate: true,
                onChanged: items.isEmpty
                    ? null
                    : (bool? value) => setState(() {
                          if (value == true) {
                            _selected.addAll(
                              items.map((ValidateActivityItem item) => item.progressId),
                            );
                          } else {
                            _selected.removeAll(
                              items.map((ValidateActivityItem item) => item.progressId),
                            );
                          }
                        }),
                fillColor: WidgetStatePropertyAll<Color>(scheme.onPrimary),
                checkColor: scheme.primary,
                side: BorderSide(color: scheme.onPrimary),
              ),
            ),
          ...columns.map(
            (_Column column) {
              final String title = column.title == 'Updated on'
                  ? (_status == 'Approved'
                      ? 'Approved on'
                      : _status == 'Rejected'
                          ? 'Rejected on'
                          : 'Updated on')
                  : column.title;
              return _cell(
                column.group == null ? title : '${column.group}\n$title',
                width: column.width,
                color: scheme.onPrimary,
                weight: FontWeight.w700,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _row(
    ValidateActivityItem item,
    int index,
    AppPalette palette,
    ColorScheme scheme,
    List<_Column> columns,
  ) {
    final bool selected = _selected.contains(item.progressId);
    final Color bg = selected
        ? scheme.primary.withValues(alpha: 0.12)
        : (index.isEven ? palette.tableRowEven : palette.tableRowOdd);
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          if (_isPending)
            SizedBox(
              width: 44,
              child: Checkbox(
                value: selected,
                onChanged: (bool? value) => setState(() {
                  if (value == true) {
                    _selected.add(item.progressId);
                  } else {
                    _selected.remove(item.progressId);
                  }
                }),
              ),
            ),
          ...columns.map((_Column column) {
            if (column.title == 'Action') {
              return SizedBox(
                width: column.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _roundAction(
                      icon: Icons.check_rounded,
                      color: scheme.primary,
                      onTap: () => _approve(<ValidateActivityItem>[item]),
                    ),
                    const SizedBox(width: 6),
                    _roundAction(
                      icon: Icons.close_rounded,
                      color: scheme.error,
                      onTap: () => _reject(<ValidateActivityItem>[item]),
                    ),
                  ],
                ),
              );
            }
            return _cell(
              _cellText(item, column.title),
              width: column.width,
              bold: column.title == 'Task Code',
            );
          }),
        ],
      ),
    );
  }

  Widget _roundAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _cell(
    String value, {
    required double width,
    Color? color,
    FontWeight weight = FontWeight.w500,
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
        !items.any((DropdownOption option) => option.id == value)) {
      items.add(
        DropdownOption(id: value, name: _selectedLabels[keyName] ?? value),
      );
    }
    return AppSelectSheetField<String>(
      label: label,
      title: title,
      items: items.map((DropdownOption option) => option.id).toList(),
      value: value,
      itemLabelBuilder: (String id) {
        if (id.isEmpty) {
          return 'Select';
        }
        return items
            .firstWhere(
              (DropdownOption option) => option.id == id,
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
              (DropdownOption option) => option.id == id,
              orElse: () => DropdownOption(id: id, name: id),
            )
            .name;
        _selectedLabels[keyName] = name;
        onChanged(id);
      },
    );
  }
}

class _Column {
  const _Column(this.title, this.width, {this.group});

  final String title;
  final double width;
  final String? group;
}
