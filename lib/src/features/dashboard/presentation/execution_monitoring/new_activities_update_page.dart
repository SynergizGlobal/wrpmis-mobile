import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/new_activity_row.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/execution_monitoring/providers/new_activities_update_providers.dart';

/// Update Forms → Execution & Monitoring → New Activities Update.
class NewActivitiesUpdatePage extends ConsumerStatefulWidget {
  const NewActivitiesUpdatePage({super.key});

  static const String routeName = 'new-activities-update';
  static const String routePath = '/new-activities-update';

  @override
  ConsumerState<NewActivitiesUpdatePage> createState() =>
      _NewActivitiesUpdatePageState();
}

class _NewActivitiesUpdatePageState
    extends ConsumerState<NewActivitiesUpdatePage> {
  static final DateFormat _displayDate = DateFormat('dd-MMM-yy');

  final TextEditingController _remarksController = TextEditingController();
  final Map<String, TextEditingController> _actualControllers =
      <String, TextEditingController>{};

  String? _projectId;
  String? _contractId;
  String? _structureType;
  String? _structureId;
  String? _component;
  String? _elementId;
  DateTime _dataDate = DateTime.now();

  @override
  void dispose() {
    _remarksController.dispose();
    for (final TextEditingController c in _actualControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  NewActivitiesListQuery get _listQuery => NewActivitiesListQuery(
        contractId: _contractId ?? '',
        structureId: _structureId ?? '',
        component: _component ?? '',
        structureType: _structureType ?? '',
        elementId: _elementId ?? '',
      );

  void _clearFromContractDown() {
    _structureType = null;
    _structureId = null;
    _component = null;
    _elementId = null;
    _clearActualInputs();
  }

  void _clearFromTypeDown() {
    _structureId = null;
    _component = null;
    _elementId = null;
    _clearActualInputs();
  }

  void _clearFromStructureDown() {
    _component = null;
    _elementId = null;
    _clearActualInputs();
  }

  void _clearFromComponentDown() {
    _elementId = null;
    _clearActualInputs();
  }

  void _clearActualInputs() {
    for (final TextEditingController c in _actualControllers.values) {
      c.dispose();
    }
    _actualControllers.clear();
  }

  TextEditingController _actualControllerFor(NewActivityRow row) {
    final String key =
        row.activityId.isNotEmpty ? row.activityId : row.taskCode;
    return _actualControllers.putIfAbsent(key, TextEditingController.new);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dataDate = picked);
    }
  }

  void _resetFilters() {
    setState(() {
      _projectId = null;
      _contractId = null;
      _structureType = null;
      _structureId = null;
      _component = null;
      _elementId = null;
      _dataDate = DateTime.now();
      _remarksController.clear();
      _clearActualInputs();
    });
  }

  void _comingSoon(String action) {
    GlobalDialog.info(
      '$action will be connected when the API is available.',
      title: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final AsyncValue<List<DropdownOption>> projectsAsync =
        ref.watch(newActivitiesProjectsProvider);
    final AsyncValue<List<DropdownOption>> contractsAsync =
        ref.watch(newActivitiesContractsProvider);
    final AsyncValue<NewActivitiesLatestInfo?> latestAsync =
        ref.watch(newActivitiesLatestProvider);

    final List<DropdownOption> contractsForProject =
        contractsAsync.maybeWhen(
              data: (List<DropdownOption> all) {
                if (_projectId == null || _projectId!.isEmpty) {
                  return all;
                }
                return all
                    .where((DropdownOption c) => c.extra == _projectId)
                    .toList();
              },
              orElse: () => const <DropdownOption>[],
            ) ??
            const <DropdownOption>[];

    return Scaffold(
      appBar: AppBar(title: const Text('New Activities Update')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              children: <Widget>[
                _latestBox(latestAsync, scheme),
                const SizedBox(height: 12),
                _filterField(
                  label: 'Project',
                  title: 'Select Project',
                  async: projectsAsync,
                  value: _projectId,
                  onChanged: (String? id) {
                    setState(() {
                      _projectId = id;
                      _contractId = null;
                      _clearFromContractDown();
                    });
                  },
                  scheme: scheme,
                ),
                const SizedBox(height: 10),
                _optionsField(
                  label: 'Contract *',
                  title: 'Select Contract',
                  options: contractsForProject,
                  value: _contractId,
                  enabled: _projectId != null,
                  loading: contractsAsync.isLoading,
                  error: contractsAsync.hasError ? contractsAsync.error : null,
                  onChanged: (String? id) {
                    setState(() {
                      _contractId = id;
                      _clearFromContractDown();
                    });
                  },
                  scheme: scheme,
                ),
                const SizedBox(height: 10),
                if (_contractId != null)
                  _filterField(
                    label: 'Structure Type *',
                    title: 'Select Structure Type',
                    async: ref.watch(
                      newActivitiesStructureTypesProvider(_contractId!),
                    ),
                    value: _structureType,
                    onChanged: (String? id) {
                      setState(() {
                        _structureType = id;
                        _clearFromTypeDown();
                      });
                    },
                    scheme: scheme,
                  ),
                if (_contractId != null) const SizedBox(height: 10),
                if (_contractId != null && _structureType != null)
                  _filterField(
                    label: 'Structure *',
                    title: 'Select Structure',
                    async: ref.watch(
                      newActivitiesStructuresProvider(
                        NewActivitiesStructuresQuery(
                          contractId: _contractId!,
                          structureType: _structureType!,
                        ),
                      ),
                    ),
                    value: _structureId,
                    onChanged: (String? id) {
                      setState(() {
                        _structureId = id;
                        _clearFromStructureDown();
                      });
                    },
                    scheme: scheme,
                  ),
                if (_contractId != null && _structureType != null)
                  const SizedBox(height: 10),
                if (_contractId != null &&
                    _structureType != null &&
                    _structureId != null)
                  _filterField(
                    label: 'Component *',
                    title: 'Select Component',
                    async: ref.watch(
                      newActivitiesComponentsProvider(
                        NewActivitiesComponentsQuery(
                          contractId: _contractId!,
                          structureId: _structureId!,
                          structureType: _structureType!,
                        ),
                      ),
                    ),
                    value: _component,
                    onChanged: (String? id) {
                      setState(() {
                        _component = id;
                        _clearFromComponentDown();
                      });
                    },
                    scheme: scheme,
                  ),
                if (_contractId != null &&
                    _structureType != null &&
                    _structureId != null)
                  const SizedBox(height: 10),
                if (_contractId != null &&
                    _structureType != null &&
                    _structureId != null &&
                    _component != null)
                  _filterField(
                    label: 'Element',
                    title: 'Select Element',
                    async: ref.watch(
                      newActivitiesElementsProvider(
                        NewActivitiesElementsQuery(
                          contractId: _contractId!,
                          structureId: _structureId!,
                          component: _component!,
                          structureType: _structureType!,
                        ),
                      ),
                    ),
                    value: _elementId,
                    onChanged: (String? id) {
                      setState(() {
                        _elementId = id;
                        _clearActualInputs();
                      });
                    },
                    scheme: scheme,
                  ),
                if (_contractId != null &&
                    _structureType != null &&
                    _structureId != null &&
                    _component != null)
                  const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            suffixIcon: Icon(Icons.calendar_today_rounded),
                          ),
                          child: Text(_displayDate.format(_dataDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _comingSoon('Attach Photo'),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Attach Photo'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Activities',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                _activitiesSection(scheme, palette),
              ],
            ),
          ),
          _bottomActions(scheme),
        ],
      ),
    );
  }

  Widget _latestBox(
    AsyncValue<NewActivitiesLatestInfo?> latestAsync,
    ColorScheme scheme,
  ) {
    return latestAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (NewActivitiesLatestInfo? info) {
        if (info == null || info.displayLabel.isEmpty) {
          return const SizedBox.shrink();
        }
        return Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              final List<DropdownOption> contracts =
                  ref.read(newActivitiesContractsProvider).maybeWhen(
                        data: (List<DropdownOption> all) => all,
                        orElse: () => const <DropdownOption>[],
                      ) ??
                      const <DropdownOption>[];
              String? projectFromContract;
              if (info.contractId.isNotEmpty) {
                for (final DropdownOption c in contracts) {
                  if (c.id == info.contractId) {
                    projectFromContract = c.extra;
                    break;
                  }
                }
              }
              setState(() {
                if (projectFromContract != null &&
                    projectFromContract.isNotEmpty) {
                  _projectId = projectFromContract;
                }
                if (info.contractId.isNotEmpty) {
                  _contractId = info.contractId;
                }
                if (info.structureType.isNotEmpty) {
                  _structureType = info.structureType;
                }
                if (info.structure.isNotEmpty) {
                  _structureId = info.structure;
                }
                if (info.component.isNotEmpty) {
                  _component = info.component;
                }
                _elementId = null;
                _clearActualInputs();
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Latest Updated Structure --> Component',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.displayLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: scheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _activitiesSection(ColorScheme scheme, AppPalette palette) {
    if (!_listQuery.isReady) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select Contract, Structure Type, Structure, and Component to load activities.',
            style: TextStyle(color: palette.mutedText),
          ),
        ),
      );
    }

    final AsyncValue<List<NewActivityRow>> listAsync =
        ref.watch(newActivitiesListProvider(_listQuery));

    return listAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Unable to load activities: $e',
            style: TextStyle(color: scheme.error),
          ),
        ),
      ),
      data: (List<NewActivityRow> rows) {
        if (rows.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No activities found for the selected filters.',
                style: TextStyle(color: palette.mutedText),
              ),
            ),
          );
        }
        return Column(
          children: <Widget>[
            for (final NewActivityRow row in rows) ...<Widget>[
              _activityCard(row, scheme, palette),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _activityCard(
    NewActivityRow row,
    ColorScheme scheme,
    AppPalette palette,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    row.taskCode.isEmpty ? '-' : row.taskCode,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (row.dataDate.isNotEmpty)
                  Text(
                    'Updated ${row.dataDate}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.mutedText,
                        ),
                  ),
              ],
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
                _chip('Baseline Start', row.baselineStart, scheme),
                _chip('Baseline Finish', row.baselineFinish, scheme),
                _chip('Expected Start', row.expectedStart, scheme),
                _chip('Expected Finish', row.expectedFinish, scheme),
                _chip('Scope', row.scope, scheme),
                _chip(
                  'Validation Pending',
                  row.validationPending,
                  scheme,
                  emphasize: true,
                ),
                _chip('Completed', row.completed, scheme),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _actualControllerFor(row),
              decoration: const InputDecoration(
                labelText: 'Actual',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    String label,
    String value,
    ColorScheme scheme, {
    bool emphasize = false,
  }) {
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
                  color: emphasize ? scheme.error : scheme.onSurface,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _comingSoon('Update'),
                      child: const Text('UPDATE'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _resetFilters,
                      child: const Text('RESET'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _comingSoon('Export'),
                      child: const Text('EXPORT'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _comingSoon('Upload'),
                      child: const Text('UPLOAD'),
                    ),
                  ),
                ],
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
        return _optionsField(
          label: label,
          title: title,
          options: options,
          value: value,
          onChanged: onChanged,
          scheme: scheme,
        );
      },
    );
  }

  Widget _optionsField({
    required String label,
    required String title,
    required List<DropdownOption> options,
    required String? value,
    required ValueChanged<String?> onChanged,
    required ColorScheme scheme,
    bool enabled = true,
    bool loading = false,
    Object? error,
  }) {
    if (loading) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (error != null) {
      return Text(
        'Unable to load $label: $error',
        style: TextStyle(color: scheme.error, fontSize: 12),
      );
    }
    final List<DropdownOption> items = <DropdownOption>[
      const DropdownOption(id: '', name: 'Select'),
      ...options,
    ];
    return AppSelectSheetField<String>(
      label: label,
      title: title,
      enabled: enabled,
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
  }
}
