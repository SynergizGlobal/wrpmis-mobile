import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_global_loader.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contract_form_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/contracts/providers/contract_form_providers.dart';

/// Add / Update Contract (same fields). Save APIs later.
class ContractFormPage extends ConsumerStatefulWidget {
  const ContractFormPage({super.key, this.contractId});

  static const String routeName = 'contract-form';
  static const String routePath = '/contract-form';

  final String? contractId;

  @override
  ConsumerState<ContractFormPage> createState() => _ContractFormPageState();
}

class _ExecRow {
  _ExecRow({this.departmentId, List<String>? executiveIds})
      : executiveIds = executiveIds ?? <String>[];

  String? departmentId;
  List<String> executiveIds;
}

class _RevRow {
  _RevRow()
      : revisionNo = TextEditingController(text: 'R1'),
        estimatedCost = TextEditingController(),
        remarks = TextEditingController();

  final TextEditingController revisionNo;
  final TextEditingController estimatedCost;
  final TextEditingController remarks;
  DateTime? plannedAward;
  DateTime? plannedCompletion;
  DateTime? nit;
  DateTime? tenderOpening;
  DateTime? techApproval;
  DateTime? finApproval;

  void dispose() {
    revisionNo.dispose();
    estimatedCost.dispose();
    remarks.dispose();
  }
}

class _DocRow {
  _DocRow() : name = TextEditingController();

  String? fileType;
  final TextEditingController name;

  void dispose() => name.dispose();
}

class _ContractFormPageState extends ConsumerState<ContractFormPage> {
  static final DateFormat _displayDate = DateFormat('dd-MM-yyyy');

  final TextEditingController _shortName = TextEditingController();
  final TextEditingController _contractName = TextEditingController();
  final TextEditingController _contractCode = TextEditingController();
  final TextEditingController _scope = TextEditingController();
  final TextEditingController _loaNo = TextEditingController();
  final TextEditingController _caNo = TextEditingController();
  final TextEditingController _awardedCost = TextEditingController();
  final TextEditingController _estimatedCost = TextEditingController();
  final TextEditingController _gstRate = TextEditingController();

  bool _prefilled = false;
  String? _projectId;
  String? _projectLabel;
  String? _hodUserId;
  String? _dyHodUserId;
  String? _department;
  String _bankFunded = 'No';
  String _awarded = 'No';
  String? _contractType;
  String? _contractorId;
  String? _awardedCostUnit;
  String? _estimatedCostUnit;
  String? _workStatus;
  String _bgRequired = 'No';
  String _insuranceRequired = 'No';
  String _milestoneRequired = 'No';
  String _revisionRequired = 'No';
  String _keyPersonnelRequired = 'No';
  String? _gstInclusive;

  DateTime? _loaDate;
  DateTime? _caDate;
  DateTime? _dateOfStart;
  DateTime? _originalDoc;
  DateTime? _targetDoc;
  DateTime? _plannedAward;
  DateTime? _plannedCompletion;
  DateTime? _nit;
  DateTime? _tenderOpening;
  DateTime? _techSubmission;
  DateTime? _finSubmission;

  final List<_ExecRow> _execRows = <_ExecRow>[_ExecRow()];
  final List<_RevRow> _revRows = <_RevRow>[_RevRow()];
  final List<_DocRow> _docRows = <_DocRow>[_DocRow()];

  bool get _isEdit =>
      widget.contractId != null && widget.contractId!.isNotEmpty;

  @override
  void dispose() {
    _shortName.dispose();
    _contractName.dispose();
    _contractCode.dispose();
    _scope.dispose();
    _loaNo.dispose();
    _caNo.dispose();
    _awardedCost.dispose();
    _estimatedCost.dispose();
    _gstRate.dispose();
    for (final _RevRow row in _revRows) {
      row.dispose();
    }
    for (final _DocRow row in _docRows) {
      row.dispose();
    }
    super.dispose();
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    for (final String pattern in <String>['dd-MM-yyyy', 'dd/MM/yyyy']) {
      try {
        return DateFormat(pattern).parseStrict(raw.trim());
      } catch (_) {}
    }
    return DateTime.tryParse(raw);
  }

