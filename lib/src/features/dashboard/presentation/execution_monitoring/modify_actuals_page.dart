import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_table_pagination_footer.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/new_activity_row.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/execution_monitoring/providers/modify_actuals_providers.dart';

/// Update Forms → Execution & Monitoring → Modify Actuals.
class ModifyActualsPage extends ConsumerStatefulWidget {
  const ModifyActualsPage({super.key});

  static const String routeName = 'modify-actuals';
  static const String routePath = '/modify-actuals';

  @override
  ConsumerState<ModifyActualsPage> createState() => _ModifyActualsPageState();
}

class _ModifyActualsPageState extends ConsumerState<ModifyActualsPage> {
  static const List<int> _pageSizeOptions = <int>[5, 10, 25, 50];

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = <String>{};

  ModifyActualsAction? _action;
  String? _contractId;
  String? _structureId;
  String _searchQuery = '';
  int _pageSize = 10;
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ModifyActualsListQuery get _listQuery => ModifyActualsListQuery(
        action: _action,
        contractId: _contractId ?? '',
        structureId: _structureId ?? '',
        searchStr: _searchQuery,
      );

  String _rowKey(NewActivityRow row) {
    if (row.activityId.isNotEmpty) {
      return row.activityId;
    }
    return row.taskCode;
  }

  void _clearSelection() {
    _selectedIds.clear();
  }

  void _resetAll() {
    setState(() {
      _action = null;
      _contractId = null;
      _structureId = null;
      _searchQuery = '';
      _currentPage = 0;
      _pageSize = 10;
      _searchController.clear();
      _clearSelection();
    });
  }

  void _onUpdateStub() {
    GlobalDialog.info(
      _selectedIds.isEmpty
          ? 'Select one or more activities, then Update will be connected when the API is available.'
          : 'Update for ${_selectedIds.length} selected item(s) will be connected when the API is available.',
      title: 'UPDATE',
    );
  }

