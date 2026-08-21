import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/project_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_form_edit_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/structures/providers/structure_form_edit_providers.dart';

/// Update Forms → Works → Update Structure → pencil → Update Structure Form.
class UpdateStructureFormPage extends ConsumerStatefulWidget {
  const UpdateStructureFormPage({super.key, required this.structureId});

  static const String routeName = 'update-structure-form';
  static const String routePath = '/update-structure-form';

  final String structureId;

  @override
  ConsumerState<UpdateStructureFormPage> createState() =>
      _UpdateStructureFormPageState();
}

class _UpdateStructureFormPageState
    extends ConsumerState<UpdateStructureFormPage> {
  static final DateFormat _displayDate = DateFormat('dd-MM-yyyy');
  static const List<DropdownOption> _costUnits = <DropdownOption>[
    DropdownOption(id: '1', name: 'Rs'),
    DropdownOption(id: '1000', name: 'Th'),
    DropdownOption(id: '100000', name: 'L'),
    DropdownOption(id: '10000000', name: 'Cr'),
  ];
  static const List<DropdownOption> _fileTypes = <DropdownOption>[
    DropdownOption(id: 'Drawing', name: 'Drawing'),
    DropdownOption(id: 'Photograph', name: 'Photograph'),
    DropdownOption(id: 'Document', name: 'Document'),
    DropdownOption(id: 'Report', name: 'Report'),
    DropdownOption(id: 'Other', name: 'Other'),
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _prefilled = false;

  String? _projectId;
  String? _projectLabel;
  String? _structureType;
  String? _workStatus;
  String? _existingWorkStatus;
  String? _costUnit;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _structureCtrl = TextEditingController();
  final TextEditingController _costCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();

  DateTime? _targetDate;
  DateTime? _constructionStart;
  DateTime? _revisedCompletion;

  List<StructureFormOption> _structureTypes = const <StructureFormOption>[];
  List<StructureFormOption> _workStatuses = const <StructureFormOption>[];

  final List<_ContractExecRow> _contractRows = <_ContractExecRow>[];
  final List<_DetailRow> _detailRows = <_DetailRow>[];
  final List<_DocRow> _docRows = <_DocRow>[];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _structureCtrl.dispose();
    _costCtrl.dispose();
    _remarksCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    for (final _ContractExecRow r in _contractRows) {
      r.dispose();
    }
    for (final _DetailRow r in _detailRows) {
      r.dispose();
    }
    for (final _DocRow r in _docRows) {
      r.dispose();
    }
    super.dispose();
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return _displayDate.parse(raw.trim());
    } catch (_) {
      return DateTime.tryParse(raw.trim());
    }
  }

  String _fmt(DateTime? d) => d == null ? '' : _displayDate.format(d);

  void _prefill(StructureFormEditDetail detail) {
    if (_prefilled) return;
    _prefilled = true;

    _projectId = detail.projectIdFk;
    _projectLabel = detail.projectLabel ?? detail.projectIdFk;
    _structureType = detail.structureTypeFk;
    _workStatus = detail.workStatusFk;
    _existingWorkStatus = detail.existingWorkStatusFk ?? detail.workStatusFk;
    _costUnit = detail.estimatedCostUnits;
    _nameCtrl.text = detail.structureName ?? '';
    _structureCtrl.text = detail.structure ?? '';
    _costCtrl.text = detail.estimatedCost ?? '';
    _remarksCtrl.text = detail.remarks ?? '';
    _latCtrl.text = detail.latitude ?? '';
    _lngCtrl.text = detail.longitude ?? '';
    _targetDate = _parseDate(detail.targetDate);
    _constructionStart = _parseDate(detail.constructionStartDate);
    _revisedCompletion = _parseDate(detail.revisedCompletion);
    _structureTypes = detail.structureTypes;
    _workStatuses = detail.workStatuses.isNotEmpty
        ? detail.workStatuses
        : const <StructureFormOption>[
            StructureFormOption(id: 'Not Started', name: 'Not Started'),
            StructureFormOption(id: 'In Progress', name: 'In Progress'),
            StructureFormOption(id: 'On Hold', name: 'On Hold'),
            StructureFormOption(id: 'Commissioned', name: 'Commissioned'),
            StructureFormOption(id: 'Dropped', name: 'Dropped'),
          ];

    for (final _ContractExecRow r in _contractRows) {
      r.dispose();
    }
    _contractRows
      ..clear()
      ..addAll(
        detail.contractRows.isEmpty
            ? <_ContractExecRow>[_ContractExecRow()]
            : detail.contractRows.map(_ContractExecRow.fromEntity),
      );

    for (final _DetailRow r in _detailRows) {
      r.dispose();
    }
    _detailRows
      ..clear()
      ..addAll(
        detail.detailRows.isEmpty
            ? <_DetailRow>[_DetailRow()]
            : detail.detailRows.map(_DetailRow.fromEntity),
      );

    for (final _DocRow r in _docRows) {
      r.dispose();
    }
    _docRows
      ..clear()
      ..addAll(
        detail.documentRows.isEmpty
            ? <_DocRow>[_DocRow()]
            : detail.documentRows.map(_DocRow.fromEntity),
      );
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_projectId == null || _projectId!.isEmpty) {
      await GlobalDialog.error('Project is required.');
      return;
    }
    if (_structureType == null || _structureType!.isEmpty) {
      await GlobalDialog.error('Structure Type is required.');
      return;
    }
    if (_workStatus == null || _workStatus!.isEmpty) {
      await GlobalDialog.error('Work Status is required.');
      return;
    }

    setState(() => _submitting = true);

    final Map<String, dynamic> map = <String, dynamic>{
      'structure_id': widget.structureId,
      'project_id_fk': _projectId,
      'structure_type_fk': _structureType,
      'structure_name': _nameCtrl.text.trim(),
      'structure': _structureCtrl.text.trim(),
      'work_status_fk': _workStatus,
      'existing_work_status_fk': _existingWorkStatus ?? _workStatus,
      'target_date': _fmt(_targetDate),
      'estimated_cost': _costCtrl.text.trim(),
      'estimated_cost_units': _costUnit ?? '',
      'remarks': _remarksCtrl.text.trim(),
      'latitude': _latCtrl.text.trim(),
      'longitude': _lngCtrl.text.trim(),
      'construction_start_date': _fmt(_constructionStart),
      'revised_completion': _fmt(_revisedCompletion),
      'structureContractRowNo': '${_contractRows.length}',
    };

    final FormData form = FormData.fromMap(map);

    for (final _ContractExecRow row in _contractRows) {
      if (row.contractId == null || row.contractId!.isEmpty) continue;
      form.fields.add(MapEntry('contracts_id_fk', row.contractId!));
      form.fields.add(
        MapEntry('responsible_people_id_fks', row.executiveIds.join(',')),
      );
      for (final String id in row.executiveIds) {
        form.fields.add(MapEntry('excecutives', id));
      }
    }

    for (final _DetailRow row in _detailRows) {
      final String detail = row.detailCtrl.text.trim();
      final String value = row.valueCtrl.text.trim();
      if (detail.isEmpty && value.isEmpty) continue;
      form.fields.add(MapEntry('structure_details', detail));
      form.fields.add(MapEntry('structure_values', value));
    }

    for (final _DocRow row in _docRows) {
      final String type = row.fileType ?? '';
      final String name = row.nameCtrl.text.trim();
      if (type.isEmpty && name.isEmpty && row.fileId.isEmpty) continue;
      form.fields.add(MapEntry('structure_file_types', type));
      form.fields.add(MapEntry('structureDocumentNames', name));
      form.fields.add(MapEntry('structure_file_ids', row.fileId));
      form.fields.add(MapEntry('structureFileNames', row.existingFileName));
    }

    final result =
        await ref.read(projectRepositoryProvider).updateStructureForm(form);

    if (!mounted) return;
    setState(() => _submitting = false);

    await result.fold(
      (failure) async => GlobalDialog.error(failure.message),
      (message) async {
        await GlobalDialog.success(message);
        if (mounted) context.pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(structureFormEditProvider(widget.structureId));
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Update Structure Form')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () => ref.invalidate(
                    structureFormEditProvider(widget.structureId),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (StructureFormEditDetail detail) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_prefilled && mounted) setState(() => _prefill(detail));
          });
          return _buildBody(palette, scheme);
        },
      ),
    );
  }

  Widget _buildBody(AppPalette palette, ColorScheme scheme) {
    final AsyncValue<List<DropdownOption>> contractsAsync = ref.watch(
      structureFormContractsProvider(_projectId ?? ''),
    );

    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: <Widget>[
                _readOnlyField('Project *', _projectLabel ?? _projectId ?? '—'),
                const SizedBox(height: 12),
                _dropdown(
                  'Structure Type *',
                  _structureTypes
                      .map((StructureFormOption o) => DropdownOption(
                            id: o.id,
                            name: o.name,
                          ))
                      .toList(),
                  _structureType,
                  (String? v) => setState(() => _structureType = v),
                  required: true,
                ),
                const SizedBox(height: 12),
                _text('Structure Name *', _nameCtrl, required: true),
                const SizedBox(height: 12),
                _text('Structure ID *', _structureCtrl, required: true),
                const SizedBox(height: 12),
                _dropdown(
                  'Work Status *',
                  _workStatuses
                      .map((StructureFormOption o) => DropdownOption(
                            id: o.id,
                            name: o.name,
                          ))
                      .toList(),
                  _workStatus,
                  (String? v) => setState(() => _workStatus = v),
                  required: true,
                ),
                const SizedBox(height: 20),
                Text(
                  'Contract - Execution Executives',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _sectionTable(
                  palette: palette,
                  scheme: scheme,
                  headers: const <String>[
                    'Contract *',
                    'Responsible Executives *',
                    'Action',
                  ],
                  headerFlex: const <int>[4, 4, 1],
                  rows: <Widget>[
                    for (int i = 0; i < _contractRows.length; i++)
                      _contractRow(i, contractsAsync, palette, scheme),
                  ],
                  onAdd: () => setState(() => _contractRows.add(_ContractExecRow())),
                ),
                const SizedBox(height: 16),
                _dateField(
                  'Original Target Date',
                  _targetDate,
                  (DateTime d) => setState(() => _targetDate = d),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Estimated Cost',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _dropdown(
                        'Unit',
                        _costUnits,
                        _costUnit,
                        (String? v) => setState(() => _costUnit = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _remarksCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(child: _text('Latitude', _latCtrl)),
                    const SizedBox(width: 8),
                    Expanded(child: _text('Longitude', _lngCtrl)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _dateField(
                        'Construction Start Date',
                        _constructionStart,
                        (DateTime d) =>
                            setState(() => _constructionStart = d),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _dateField(
                        'Target completion Date',
                        _revisedCompletion,
                        (DateTime d) =>
                            setState(() => _revisedCompletion = d),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Structure Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _sectionTable(
                  palette: palette,
                  scheme: scheme,
                  headers: const <String>[
                    'Structure Detail',
                    'Value',
                    'Action',
                  ],
                  headerFlex: const <int>[4, 4, 1],
                  rows: <Widget>[
                    for (int i = 0; i < _detailRows.length; i++)
                      _detailRow(i, scheme),
                  ],
                  onAdd: () => setState(() => _detailRows.add(_DetailRow())),
                ),
                const SizedBox(height: 20),
                Text(
                  'Documents',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _sectionTable(
                  palette: palette,
                  scheme: scheme,
                  headers: const <String>[
                    'File Type',
                    'Name',
                    'Attachment',
                    'Action',
                  ],
                  headerFlex: const <int>[3, 3, 3, 1],
                  rows: <Widget>[
                    for (int i = 0; i < _docRows.length; i++)
                      _docRow(i, scheme),
                  ],
                  onAdd: () => setState(() => _docRows.add(_DocRow())),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: palette.stickyBar,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        minimumSize: const Size(0, 48),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : const Text('UPDATE'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.brandAppBar,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _submitting ? null : () => context.pop(),
                      child: const Text('CANCEL'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contractRow(
    int index,
    AsyncValue<List<DropdownOption>> contractsAsync,
    AppPalette palette,
    ColorScheme scheme,
  ) {
    final _ContractExecRow row = _contractRows[index];
    final List<DropdownOption> contracts = contractsAsync.valueOrNull ??
        const <DropdownOption>[];
    final AsyncValue<List<DropdownOption>> execAsync =
        ref.watch(structureFormExecutivesProvider(row.contractId ?? ''));
    final List<DropdownOption> executives =
        execAsync.valueOrNull ?? const <DropdownOption>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<String>(
              key: ValueKey<String>('c-$index-${row.contractId}'),
              initialValue: contracts.any((DropdownOption o) => o.id == row.contractId)
                  ? row.contractId
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                border: UnderlineInputBorder(),
              ),
              hint: const Text('Select'),
              items: contracts
                  .map(
                    (DropdownOption o) => DropdownMenuItem<String>(
                      value: o.id,
                      child: Text(o.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (String? v) {
                setState(() {
                  row.contractId = v;
                  row.executiveIds.clear();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: () => _pickExecutives(row, executives),
              child: InputDecorator(
                decoration: const InputDecoration(
                  isDense: true,
                  border: UnderlineInputBorder(),
                  hintText: 'Select',
                ),
                child: Text(
                  row.executiveIds.isEmpty
                      ? 'Select'
                      : row.executiveIds
                          .map((String id) {
                            for (final DropdownOption o in executives) {
                              if (o.id == id) return o.name;
                            }
                            return id;
                          })
                          .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: row.executiveIds.isEmpty
                        ? palette.mutedText
                        : scheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _contractRows.length <= 1
                ? null
                : () => setState(() {
                      _contractRows.removeAt(index).dispose();
                    }),
            icon: Icon(Icons.cancel, color: Colors.red.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExecutives(
    _ContractExecRow row,
    List<DropdownOption> options,
  ) async {
    if (row.contractId == null || row.contractId!.isEmpty) {
      await GlobalDialog.info('Select a contract first.');
      return;
    }
    if (options.isEmpty) {
      await GlobalDialog.info('No responsible executives for this contract.');
      return;
    }
    final Set<String> selected = Set<String>.from(row.executiveIds);
    final Set<String>? result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModal) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: <Widget>[
                    const ListTile(title: Text('Responsible Executives')),
                    Expanded(
                      child: ListView(
                        children: options
                            .map(
                              (DropdownOption o) => CheckboxListTile(
                                value: selected.contains(o.id),
                                title: Text(o.name),
                                onChanged: (bool? v) {
                                  setModal(() {
                                    if (v == true) {
                                      selected.add(o.id);
                                    } else {
                                      selected.remove(o.id);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, selected),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (result != null) {
      setState(() {
        row.executiveIds
          ..clear()
          ..addAll(result);
      });
    }
  }

  Widget _detailRow(int index, ColorScheme scheme) {
    final _DetailRow row = _detailRows[index];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: row.detailCtrl,
              decoration: const InputDecoration(
                hintText: 'Detail name',
                isDense: true,
                border: UnderlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: row.valueCtrl,
              decoration: const InputDecoration(
                hintText: 'Value',
                isDense: true,
                border: UnderlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            onPressed: _detailRows.length <= 1
                ? null
                : () => setState(() {
                      _detailRows.removeAt(index).dispose();
                    }),
            icon: Icon(Icons.cancel, color: Colors.red.shade600),
          ),
        ],
      ),
    );
  }

  Widget _docRow(int index, ColorScheme scheme) {
    final _DocRow row = _docRows[index];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              key: ValueKey<String>('ft-$index-${row.fileType}'),
              initialValue: _fileTypes.any((DropdownOption o) => o.id == row.fileType)
                  ? row.fileType
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                border: UnderlineInputBorder(),
              ),
              hint: const Text('Select'),
              items: _fileTypes
                  .map(
                    (DropdownOption o) => DropdownMenuItem<String>(
                      value: o.id,
                      child: Text(o.name),
                    ),
                  )
                  .toList(),
              onChanged: (String? v) => setState(() => row.fileType = v),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: row.nameCtrl,
              maxLength: 50,
              decoration: const InputDecoration(
                hintText: 'Name',
                isDense: true,
                border: UnderlineInputBorder(),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: Text(
              row.existingFileName.isEmpty ? '—' : row.existingFileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: scheme.onSurface),
            ),
          ),
          IconButton(
            onPressed: _docRows.length <= 1
                ? null
                : () => setState(() {
                      _docRows.removeAt(index).dispose();
                    }),
            icon: Icon(Icons.cancel, color: Colors.red.shade600),
          ),
        ],
      ),
    );
  }

  Widget _sectionTable({
    required AppPalette palette,
    required ColorScheme scheme,
    required List<String> headers,
    required List<int> headerFlex,
    required List<Widget> rows,
    required VoidCallback onAdd,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: palette.borderSubtle),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: <Widget>[
          Container(
            color: scheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: <Widget>[
                for (int i = 0; i < headers.length; i++)
                  Expanded(
                    flex: headerFlex[i],
                    child: Text(
                      headers[i],
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ...rows,
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onAdd,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.add, color: scheme.onPrimary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 12, color: palette.mutedText)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15)),
        Divider(color: palette.borderSubtle),
      ],
    );
  }

  Widget _text(
    String label,
    TextEditingController ctrl, {
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (String? v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _dropdown(
    String label,
    List<DropdownOption> options,
    String? selected,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) {
    final Set<String> ids = options.map((DropdownOption o) => o.id).toSet();
    return DropdownButtonFormField<String>(
      key: ValueKey<String>('$label-$selected'),
      initialValue: ids.contains(selected) ? selected : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options
          .map(
            (DropdownOption o) => DropdownMenuItem<String>(
              value: o.id,
              child: Text(o.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: required
          ? (String? v) => (v == null || v.isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _dateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onPicked,
  ) {
    return InkWell(
      onTap: () => _pickDate(current: value, onPicked: onPicked),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(value == null ? '' : _fmt(value)),
      ),
    );
  }
}

class _ContractExecRow {
  _ContractExecRow({this.contractId, List<String>? executiveIds})
      : executiveIds = executiveIds ?? <String>[];

  factory _ContractExecRow.fromEntity(StructureFormContractRow e) {
    return _ContractExecRow(
      contractId: e.contractIdFk.isEmpty ? null : e.contractIdFk,
      executiveIds: List<String>.from(e.executiveIds),
    );
  }

  String? contractId;
  final List<String> executiveIds;

  void dispose() {}
}

class _DetailRow {
  _DetailRow({String detail = '', String value = ''})
      : detailCtrl = TextEditingController(text: detail),
        valueCtrl = TextEditingController(text: value);

  factory _DetailRow.fromEntity(StructureFormDetailRow e) {
    return _DetailRow(detail: e.detail, value: e.value);
  }

  final TextEditingController detailCtrl;
  final TextEditingController valueCtrl;

  void dispose() {
    detailCtrl.dispose();
    valueCtrl.dispose();
  }
}

class _DocRow {
  _DocRow({
    this.fileType,
    String name = '',
    this.fileId = '',
    this.existingFileName = '',
  }) : nameCtrl = TextEditingController(text: name);

  factory _DocRow.fromEntity(StructureFormDocumentRow e) {
    return _DocRow(
      fileType: e.fileType.isEmpty ? null : e.fileType,
      name: e.name,
      fileId: e.fileId,
      existingFileName: e.existingFileName,
    );
  }

  String? fileType;
  final TextEditingController nameCtrl;
  final String fileId;
  final String existingFileName;

  void dispose() {
    nameCtrl.dispose();
  }
}