  void _prefill(ContractFormDetail detail) {
    _prefilled = true;
    _projectId = detail.projectId;
    _projectLabel = detail.projectLabel;
    _hodUserId = detail.hodUserId;
    _dyHodUserId = detail.dyHodUserId;
    _department = detail.contractDepartment;
    _bankFunded = detail.bankFunded ?? 'No';
    _awarded = detail.awarded ?? 'No';
    _shortName.text = detail.shortName ?? '';
    _contractName.text = detail.contractName ?? '';
    _contractType = detail.contractType;
    _contractorId = detail.contractorId;
    _contractCode.text = detail.contractCode ?? '';
    _scope.text = detail.scope ?? '';
    _loaNo.text = detail.loaLetterNumber ?? '';
    _loaDate = _parseDate(detail.loaDate);
    _caNo.text = detail.caNo ?? '';
    _caDate = _parseDate(detail.caDate);
    _dateOfStart = _parseDate(detail.dateOfStart);
    _originalDoc = _parseDate(detail.originalDoc);
    _targetDoc = _parseDate(detail.targetDoc);
    _awardedCost.text = detail.awardedCost ?? '';
    _awardedCostUnit = detail.awardedCostUnit;
    _estimatedCost.text = detail.estimatedCost ?? '';
    _estimatedCostUnit = detail.estimatedCostUnit;
    _workStatus = detail.workStatus;
    _plannedAward = _parseDate(detail.plannedDateOfAward);
    _plannedCompletion = _parseDate(detail.plannedDateOfCompletion);
    _nit = _parseDate(detail.noticeInvitingTender);
    _tenderOpening = _parseDate(detail.tenderOpeningDate);
    _techSubmission = _parseDate(detail.technicalEvalSubmission);
    _finSubmission = _parseDate(detail.financialEvalSubmission);
    _bgRequired = detail.bgRequired ?? 'No';
    _insuranceRequired = detail.insuranceRequired ?? 'No';
    _milestoneRequired = detail.milestoneRequired ?? 'No';
    _revisionRequired = detail.revisionRequired ?? 'No';
    _keyPersonnelRequired = detail.keyPersonnelRequired ?? 'No';
    _gstInclusive = detail.gstInclusive;
    _gstRate.text = detail.gstRate ?? '';

    if (detail.executives.isNotEmpty) {
      _execRows
        ..clear()
        ..addAll(
          detail.executives.map(
            (ContractExecutiveRow e) => _ExecRow(
              departmentId: e.departmentId,
              executiveIds: List<String>.from(e.executiveIds),
            ),
          ),
        );
    }
    if (detail.revisions.isNotEmpty) {
      for (final _RevRow row in _revRows) {
        row.dispose();
      }
      _revRows
        ..clear()
        ..addAll(
          detail.revisions.map((ContractRevisionRow e) {
            final _RevRow row = _RevRow();
            row.revisionNo.text = e.revisionNo ?? 'R1';
            row.estimatedCost.text = e.estimatedCost ?? '';
            row.remarks.text = e.remarks ?? '';
            row.plannedAward = _parseDate(e.plannedAward);
            row.plannedCompletion = _parseDate(e.plannedCompletion);
            row.nit = _parseDate(e.noticeInvitingTender);
            row.tenderOpening = _parseDate(e.tenderOpeningDate);
            row.techApproval = _parseDate(e.technicalEvalApproval);
            row.finApproval = _parseDate(e.financialEvalApproval);
            return row;
          }),
        );
    }
  }

