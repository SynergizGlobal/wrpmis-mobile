import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_global_loader.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/utility_shifting_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/utility_shifting_item.dart';

class UtilityShiftingFormPage extends ConsumerStatefulWidget {
  const UtilityShiftingFormPage({super.key, this.seed});

  static const String routeName = 'utility-shifting-form';
  static const String routePath = '/utility-shifting-form';

  final UtilityShiftingItem? seed;

  @override
  ConsumerState<UtilityShiftingFormPage> createState() =>
      _UtilityShiftingFormPageState();
}

class _ProgressRow {
  _ProgressRow() : work = TextEditingController();

  DateTime? date;
  final TextEditingController work;

  void dispose() => work.dispose();
}

class _AttachmentRow {
  _AttachmentRow() : name = TextEditingController();

  String? fileType;
  final TextEditingController name;
  String? fileName;

  void dispose() => name.dispose();
}

class _UtilityShiftingFormPageState
    extends ConsumerState<UtilityShiftingFormPage> {
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDate = DateFormat('dd-MM-yyyy');

  final TextEditingController _description = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _custodian = TextEditingController();
  final TextEditingController _reference = TextEditingController();
  final TextEditingController _executedBy = TextEditingController();
  final TextEditingController _chainage = TextEditingController();
  final TextEditingController _latitude = TextEditingController();
  final TextEditingController _longitude = TextEditingController();
  final TextEditingController _affected = TextEditingController();
  final TextEditingController _scope = TextEditingController();
  final TextEditingController _completed = TextEditingController();
  final TextEditingController _remarks = TextEditingController();

  final List<_ProgressRow> _progress = <_ProgressRow>[_ProgressRow()];
  final List<_AttachmentRow> _attachments = <_AttachmentRow>[_AttachmentRow()];

  bool _loading = true;
  bool _saving = false;
  String? _recordId;

  String? _projectId;
  String? _agency;
  String? _hod;
  String? _utilityType;
  String? _contractId;
  String? _stage;
  String? _element;
  String? _unit;
  String? _status;
  DateTime? _identificationDate;
  DateTime? _targetDate;
  DateTime? _startDate;
  DateTime? _completionDate;

  List<DropdownOption> _projects = const <DropdownOption>[];
  List<DropdownOption> _agencies = const <DropdownOption>[];
  List<DropdownOption> _hods = const <DropdownOption>[];
  List<DropdownOption> _types = const <DropdownOption>[];
  List<DropdownOption> _contracts = const <DropdownOption>[];
  List<DropdownOption> _stages = const <DropdownOption>[];
  List<DropdownOption> _elements = const <DropdownOption>[];
  List<DropdownOption> _units = const <DropdownOption>[];
  List<DropdownOption> _statuses = const <DropdownOption>[];
  List<DropdownOption> _fileTypes = const <DropdownOption>[];

  bool get _isEdit =>
      widget.seed != null &&
      ((widget.seed!.utilityShiftingId ?? '').isNotEmpty ||
          widget.seed!.id.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _description.dispose();
    _location.dispose();
    _custodian.dispose();
    _reference.dispose();
    _executedBy.dispose();
    _chainage.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _affected.dispose();
    _scope.dispose();
    _completed.dispose();
    _remarks.dispose();
    for (final _ProgressRow row in _progress) {
      row.dispose();
    }
    for (final _AttachmentRow row in _attachments) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(utilityShiftingRepositoryProvider);
    final options = await repo.getAddFormOptions();
    if (!mounted) {
      return;
    }
    options.fold((failure) {}, (Map<String, List<DropdownOption>> map) {
      _projects = _list(map, const <String>['project_id_fk', 'project']);
      _agencies = _list(map, const <String>[
        'execution_agency_fk',
        'executionAgency',
      ]);
      _hods = _list(map, const <String>['hod_user_id_fk', 'hod']);
      _types = _list(map, const <String>['utility_type_fk']);
      _units = _list(map, const <String>['unit_fk', 'unit']);
      _statuses = _list(map, const <String>['shifting_status_fk', 'status']);
      _fileTypes = _list(map, const <String>[
        'utility_shifting_file_type',
        'file_type',
        'fileType',
      ]);
    });
    if (_statuses.isEmpty) {
      _statuses = const <DropdownOption>[
        DropdownOption(id: 'Not Started', name: 'Not Started'),
        DropdownOption(id: 'In Progress', name: 'In Progress'),
        DropdownOption(id: 'Completed', name: 'Completed'),
      ];
    }
    if (!_isEdit) {
      _status = 'Not Started';
    } else {
      _apply(widget.seed!);
      final UtilityShiftingItem seed = widget.seed!;
      final detail = await repo.getDetail(
        id: seed.id,
        utilityShiftingId: seed.utilityShiftingId ?? '',
      );
      if (!mounted) {
        return;
      }
      detail.fold((_) {}, (UtilityShiftingItem? item) {
        if (item != null) {
          _apply(item);
        }
      });
      if ((_projectId ?? '').isNotEmpty) {
        await _loadContracts(_projectId!, keepSelection: true);
      }
      if ((_contractId ?? '').isNotEmpty) {
        await _loadStages(_contractId!, keepSelection: true);
      }
      if ((_stage ?? '').isNotEmpty) {
        await _loadElements(_stage!, keepSelection: true);
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  List<DropdownOption> _list(
    Map<String, List<DropdownOption>> map,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final List<DropdownOption>? items = map[key];
      if (items != null && items.isNotEmpty) {
        return items;
      }
    }
    return const <DropdownOption>[];
  }

  void _apply(UtilityShiftingItem item) {
    _recordId = item.id;
    _projectId = item.projectId;
    _agency = item.executionAgency;
    _hod = (item.hodUserId ?? '').isNotEmpty ? item.hodUserId : item.hod;
    _utilityType = item.utilityType;
    _contractId = item.impactedContractId;
    _stage = item.requirementStage;
    _element = item.impactedElement;
    _unit = item.unit;
    _status = item.status ?? _status;
    _description.text = item.description ?? '';
    _location.text = item.locationName ?? '';
    _custodian.text = item.custodian ?? '';
    _reference.text = item.referenceNumber ?? '';
    _executedBy.text = item.executedBy ?? '';
    _chainage.text = item.chainage ?? '';
    _latitude.text = item.latitude ?? '';
    _longitude.text = item.longitude ?? '';
    _affected.text = item.affectedStructures ?? '';
    _scope.text = item.scope ?? '';
    _completed.text = item.completed ?? '';
    _remarks.text = item.remarks ?? '';
    _identificationDate = _parseDate(item.identification);
    _targetDate = _parseDate(item.targetDate);
    _startDate = _parseDate(item.startDate);
    _completionDate = _parseDate(item.completionDate);
    _projects = _ensure(_projects, _projectId, _projectId);
    _agencies = _ensure(_agencies, _agency, _agency);
    _hods = _ensure(_hods, _hod, item.hod ?? _hod);
    _types = _ensure(_types, _utilityType, _utilityType);
    _units = _ensure(_units, _unit, _unit);
    _statuses = _ensure(_statuses, _status, _status);
    _contracts = _ensure(_contracts, _contractId, _contractId);
    _stages = _ensure(_stages, _stage, _stage);
    _elements = _ensure(_elements, _element, _element);
  }

  DateTime? _parseDate(String? raw) {
    final String text = raw?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    for (final DateFormat format in <DateFormat>[_apiDate, _displayDate]) {
      try {
        return format.parseStrict(text);
      } catch (_) {}
    }
    return DateTime.tryParse(text);
  }

  String _format(DateTime? date) => date == null ? '' : _apiDate.format(date);

  List<DropdownOption> _ensure(
    List<DropdownOption> items,
    String? id,
    String? label,
  ) {
    final String value = id?.trim() ?? '';
    if (value.isEmpty || items.any((DropdownOption e) => e.id == value)) {
      return items;
    }
    return <DropdownOption>[
      DropdownOption(id: value, name: (label ?? value).trim()),
      ...items,
    ];
  }

  Future<void> _loadContracts(
    String projectId, {
    bool keepSelection = false,
  }) async {
    final result = await ref
        .read(utilityShiftingRepositoryProvider)
        .getImpactedContracts(projectId);
    if (!mounted) {
      return;
    }
    result.fold((_) {}, (List<DropdownOption> items) {
      setState(() {
        _contracts = _ensure(items, keepSelection ? _contractId : null, _contractId);
        if (!keepSelection) {
          _contractId = null;
          _stage = null;
          _element = null;
          _stages = const <DropdownOption>[];
          _elements = const <DropdownOption>[];
        }
      });
    });
  }

  Future<void> _loadStages(
    String contractId, {
    bool keepSelection = false,
  }) async {
    final result = await ref
        .read(utilityShiftingRepositoryProvider)
        .getRequirementStages(contractId);
    if (!mounted) {
      return;
    }
    result.fold((_) {}, (List<DropdownOption> items) {
      setState(() {
        _stages = _ensure(items, keepSelection ? _stage : null, _stage);
        if (!keepSelection) {
          _stage = null;
          _element = null;
          _elements = const <DropdownOption>[];
        }
      });
    });
  }

  Future<void> _loadElements(
    String stage, {
    bool keepSelection = false,
  }) async {
    final result = await ref
        .read(utilityShiftingRepositoryProvider)
        .getImpactedElements(
          contractId: _contractId ?? '',
          stage: stage,
        );
    if (!mounted) {
      return;
    }
    result.fold((_) {}, (List<DropdownOption> items) {
      setState(() {
        _elements = _ensure(items, keepSelection ? _element : null, _element);
        if (!keepSelection) {
          _element = null;
        }
      });
    });
  }

  Future<void> _pickDate(ValueChanged<DateTime?> onPicked, DateTime? current) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _pickFile(_AttachmentRow row) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    setState(() => row.fileName = result.files.first.name);
  }

  Future<void> _save() async {
    if ((_agency ?? '').isEmpty ||
        (_hod ?? '').isEmpty ||
        (_utilityType ?? '').isEmpty ||
        _description.text.trim().isEmpty ||
        (_contractId ?? '').isEmpty ||
        (_stage ?? '').isEmpty) {
      await GlobalDialog.error(
        'Fill the required fields: Execution Agency, HOD, Utility Type, Utility Description, Impacted Contract and Requirement stage.',
        title: 'Missing details',
      );
      return;
    }
    setState(() => _saving = true);
    final Map<String, dynamic> fields = <String, dynamic>{
      'id': _recordId ?? '',
      'utility_shifting_id': widget.seed?.utilityShiftingId ?? '',
      'project_id_fk': _projectId ?? '',
      'execution_agency_fk': _agency ?? '',
      'hod_user_id_fk': _hod ?? '',
      'utility_type_fk': _utilityType ?? '',
      'utility_description': _description.text.trim(),
      'location_name': _location.text.trim(),
      'custodian': _custodian.text.trim(),
      'identification': _format(_identificationDate),
      'reference_number': _reference.text.trim(),
      'executed_by': _executedBy.text.trim(),
      'chainage': _chainage.text.trim(),
      'latitude': _latitude.text.trim(),
      'longitude': _longitude.text.trim(),
      'impacted_contract_id_fk': _contractId ?? '',
      'requirement_stage_fk': _stage ?? '',
      'impacted_element': _element ?? '',
      'affected_structures': _affected.text.trim(),
      'planned_completion_date': _format(_targetDate),
      'scope': _scope.text.trim(),
      'completed': _completed.text.trim(),
      'unit_fk': _unit ?? '',
      'start_date': _format(_startDate),
      'shifting_status_fk': _status ?? '',
      'shifting_completion_date': _format(_completionDate),
      'remarks': _remarks.text.trim(),
      'progress_dates': _progress
          .map((_ProgressRow row) => _format(row.date))
          .where((String value) => value.isNotEmpty)
          .toList(),
      'progress_of_works': _progress
          .map((_ProgressRow row) => row.work.text.trim())
          .where((String value) => value.isNotEmpty)
          .toList(),
    };
    final result =
        await ref.read(utilityShiftingRepositoryProvider).save(fields);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    await result.fold(
      (failure) => GlobalDialog.error(failure.message, title: 'Save failed'),
      (String message) async {
        await GlobalDialog.success(message, title: _isEdit ? 'Updated' : 'Added');
        if (mounted) {
          context.pop(true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? code = widget.seed?.utilityShiftingId;
    final String title = _isEdit
        ? 'Update${(code ?? '').isEmpty ? '' : ' ($code)'}'
        : 'Add Utility Shifting';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: <Widget>[
                    _pair(
                      _drop(
                        label: 'Project',
                        title: 'Select Project',
                        items: _projects,
                        value: _projectId,
                        onChanged: (String? id) {
                          setState(() => _projectId = id);
                          if (id != null && id.isNotEmpty) {
                            _loadContracts(id);
                          }
                        },
                      ),
                      _drop(
                        label: 'Execution Agency *',
                        title: 'Select Execution Agency',
                        items: _agencies,
                        value: _agency,
                        onChanged: (String? id) => setState(() => _agency = id),
                      ),
                    ),
                    _pair(
                      _drop(
                        label: 'HOD *',
                        title: 'Select HOD',
                        items: _hods,
                        value: _hod,
                        onChanged: (String? id) => setState(() => _hod = id),
                      ),
                      _drop(
                        label: 'Utility Type *',
                        title: 'Select Utility Type',
                        items: _types,
                        value: _utilityType,
                        onChanged: (String? id) =>
                            setState(() => _utilityType = id),
                      ),
                    ),
                    _field(
                      _text(
                        _description,
                        label: 'Utility Description *',
                      ),
                    ),
                    _pair(
                      _text(_location, label: 'Location Name'),
                      _text(_custodian, label: 'Custodian'),
                    ),
                    _pair(
                      _date(
                        'Identification Date',
                        _identificationDate,
                        (DateTime? value) =>
                            setState(() => _identificationDate = value),
                      ),
                      _text(_reference, label: 'Reference Number'),
                    ),
                    _pair(
                      _text(_executedBy, label: 'Executed by'),
                      _text(_chainage, label: 'Chainage'),
                    ),
                    _pair(
                      _text(_latitude, label: 'Latitude'),
                      _text(_longitude, label: 'Longitude'),
                    ),
                    _field(
                      _drop(
                        label: 'Impacted Contract *',
                        title: 'Select Impacted Contract',
                        items: _contracts,
                        value: _contractId,
                        onChanged: (String? id) {
                          setState(() => _contractId = id);
                          if (id != null && id.isNotEmpty) {
                            _loadStages(id);
                          }
                        },
                      ),
                    ),
                    _pair(
                      _drop(
                        label: 'Requirement stage *',
                        title: 'Select Requirement Stage',
                        items: _stages,
                        value: _stage,
                        onChanged: (String? id) {
                          setState(() => _stage = id);
                          if (id != null && id.isNotEmpty) {
                            _loadElements(id);
                          }
                        },
                      ),
                      _drop(
                        label: 'Impacted Element',
                        title: 'Select Impacted Element',
                        items: _elements,
                        value: _element,
                        onChanged: (String? id) => setState(() => _element = id),
                      ),
                    ),
                    _pair(
                      _text(_affected, label: 'Affected Structures'),
                      _date(
                        'Target Date',
                        _targetDate,
                        (DateTime? value) => setState(() => _targetDate = value),
                      ),
                    ),
                    _pair(
                      _text(_scope, label: 'Scope'),
                      _text(_completed, label: 'Completed'),
                    ),
                    _pair(
                      _drop(
                        label: 'Unit',
                        title: 'Select Unit',
                        items: _units,
                        value: _unit,
                        onChanged: (String? id) => setState(() => _unit = id),
                      ),
                      _date(
                        'Start Date',
                        _startDate,
                        (DateTime? value) => setState(() => _startDate = value),
                      ),
                    ),
                    _pair(
                      _drop(
                        label: 'Status',
                        title: 'Select Status',
                        items: _statuses,
                        value: _status,
                        onChanged: (String? id) => setState(() => _status = id),
                      ),
                      _date(
                        'Completion Date',
                        _completionDate,
                        (DateTime? value) =>
                            setState(() => _completionDate = value),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _sectionCard(
                      title: 'Progress Details',
                      headers: const <String>['Progress Date', 'Progress of Work'],
                      onAdd: () => setState(() => _progress.add(_ProgressRow())),
                      rows: <Widget>[
                        for (int i = 0; i < _progress.length; i++)
                          _progressRow(i, scheme),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      title: 'Attachments',
                      headers: const <String>['File Type', 'Name'],
                      onAdd: () =>
                          setState(() => _attachments.add(_AttachmentRow())),
                      rows: <Widget>[
                        for (int i = 0; i < _attachments.length; i++)
                          _attachmentRow(i, scheme),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _field(
                      _text(_remarks, label: 'Remarks', maxLines: 3),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: Text(_isEdit ? 'UPDATE' : 'ADD'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text('CANCEL'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_loading || _saving) const AppGlobalLoader(),
        ],
      ),
    );
  }

  Widget _pair(Widget left, Widget right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _field(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: child,
    );
  }

  Widget _sectionCard({
    required String title,
    required List<String> headers,
    required List<Widget> rows,
    required VoidCallback onAdd,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  color: scheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: <Widget>[
                      for (int i = 0; i < headers.length; i++)
                        Expanded(
                          flex: i == 0 ? 1 : 2,
                          child: Text(
                            headers[i],
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                for (int i = 0; i < rows.length; i++) ...<Widget>[
                  if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
                    child: rows[i],
                  ),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: IconButton.filled(
                      tooltip: 'Add row',
                      visualDensity: VisualDensity.compact,
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressRow(int index, ColorScheme scheme) {
    final _ProgressRow row = _progress[index];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _dateBox(
            row.date,
            (DateTime? value) => setState(() => row.date = value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _boxField(row.work, hint: 'Progress of work'),
        ),
        _removeButton(
          enabled: _progress.length > 1,
          onPressed: () => setState(() => _progress.removeAt(index).dispose()),
          color: scheme.error,
        ),
      ],
    );
  }

  Widget _attachmentRow(int index, ColorScheme scheme) {
    final _AttachmentRow row = _attachments[index];
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _dropBox(
                title: 'Select File Type',
                items: _fileTypes,
                value: row.fileType,
                onChanged: (String? id) => setState(() => row.fileType = id),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _boxField(row.name, hint: 'Name'),
            ),
            _removeButton(
              enabled: _attachments.length > 1,
              onPressed: () =>
                  setState(() => _attachments.removeAt(index).dispose()),
              color: scheme.error,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(right: 40),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickFile(row),
              icon: const Icon(Icons.attach_file_rounded, size: 18),
              label: Text(
                row.fileName ?? 'Attach file',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _removeButton({
    required bool enabled,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: 40,
      height: 48,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: enabled ? onPressed : null,
        icon: Icon(Icons.close_rounded, color: enabled ? color : null),
      ),
    );
  }

  Widget _text(
    TextEditingController controller, {
    String? label,
    String? hint,
    int maxLines = 1,
  }) {
    final Widget field = _boxField(controller, hint: hint, maxLines: maxLines);
    if (label == null) {
      return field;
    }
    return _labeled(label, field);
  }

  Widget _boxField(
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: _boxDecoration(hint: hint),
    );
  }

  Widget _drop({
    required String label,
    required String title,
    required List<DropdownOption> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return _labeled(
      label,
      _dropBox(
        title: title,
        items: items,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropBox({
    required String title,
    required List<DropdownOption> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final List<DropdownOption> options = <DropdownOption>[
      const DropdownOption(id: '', name: 'Select'),
      ..._ensure(items, value, value),
    ];
    return AppSelectSheetField<String>(
      label: '',
      title: title,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      items: options.map((DropdownOption e) => e.id).toList(),
      value: value,
      itemLabelBuilder: (String id) {
        if (id.isEmpty) {
          return 'Select';
        }
        return options
            .firstWhere(
              (DropdownOption e) => e.id == id,
              orElse: () => DropdownOption(id: id, name: id),
            )
            .name;
      },
      onChanged: (String id) => onChanged(id.isEmpty ? null : id),
    );
  }

  Widget _date(String label, DateTime? value, ValueChanged<DateTime?> onChanged) {
    return _labeled(label, _dateBox(value, onChanged));
  }

  Widget _dateBox(DateTime? value, ValueChanged<DateTime?> onChanged) {
    return InkWell(
      onTap: () => _pickDate(onChanged, value),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _boxDecoration(
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null ? 'Select' : _displayDate.format(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: value == null
                ? Theme.of(context).hintColor
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 34,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _boxDecoration({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      isDense: true,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