  void _setSearch(String value) {
    setState(() {
      _searchQuery = value.trim();
      _currentPage = 0;
      _clearSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final AsyncValue<List<DropdownOption>> contractsAsync =
        ref.watch(modifyActualsContractsProvider);

    final AsyncValue<List<NewActivityRow>>? listAsync =
        _listQuery.isReady ? ref.watch(modifyActualsListProvider(_listQuery)) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Modify Actuals')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: listAsync == null
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    children: <Widget>[
                      _actionSection(),
                      if (_action != null) ...<Widget>[
                        const SizedBox(height: 12),
                        _contractField(contractsAsync, scheme),
                      ],
                      if (_action?.requiresStructure == true &&
                          _contractId != null) ...<Widget>[
                        const SizedBox(height: 10),
                        _structureField(scheme),
                      ],
                      if (_action != null && _contractId != null) ...<Widget>[
                        const SizedBox(height: 10),
                        _searchField(),
                      ],
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _hintMessage(),
                            style: TextStyle(color: palette.mutedText),
                          ),
                        ),
                      ),
                    ],
                  )
                : listAsync.when(
                    loading: () => ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      children: <Widget>[
                        _actionSection(),
                        const SizedBox(height: 12),
                        _contractField(contractsAsync, scheme),
                        if (_action?.requiresStructure == true) ...<Widget>[
                          const SizedBox(height: 10),
                          _structureField(scheme),
                        ],
                        const SizedBox(height: 10),
                        _searchField(),
                        const SizedBox(height: 24),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                    error: (Object error, StackTrace _) => ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      children: <Widget>[
                        _actionSection(),
                        const SizedBox(height: 12),
                        _contractField(contractsAsync, scheme),
                        if (_action?.requiresStructure == true) ...<Widget>[
                          const SizedBox(height: 10),
                          _structureField(scheme),
                        ],
                        const SizedBox(height: 10),
                        _searchField(),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: <Widget>[
                                Text(
                                  'Unable to load activities: $error',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: scheme.error),
                                ),
                                const SizedBox(height: 10),
                                FilledButton(
                                  onPressed: () => ref.invalidate(
                                    modifyActualsListProvider(_listQuery),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    data: (List<NewActivityRow> rows) {
                      final int total = rows.length;
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
                          total == 0 ? 0 : _currentPage * _pageSize;
                      final int end = total == 0
                          ? 0
                          : (start + _pageSize).clamp(0, total);
                      final List<NewActivityRow> pageRows =
                          total == 0 ? const <NewActivityRow>[] : rows.sublist(start, end);
                      final List<String> pageKeys =
                          pageRows.map(_rowKey).where((String k) => k.isNotEmpty).toList();
                      final bool allPageSelected = pageKeys.isNotEmpty &&
                          pageKeys.every(_selectedIds.contains);

                      return Column(
                        children: <Widget>[
                          Expanded(
                            child: CustomScrollView(
                              slivers: <Widget>[
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                                  sliver: SliverList(
                                    delegate: SliverChildListDelegate(
                                      <Widget>[
                                        _actionSection(),
                                        const SizedBox(height: 12),
                                        _contractField(contractsAsync, scheme),
                                        if (_action?.requiresStructure == true) ...<Widget>[
                                          const SizedBox(height: 10),
                                          _structureField(scheme),
                                        ],
                                        const SizedBox(height: 10),
                                        _searchField(),
                                        const SizedBox(height: 12),
                                        if (pageRows.isNotEmpty)
                                          _selectAllRow(
                                            allPageSelected: allPageSelected,
                                            pageKeys: pageKeys,
                                            scheme: scheme,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (pageRows.isEmpty)
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Text(
                                          'No activities found.',
                                          style: TextStyle(color: palette.mutedText),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (BuildContext context, int index) {
                                          final NewActivityRow row = pageRows[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 10),
                                            child: _activityCard(row, scheme),
                                          );
                                        },
                                        childCount: pageRows.length,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
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
                                _clearSelection();
                              }),
                              onPrevious: _currentPage > 0
                                  ? () => setState(() {
                                        _currentPage--;
                                        _clearSelection();
                                      })
                                  : null,
                              onNext: end < total
                                  ? () => setState(() {
                                        _currentPage++;
                                        _clearSelection();
                                      })
                                  : null,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          _bottomActions(scheme),
        ],
      ),
    );
  }

  String _hintMessage() {
    if (_action == null) {
      return 'Select an action to continue.';
    }
    if (_contractId == null) {
      return 'Select a contract to load activities.';
    }
    if (_action!.requiresStructure && _structureId == null) {
      return 'Select a structure to load activities.';
    }
    return 'Loading filters…';
  }

  Widget _actionSection() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              'Action *',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          RadioGroup<ModifyActualsAction>(
            groupValue: _action,
            onChanged: (ModifyActualsAction? value) {
              setState(() {
                _action = value;
                _contractId = null;
                _structureId = null;
                _currentPage = 0;
                _clearSelection();
              });
            },
            child: Column(
              children: <Widget>[
                for (final ModifyActualsAction action
                    in ModifyActualsAction.values)
                  RadioListTile<ModifyActualsAction>(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      action.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    value: action,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contractField(
    AsyncValue<List<DropdownOption>> contractsAsync,
    ColorScheme scheme,
  ) {
    return _filterField(
      label: 'Contract *',
      title: 'Select Contract',
      async: contractsAsync,
      value: _contractId,
      onChanged: (String? id) {
        setState(() {
          _contractId = id;
          _structureId = null;
          _currentPage = 0;
          _clearSelection();
        });
      },
      scheme: scheme,
    );
  }

  Widget _structureField(ColorScheme scheme) {
    final AsyncValue<List<DropdownOption>> structuresAsync =
        ref.watch(modifyActualsStructuresProvider(_contractId ?? ''));
    return _filterField(
      label: 'Structure *',
      title: 'Select Structure',
      async: structuresAsync,
      value: _structureId,
      onChanged: (String? id) {
        setState(() {
          _structureId = id;
          _currentPage = 0;
          _clearSelection();
        });
      },
      scheme: scheme,
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _searchController.clear();
                  _setSearch('');
                },
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textInputAction: TextInputAction.search,
      onChanged: _setSearch,
      onSubmitted: _setSearch,
    );
  }

  Widget _selectAllRow({
    required bool allPageSelected,
    required List<String> pageKeys,
    required ColorScheme scheme,
  }) {
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: CheckboxListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          'Select all on this page',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        value: allPageSelected,
        onChanged: pageKeys.isEmpty
            ? null
            : (bool? checked) {
                setState(() {
                  if (checked == true) {
                    _selectedIds.addAll(pageKeys);
                  } else {
                    _selectedIds.removeAll(pageKeys);
                  }
                });
              },
      ),
    );
  }

  Widget _activityCard(NewActivityRow row, ColorScheme scheme) {
    final String key = _rowKey(row);
    final bool selectable = key.isNotEmpty;
    final bool selected = selectable && _selectedIds.contains(key);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: !selectable
            ? null
            : () {
                setState(() {
                  if (selected) {
                    _selectedIds.remove(key);
                  } else {
                    _selectedIds.add(key);
                  }
                });
              },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Checkbox(
                value: selected,
                onChanged: !selectable
                    ? null
                    : (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedIds.add(key);
                          } else {
                            _selectedIds.remove(key);
                          }
                        });
                      },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 8),
                    Text(
                      row.taskCode.isEmpty ? '-' : row.taskCode,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.activityName.isEmpty ? '-' : row.activityName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _chip('Scope', row.scope, scheme),
                        _chip('Completed', row.completed, scheme),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value, ColorScheme scheme) {
    final String text = value.isEmpty ? '-' : value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _bottomActions(ColorScheme scheme) {
    return Material(
      elevation: 8,
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  onPressed: _onUpdateStub,
                  child: const Text('UPDATE'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _resetAll,
                  child: const Text('RESET'),
                ),
              ),
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
                  orElse: () => const DropdownOption(id: '', name: 'Select'),
                )
                .name;
          },
          onChanged: (String id) => onChanged(id.isEmpty ? null : id),
        );
      },
    );
  }
}