  Future<void> _pickDate(ValueChanged<DateTime> onPicked, DateTime? current) async {
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

  void _comingSoon(String action) {
    GlobalDialog.info(
      '$action will be connected when the API is available.',
      title: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ContractFormDetail> async =
        ref.watch(contractFormProvider(widget.contractId ?? ''));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'Update Contract (${widget.contractId})'
              : 'Add Contract',
        ),
      ),
      body: async.when(
        loading: () => const Stack(
          children: <Widget>[
            AppGlobalLoader(),
          ],
        ),
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
                    contractFormProvider(widget.contractId ?? ''),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (ContractFormDetail detail) {
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

  Widget _body(ContractFormDetail detail) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool awarded = _awarded == 'Yes';
    final AsyncValue<List<DropdownOption>> hodAsync =
        ref.watch(contractHodListProvider);
    final AsyncValue<List<DropdownOption>> dyHodAsync =
        ref.watch(contractDyHodListProvider(_hodUserId ?? ''));
    final AsyncValue<List<DropdownOption>> workStatusAsync =
        ref.watch(contractFormWorkStatusProvider(_awarded));
    final bool execLoading = _execRows.any((_ExecRow row) {
      return ref
          .watch(contractExecutivesProvider(row.departmentId ?? ''))
          .isLoading;
    });
    final bool loading = hodAsync.isLoading ||
        dyHodAsync.isLoading ||
        workStatusAsync.isLoading ||
        execLoading;

    return Stack(
      children: <Widget>[
        Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: <Widget>[
              _sectionTitle('Contract Managers'),
              if (_isEdit)
                _readOnly('Project *', _projectLabel ?? _projectId ?? '—')
              else
                _dropdown(
                  'Project *',
                  detail.options.projects,
                  _projectId,
                  (String? v) => setState(() => _projectId = v),
                ),
              const SizedBox(height: 10),
              _grid(<Widget>[
                _asyncDropdown(
                  'HOD *',
                  ref.watch(contractHodListProvider),
                  _hodUserId,
                  (String? v) => setState(() {
                    _hodUserId = v;
                    _dyHodUserId = null;
                  }),
                ),
                _asyncDropdown(
                  'Dy HOD *',
                  ref.watch(contractDyHodListProvider(_hodUserId ?? '')),
                  _dyHodUserId,
                  (String? v) => setState(() => _dyHodUserId = v),
                  enabled: _hodUserId != null,
                ),
              ]),
              const SizedBox(height: 10),
              _dropdown(
                'Contract Department *',
                detail.options.departments,
                _department,
                (String? v) => setState(() => _department = v),
              ),
              const SizedBox(height: 10),
              _yesNo('Bank Funded *', _bankFunded, (String v) {
                setState(() => _bankFunded = v);
              }),
              const SizedBox(height: 10),
              _yesNo('Contract Awarded? *', _awarded, (String v) {
                setState(() => _awarded = v);
              }),
              const SizedBox(height: 18),
              _sectionTitle('Executives'),
              for (int i = 0; i < _execRows.length; i++) ...<Widget>[
                _execCard(i, detail, scheme),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  onPressed: () => setState(() => _execRows.add(_ExecRow())),
                  icon: const Icon(Icons.add),
                ),
              ),
              const SizedBox(height: 12),
              _sectionTitle('Contract Details'),
              _text('Contract Short Name *', _shortName),
              const SizedBox(height: 10),
              _text('Contract Name *', _contractName, maxLines: 3),
              const SizedBox(height: 10),
              _dropdown(
                'Contract Type *',
                detail.options.contractTypes,
                _contractType,
                (String? v) => setState(() => _contractType = v),
              ),
              if (awarded) ...<Widget>[
                const SizedBox(height: 10),
                _dropdown(
                  'Contractor Name *',
                  detail.options.contractors,
                  _contractorId,
                  (String? v) => setState(() => _contractorId = v),
                ),
              ],
              const SizedBox(height: 10),
              _text('Contract Code', _contractCode),
              const SizedBox(height: 10),
              _text('Scope of Contract', _scope, maxLines: 3),
              if (awarded) ...<Widget>[
                const SizedBox(height: 10),
                _grid(<Widget>[
                  _text('LOA Letter No *', _loaNo),
                  _date('LOA Date *', _loaDate, (DateTime d) {
                    setState(() => _loaDate = d);
                  }),
                  _text('CA No', _caNo),
                  _date('CA Date', _caDate, (DateTime d) {
                    setState(() => _caDate = d);
                  }),
                  _date('Date of Start *', _dateOfStart, (DateTime d) {
                    setState(() => _dateOfStart = d);
                  }),
                  _date('Original DOC *', _originalDoc, (DateTime d) {
                    setState(() => _originalDoc = d);
                  }),
                ]),
                const SizedBox(height: 10),
                _amount(
                  'Awarded cost *',
                  _awardedCost,
                  detail.options.costUnits,
                  _awardedCostUnit,
                  (String? v) => setState(() => _awardedCostUnit = v),
                ),
                const SizedBox(height: 10),
                _date('Target DOC', _targetDoc, (DateTime d) {
                  setState(() => _targetDoc = d);
                }),
              ],
              const SizedBox(height: 10),
              _asyncDropdown(
                'Status of Work *',
                ref.watch(contractFormWorkStatusProvider(_awarded)),
                _workStatus,
                (String? v) => setState(() => _workStatus = v),
              ),
              const SizedBox(height: 10),
              _amount(
                'Detailed Estimated cost',
                _estimatedCost,
                detail.options.costUnits,
                _estimatedCostUnit,
                (String? v) => setState(() => _estimatedCostUnit = v),
              ),
              const SizedBox(height: 10),
              _grid(<Widget>[
                _date('Planned date of award', _plannedAward, (DateTime d) {
                  setState(() => _plannedAward = d);
                }),
                _date(
                  'Planned date of completion',
                  _plannedCompletion,
                  (DateTime d) => setState(() => _plannedCompletion = d),
                ),
                _date('Notice Inviting Tender', _nit, (DateTime d) {
                  setState(() => _nit = d);
                }),
                _date('Tender Opening Date', _tenderOpening, (DateTime d) {
                  setState(() => _tenderOpening = d);
                }),
                _date(
                  'Technical Eval. Submission',
                  _techSubmission,
                  (DateTime d) => setState(() => _techSubmission = d),
                ),
                _date(
                  'Financial Eval. Submission',
                  _finSubmission,
                  (DateTime d) => setState(() => _finSubmission = d),
                ),
              ]),
              const SizedBox(height: 18),
              _sectionTitle('Tender Bid Revisions'),
              for (int i = 0; i < _revRows.length; i++) ...<Widget>[
                _revCard(i, detail, scheme),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  onPressed: () => setState(() => _revRows.add(_RevRow())),
                  icon: const Icon(Icons.add),
                ),
              ),
              const SizedBox(height: 12),
              _sectionTitle('Bank Guarantee Details'),
              _yesNo('Bank Guarantee Required?', _bgRequired, (String v) {
                setState(() => _bgRequired = v);
              }),
              const SizedBox(height: 12),
              _sectionTitle('Insurance Details'),
              _yesNo('Insurance Required?', _insuranceRequired, (String v) {
                setState(() => _insuranceRequired = v);
              }),
              const SizedBox(height: 12),
              _sectionTitle('Milestone Details'),
              _yesNo('Milestone Required?', _milestoneRequired, (String v) {
                setState(() => _milestoneRequired = v);
              }),
              const SizedBox(height: 10),
              _yesNo('Revision Required?', _revisionRequired, (String v) {
                setState(() => _revisionRequired = v);
              }),
              const SizedBox(height: 12),
              _sectionTitle("Contractor's Key Personnel"),
              _yesNo("Contractor's Key Required?", _keyPersonnelRequired,
                  (String v) {
                setState(() => _keyPersonnelRequired = v);
              }),
              const SizedBox(height: 12),
              _sectionTitle('Documents'),
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
              const SizedBox(height: 12),
              _sectionTitle('GST Rate'),
              _grid(<Widget>[
                _dropdown(
                  'Contract Value inclusive of GST',
                  const <DropdownOption>[
                    DropdownOption(id: 'yes', name: 'Yes'),
                    DropdownOption(id: 'no', name: 'No'),
                  ],
                  _gstInclusive,
                  (String? v) => setState(() => _gstInclusive = v),
                ),
                _text('GST Rate', _gstRate),
              ]),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: <Widget>[
                if (_isEdit)
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _comingSoon('Update'),
                      child: const Text('UPDATE'),
                    ),
                  )
                else ...<Widget>[
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _comingSoon('Add'),
                      child: const Text('ADD'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _comingSoon('Save & Edit'),
                      child: const Text('SAVE & EDIT'),
                    ),
                  ),
                ],
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

  Widget _execCard(int index, ContractFormDetail detail, ColorScheme scheme) {
    final _ExecRow row = _execRows[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            _grid(<Widget>[
              _dropdown(
                'Department *',
                detail.options.departments,
                row.departmentId,
                (String? v) => setState(() {
                  row.departmentId = v;
                  row.executiveIds = <String>[];
                }),
              ),
              _asyncDropdown(
                'Select Executive *',
                ref.watch(contractExecutivesProvider(row.departmentId ?? '')),
                row.executiveIds.isEmpty ? null : row.executiveIds.first,
                (String? v) => setState(() {
                  row.executiveIds = v == null ? <String>[] : <String>[v];
                }),
                enabled: row.departmentId != null,
              ),
            ]),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: _execRows.length == 1
                    ? null
                    : () => setState(() => _execRows.removeAt(index)),
                icon: Icon(Icons.close, color: scheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _revCard(int index, ContractFormDetail detail, ColorScheme scheme) {
    final _RevRow row = _revRows[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            _grid(<Widget>[
              _text('Revision No.', row.revisionNo),
              _text('Detailed Estimated cost', row.estimatedCost),
              _date('Planned date of award', row.plannedAward, (DateTime d) {
                setState(() => row.plannedAward = d);
              }),
              _date(
                'Planned date of completion',
                row.plannedCompletion,
                (DateTime d) => setState(() => row.plannedCompletion = d),
              ),
              _date('Notice Inviting Tender', row.nit, (DateTime d) {
                setState(() => row.nit = d);
              }),
              _date('Tender Opening Date', row.tenderOpening, (DateTime d) {
                setState(() => row.tenderOpening = d);
              }),
              _date('Tech. Eval. Approval', row.techApproval, (DateTime d) {
                setState(() => row.techApproval = d);
              }),
              _date('Fin. Eval. Approval', row.finApproval, (DateTime d) {
                setState(() => row.finApproval = d);
              }),
            ]),
            const SizedBox(height: 10),
            _text('Remarks', row.remarks, maxLines: 2),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: _revRows.length == 1
                    ? null
                    : () {
                        setState(() {
                          _revRows.removeAt(index).dispose();
                        });
                      },
                icon: Icon(Icons.close, color: scheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docCard(int index, ContractFormDetail detail, ColorScheme scheme) {
    final _DocRow row = _docRows[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            _grid(<Widget>[
              _dropdown(
                'File Type',
                detail.options.fileTypes,
                row.fileType,
                (String? v) => setState(() => row.fileType = v),
              ),
              _text('Name', row.name),
            ]),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _comingSoon('Attach'),
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Attachment'),
                  ),
                ),
                const SizedBox(width: 4),
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

  static const double _labelSlotHeight = 40;
  static const EdgeInsets _controlPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 14,
  );

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
        child: Text(value),
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

  Widget _date(String label, DateTime? value, ValueChanged<DateTime> onPicked) {
    return _labeled(
      label,
      InkWell(
        onTap: () => _pickDate(onPicked, value),
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

  Widget _yesNo(String label, String value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(label, style: _fieldLabelStyle),
        ),
        RadioGroup<String>(
          groupValue: value,
          onChanged: (String? v) {
            if (v != null) {
              onChanged(v);
            }
          },
          child: Row(
            children: <Widget>[
              Expanded(
                child: RadioListTile<String>(
                  value: 'Yes',
                  title: const Text('Yes'),
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  value: 'No',
                  title: const Text('No'),
                  dense: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amount(
    String label,
    TextEditingController controller,
    List<DropdownOption> units,
    String? unit,
    ValueChanged<String?> onUnit,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(flex: 2, child: _text(label, controller)),
        const SizedBox(width: 8),
        Expanded(child: _dropdown('Unit', units, unit, onUnit)),
      ],
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
      async.valueOrNull ?? const <DropdownOption>[],
      value,
      onChanged,
      enabled: enabled,
    );
  }
}
