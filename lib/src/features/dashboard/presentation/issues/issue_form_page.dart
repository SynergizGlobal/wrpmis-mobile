import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_global_loader.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/issue_form_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/issue_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/issues/providers/issue_form_providers.dart';

/// Add / Update Issue. Save APIs later.
class IssueFormPage extends ConsumerStatefulWidget {
  const IssueFormPage({super.key, this.issueId, this.seed});

  static const String routeName = 'issue-form';
  static const String routePath = '/issue-form';

  final String? issueId;
  final IssueListItem? seed;

  @override
  ConsumerState<IssueFormPage> createState() => _IssueFormPageState();
}

class _DocRow {
  _DocRow() : name = TextEditingController();

  String? fileType;
  final TextEditingController name;

  void dispose() => name.dispose();
}

class _IssueFormPageState extends ConsumerState<IssueFormPage> {
  static final DateFormat _displayDate = DateFormat('dd-MM-yyyy');
  static const double _labelSlotHeight = 40;
  static const EdgeInsets _controlPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 14,
  );

  final TextEditingController _description = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _personName = TextEditingController();
  final TextEditingController _personDesignation = TextEditingController();
  final TextEditingController _reportedBy = TextEditingController();
  final TextEditingController _remarks = TextEditingController();
  final List<_DocRow> _docRows = <_DocRow>[_DocRow()];

  bool _prefilled = false;
  String? _projectId;
  String? _projectLabel;
  String? _contractId;
  String? _contractLabel;
  String? _contractType;
  String? _structure;
  String? _component;
  String? _category;
  String? _shortDescription;
  String? _priority;
  String? _organization;
  String? _status;
  String? _laId;
  DateTime? _deadline;
  List<IssueHistoryRow> _history = const <IssueHistoryRow>[];

  bool get _isEdit => widget.issueId != null && widget.issueId!.isNotEmpty;

  IssueFormArgs get _args => IssueFormArgs(
        issueId: widget.issueId,
        seed: widget.seed,
      );

  @override
  void dispose() {
    _description.dispose();
    _location.dispose();
    _personName.dispose();
    _personDesignation.dispose();
    _reportedBy.dispose();
    _remarks.dispose();
    for (final _DocRow row in _docRows) {
      row.dispose();
    }
    super.dispose();
  }

  DateTime? _parseDate(String? raw) {
    final String text = (raw ?? '').trim();
    if (text.isEmpty) {
      return null;
    }
    for (final DateFormat format in <DateFormat>[
      DateFormat('dd-MM-yyyy'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('dd-MMM-yyyy'),
    ]) {
      try {
        return format.parseStrict(text);
      } catch (_) {}
    }
    return DateTime.tryParse(text);
  }

  void _prefill(IssueFormDetail detail) {
    _prefilled = true;
    _projectId = detail.projectId;
    _projectLabel = detail.projectLabel;
    _contractId = detail.contractId;
    _contractLabel = detail.contractLabel;
    _contractType = detail.contractType;
    _structure = detail.structure;
    _component = detail.component;
    _category = detail.category;
    _shortDescription = detail.shortDescription;
    _priority = detail.priority;
    _organization = detail.responsibleOrganization;
    _status = detail.status;
    _deadline = _parseDate(detail.deadline);
    _description.text = detail.description ?? '';
    _location.text = detail.location ?? '';
    _personName.text = detail.responsiblePersonName ?? '';
    _personDesignation.text = detail.responsiblePersonDesignation ?? '';
    _reportedBy.text = detail.reportedBy ?? '';
    _remarks.text = detail.remarks ?? '';
    _history = detail.history;
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  void _comingSoon(String action) {
    GlobalDialog.info(
      '$action will be connected when the API is available.',
      title: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<IssueFormDetail> async = ref.watch(issueFormProvider(_args));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'Update Issue (Issue Id : ${widget.issueId})'
              : 'Add Issue',
        ),
      ),
      body: async.when(
        loading: () => const Stack(children: <Widget>[AppGlobalLoader()]),
        error: (Object e, StackTrace _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () => ref.invalidate(issueFormProvider(_args)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (IssueFormDetail detail) {
          if (!_prefilled) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_prefilled) {
                setState(() => _prefill(detail));
              }
            });
          }
          return _body(detail);
        },
      ),
    );
  }

  Widget _body(IssueFormDetail detail) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AsyncValue<List<DropdownOption>> contractsAsync =
        ref.watch(issueFormContractsProvider(_projectId ?? ''));
    final AsyncValue<List<DropdownOption>> categoriesAsync =
        ref.watch(issueFormCategoriesProvider(_contractType ?? ''));
    final AsyncValue<List<DropdownOption>> titlesAsync =
        ref.watch(issueFormTitlesProvider(_category ?? ''));
    final AsyncValue<List<DropdownOption>> structuresAsync =
        ref.watch(issueFormStructuresProvider(_contractId ?? ''));
    final AsyncValue<List<DropdownOption>> componentsAsync =
        ref.watch(
      issueFormComponentsProvider(
        IssueComponentQuery(
          contractId: _contractId ?? '',
          structure: _structure ?? '',
        ),
      ),
    );
    final AsyncValue<List<DropdownOption>> statusesAsync =
        ref.watch(issueFormStatusesProvider);
    final AsyncValue<List<DropdownOption>> responsibleAsync =
        ref.watch(issueFormResponsibleProvider(''));
    final AsyncValue<List<DropdownOption>> laAsync =
        ref.watch(issueFormLaDetailsProvider);
    final bool loading = contractsAsync.isLoading ||
        categoriesAsync.isLoading ||
        titlesAsync.isLoading ||
        structuresAsync.isLoading ||
        componentsAsync.isLoading ||
        statusesAsync.isLoading ||
        responsibleAsync.isLoading;

    final List<DropdownOption> contractOptions =
        List<DropdownOption>.from(contractsAsync.valueOrNull ?? const []);
    if (_contractId != null &&
        _contractId!.isNotEmpty &&
        !contractOptions.any((DropdownOption e) => e.id == _contractId)) {
      contractOptions.insert(
        0,
        DropdownOption(
          id: _contractId!,
          name: _contractLabel ?? _contractId!,
          extra: _contractType,
        ),
      );
    }

    final bool showLa = (_category ?? '').toLowerCase().contains('land');
    final List<DropdownOption> laOptions =
        laAsync.valueOrNull ?? const <DropdownOption>[];

    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: <Widget>[
                  _grid(<Widget>[
                    if (_isEdit)
                      _readOnly('Project', _projectLabel ?? _projectId ?? '—')
                    else
                      _dropdown(
                        'Project *',
                        detail.projects,
                        _projectId,
                        (String? v) => setState(() {
                          _projectId = v;
                          _projectLabel = detail.projects
                              .where((DropdownOption e) => e.id == v)
                              .map((DropdownOption e) => e.name)
                              .firstOrNull;
                          _contractId = null;
                          _contractLabel = null;
                          _contractType = null;
                          _structure = null;
                          _component = null;
                        }),
                      ),
                    if (_isEdit)
                      _readOnly(
                        'Contract *',
                        _contractLabel ?? _contractId ?? '—',
                      )
                    else
                      _asyncDropdown(
                        'Contract *',
                        contractsAsync,
                        _contractId,
                        (String? v) {
                          final DropdownOption? selected = contractOptions
                              .where((DropdownOption e) => e.id == v)
                              .firstOrNull;
                          setState(() {
                            _contractId = v;
                            _contractLabel = selected?.name;
                            _contractType = selected?.extra;
                            _structure = null;
                            _component = null;
                            _category = null;
                            _shortDescription = null;
                          });
                        },
                        enabled: _projectId != null,
                        fallback: contractOptions,
                      ),
                  ]),
                  const SizedBox(height: 10),
                  _grid(<Widget>[
                    _asyncDropdown(
                      'Structure',
                      structuresAsync,
                      _structure,
                      (String? v) => setState(() {
                        _structure = v;
                        _component = null;
                      }),
                      enabled: _contractId != null,
                    ),
                    _asyncDropdown(
                      'Component',
                      componentsAsync,
                      _component,
                      (String? v) => setState(() => _component = v),
                      enabled: _contractId != null,
                    ),
                  ]),
                  const SizedBox(height: 10),
                  _grid(<Widget>[
                    _asyncDropdown(
                      'Issue Category *',
                      categoriesAsync,
                      _category,
                      (String? v) => setState(() {
                        _category = v;
                        _shortDescription = null;
                        _laId = null;
                      }),
                    ),
                    _asyncDropdown(
                      'Short Description *',
                      titlesAsync,
                      _shortDescription,
                      (String? v) => setState(() => _shortDescription = v),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  _dropdown(
                    'Issue Priority *',
                    detail.priorities.isEmpty
                        ? IssueFormDetail.fallbackPriorities
                        : detail.priorities,
                    _priority,
                    (String? v) => setState(() => _priority = v),
                  ),
                  if (showLa && laOptions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    _dropdown(
                      'LA Details',
                      laOptions,
                      _laId,
                      (String? v) => setState(() => _laId = v),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _text('Description of Issue', _description, maxLines: 3),
                  if (_isEdit && _history.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    _historyCard(scheme),
                  ],
                  const SizedBox(height: 10),
                  _grid(<Widget>[
                    _date('Deadline for Issue Resolution', _deadline),
                    _text('Location/Station/KM', _location),
                  ]),
                  const SizedBox(height: 10),
                  _dropdown(
                    'Responsible Organization (Pending with) *',
                    detail.organizations.isEmpty
                        ? IssueFormDetail.fallbackOrganizations
                        : detail.organizations,
                    _organization,
                    (String? v) => setState(() => _organization = v),
                  ),
                  const SizedBox(height: 10),
                  _asyncDropdown(
                    'Select Responsible Person',
                    responsibleAsync,
                    null,
                    (String? v) {
                      final DropdownOption? selected =
                          (responsibleAsync.valueOrNull ??
                                  const <DropdownOption>[])
                              .where((DropdownOption e) => e.id == v)
                              .firstOrNull;
                      if (selected == null) {
                        return;
                      }
                      setState(() {
                        _personName.text = selected.name.split(' - ').first;
                        _personDesignation.text = selected.extra ??
                            (selected.name.contains(' - ')
                                ? selected.name.split(' - ').last
                                : '');
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _grid(<Widget>[
                    _text('Responsible Person Name', _personName),
                    _text('Responsible Person Designation', _personDesignation),
                  ]),
                  const SizedBox(height: 10),
                  _grid(<Widget>[
                    _text('Reported by', _reportedBy),
                    _asyncDropdown(
                      'Issue Status *',
                      statusesAsync,
                      _status,
                      (String? v) => setState(() => _status = v),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  _text('Action Taken/Remarks', _remarks, maxLines: 3),
                  const SizedBox(height: 16),
                  _sectionTitle('Attachments'),
                  for (int i = 0; i < _docRows.length; i++) ...<Widget>[
                    _docCard(i, detail, scheme),
                    const SizedBox(height: 8),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filledTonal(
                      onPressed: () => setState(() => _docRows.add(_DocRow())),
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            _comingSoon(_isEdit ? 'Update' : 'Add'),
                        child: Text(_isEdit ? 'UPDATE' : 'ADD'),
                      ),
                    ),
                    const SizedBox(width: 8),
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
        if (loading) const AppGlobalLoader(),
      ],
    );
  }

  Widget _historyCard(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Container(
            color: scheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: const <Widget>[
                Expanded(
                  child: Text(
                    'Updated By',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Update Date',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Action Taken/Remarks',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final IssueHistoryRow row in _history)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: Text(row.updatedBy ?? '—')),
                  Expanded(child: Text(row.updateDate ?? '—')),
                  Expanded(flex: 2, child: Text(row.remarks ?? '—')),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _docCard(int index, IssueFormDetail detail, ColorScheme scheme) {
    final _DocRow row = _docRows[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            _dropdown(
              'File Type',
              detail.fileTypes.isEmpty
                  ? IssueFormDetail.fallbackFileTypes
                  : detail.fileTypes,
              row.fileType,
              (String? v) => setState(() => row.fileType = v),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _comingSoon('Attach File'),
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Attach File'),
                  ),
                ),
                IconButton(
                  onPressed: _docRows.length == 1
                      ? null
                      : () {
                          setState(() {
                            _docRows.removeAt(index).dispose();
                          });
                        },
                  icon: Icon(Icons.close, color: scheme.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<Widget> children) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      if (i > 0) {
        rows.add(const SizedBox(height: 10));
      }
      if (i + 1 < children.length) {
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: children[i]),
              const SizedBox(width: 8),
              Expanded(child: children[i + 1]),
            ],
          ),
        );
      } else {
        rows.add(children[i]);
      }
    }
    return Column(children: rows);
  }

  TextStyle? get _fieldLabelStyle =>
      Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          );

  InputDecoration _controlDecoration({
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      filled: true,
      enabled: enabled,
      isDense: true,
      contentPadding: _controlPadding,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _labeled(String label, Widget control) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: _labelSlotHeight,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 6),
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _fieldLabelStyle,
              ),
            ),
          ),
        ),
        control,
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _readOnly(String label, String value) {
    return _labeled(
      label,
      InputDecorator(
        decoration: _controlDecoration(enabled: false),
        child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _text(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return _labeled(
      label,
      TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: _controlDecoration(),
      ),
    );
  }

  Widget _date(String label, DateTime? value) {
    return _labeled(
      label,
      InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: _controlDecoration(
            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
          ),
          child: Text(
            value == null ? '' : _displayDate.format(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<DropdownOption> options,
    String? value,
    ValueChanged<String?> onChanged, {
    bool enabled = true,
  }) {
    final List<DropdownOption> items = <DropdownOption>[
      const DropdownOption(id: '', name: 'Select'),
      ...options,
    ];
    if (value != null &&
        value.isNotEmpty &&
        !items.any((DropdownOption e) => e.id == value)) {
      items.add(DropdownOption(id: value, name: value));
    }
    return _labeled(
      label,
      AppSelectSheetField<String>(
        label: '',
        title: label,
        enabled: enabled,
        isDense: true,
        contentPadding: _controlPadding,
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
      ),
    );
  }

  Widget _asyncDropdown(
    String label,
    AsyncValue<List<DropdownOption>> async,
    String? value,
    ValueChanged<String?> onChanged, {
    bool enabled = true,
    List<DropdownOption>? fallback,
  }) {
    if (async.hasError) {
      return Text(
        'Unable to load $label',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
        ),
      );
    }
    return _dropdown(
      label,
      fallback ?? async.valueOrNull ?? const <DropdownOption>[],
      value,
      onChanged,
      enabled: enabled,
    );
  }
}
