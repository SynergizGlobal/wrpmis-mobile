import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/project_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/projects/providers/project_form_providers.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/projects/providers/project_list_provider.dart';

/// Shared Add/Edit Project form matching the web Add Project screen.
/// Pass [projectId] to edit; omit for add.
class ProjectFormPage extends ConsumerStatefulWidget {
  const ProjectFormPage({super.key, this.projectId});

  static const String routeName = 'project-form';
  static const String routePath = '/project-form';

  final String? projectId;

  bool get isEdit => projectId != null && projectId!.isNotEmpty;

  @override
  ConsumerState<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends ConsumerState<ProjectFormPage> {
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDate = DateFormat('dd/MM/yyyy');
  static const List<String> _statusOptions = <String>[
    'Open',
    'Closed',
    'In Progress',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _prefilled = false;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _planHeadCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _pbItemCtrl = TextEditingController();
  final TextEditingController _actualCostCtrl = TextEditingController();
  final TextEditingController _proposedLengthCtrl = TextEditingController();
  final TextEditingController _benefitsCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

  DateTime? _sanctionedCommDate;
  DateTime? _actualCompletionDate;

  String? _selectedStatus;
  String? _selectedTypeId;
  String? _selectedZone;
  String? _selectedDivision;
  String? _selectedSection;
  String? _selectedYear;

  final List<_CommissionedCtrls> _commissionedRows = <_CommissionedCtrls>[];
  final List<_CostCtrls> _costRows = <_CostCtrls>[];

  @override
  void initState() {
    super.initState();
    _commissionedRows.add(_CommissionedCtrls());
    _costRows.add(_CostCtrls());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _planHeadCtrl.dispose();
    _amountCtrl.dispose();
    _pbItemCtrl.dispose();
    _actualCostCtrl.dispose();
    _proposedLengthCtrl.dispose();
    _benefitsCtrl.dispose();
    _remarksCtrl.dispose();
    for (final _CommissionedCtrls row in _commissionedRows) {
      row.dispose();
    }
    for (final _CostCtrls row in _costRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _prefill(ProjectDetail project) {
    if (_prefilled) return;
    _prefilled = true;

    _nameCtrl.text = project.projectName;
    _planHeadCtrl.text = project.planHeadNumber ?? '';
    _amountCtrl.text = project.sanctionedAmount ?? '';
    _pbItemCtrl.text = project.pbItemNo ?? '';
    _actualCostCtrl.text = project.actualCompletionCost ?? '';
    _proposedLengthCtrl.text = project.proposedLength ?? '';
    _benefitsCtrl.text = project.benefits ?? '';
    _remarksCtrl.text = project.remarks ?? '';

    _selectedStatus = project.projectStatus;
    _selectedTypeId = project.projectTypeIdFk;
    _selectedZone = project.railwayZone;
    _selectedDivision = project.divisionId ?? project.division;
    _selectedSection = project.sectionId ?? project.sections;
    _selectedYear = project.financialYearFk;
    _sanctionedCommDate = _parseDate(project.sanctionedCommissioningDate);
    _actualCompletionDate = _parseDate(project.actualCompletionDate);

    for (final _CommissionedCtrls row in _commissionedRows) {
      row.dispose();
    }
    _commissionedRows.clear();
    if (project.commissionedLengths.isEmpty) {
      _commissionedRows.add(_CommissionedCtrls());
    } else {
      for (final CommissionedLengthRow r in project.commissionedLengths) {
        _commissionedRows.add(
          _CommissionedCtrls(
            id: r.id,
            from: r.fromChainage,
            to: r.toChainage,
            completed: r.completedLength,
          ),
        );
      }
    }

    for (final _CostCtrls row in _costRows) {
      row.dispose();
    }
    _costRows.clear();
    if (project.costRows.isEmpty) {
      _costRows.add(_CostCtrls());
    } else {
      for (final ProjectCostRow r in project.costRows) {
        _costRows.add(
          _CostCtrls(
            date: _parseDate(r.date),
            estimatedCost: r.estimatedCompletionCost,
            revisedDate: _parseDate(r.revisedCompletionDate),
          ),
        );
      }
    }
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final String raw = value.trim();
    try {
      return _apiDate.parseStrict(raw.split(' ').first);
    } catch (_) {}
    try {
      return _displayDate.parseStrict(raw.split(' ').first);
    } catch (_) {}
    return DateTime.tryParse(raw);
  }

  String _formatDisplay(DateTime? date) {
    if (date == null) return '';
    return _displayDate.format(date);
  }

  String? _formatApi(DateTime? date) {
    if (date == null) return null;
    return _apiDate.format(date);
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final List<Map<String, dynamic>> commissioned =
        <Map<String, dynamic>>[];
    for (final _CommissionedCtrls row in _commissionedRows) {
      if (row.isEmpty) continue;
      commissioned.add(<String, dynamic>{
        if (row.id != null) 'commissioned_id': row.id,
        'commission_from_chainage': row.fromCtrl.text.trim(),
        'commission_to_chainage': row.toCtrl.text.trim(),
        'commission_completed_length': row.completedCtrl.text.trim(),
      });
    }

    final List<Map<String, dynamic>> costs = <Map<String, dynamic>>[];
    for (final _CostCtrls row in _costRows) {
      if (row.isEmpty) continue;
      costs.add(<String, dynamic>{
        if (row.date != null) 'entry_date': _formatApi(row.date),
        'estimated_completion_cost': row.costCtrl.text.trim(),
        if (row.revisedDate != null)
          'revised_completion_date': _formatApi(row.revisedDate),
      });
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      if (widget.isEdit) 'project_id': widget.projectId,
      'project_name': _nameCtrl.text.trim(),
      'project_status': _selectedStatus,
      'plan_head_number': _planHeadCtrl.text.trim(),
      if (_selectedTypeId != null) 'project_type_id_fk': _selectedTypeId,
      if (_selectedZone != null) 'railway_zone': _selectedZone,
      if (_selectedDivision != null) 'division_id': _selectedDivision,
      if (_selectedSection != null) 'section_id': _selectedSection,
      if (_selectedYear != null) 'financial_year_fk': _selectedYear,
      if (_amountCtrl.text.trim().isNotEmpty)
        'sanctioned_amount': _amountCtrl.text.trim(),
      if (_sanctionedCommDate != null)
        'sanctioned_commissioning_date': _formatApi(_sanctionedCommDate),
      if (_pbItemCtrl.text.trim().isNotEmpty)
        'pb_item_no': _pbItemCtrl.text.trim(),
      if (_actualCostCtrl.text.trim().isNotEmpty)
        'actual_completion_cost': _actualCostCtrl.text.trim(),
      if (_actualCompletionDate != null)
        'actual_completion_date': _formatApi(_actualCompletionDate),
      if (_proposedLengthCtrl.text.trim().isNotEmpty)
        'proposed_length': _proposedLengthCtrl.text.trim(),
      if (_benefitsCtrl.text.trim().isNotEmpty)
        'benefits': _benefitsCtrl.text.trim(),
      if (_remarksCtrl.text.trim().isNotEmpty)
        'remarks': _remarksCtrl.text.trim(),
      if (commissioned.isNotEmpty)
        'projectCommissionedLengthList': commissioned,
      if (costs.isNotEmpty) 'projectPinkBooks': costs,
    };

    final result = widget.isEdit
        ? await ref.read(projectRepositoryProvider).updateProject(payload)
        : await ref.read(projectRepositoryProvider).addProject(payload);

    if (!mounted) return;
    setState(() => _submitting = false);

    await result.fold(
      (failure) async {
        await GlobalDialog.error(failure.message);
      },
      (message) async {
        ref.invalidate(projectListProvider);
        await GlobalDialog.success(message);
        if (mounted) {
          context.pop(true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ProjectFormData> formDataAsync =
        ref.watch(projectFormDataProvider);
    final AsyncValue<ProjectDetail>? editAsync = widget.isEdit
        ? ref.watch(projectByIdProvider(widget.projectId!))
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Project' : 'Add Project'),
      ),
      body: formDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => _errorView(e, () {
          ref.invalidate(projectFormDataProvider);
        }),
        data: (ProjectFormData formData) {
          if (widget.isEdit && editAsync != null) {
            return editAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace _) => _errorView(e, () {
                ref.invalidate(projectByIdProvider(widget.projectId!));
              }),
              data: (ProjectDetail project) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_prefilled && mounted) {
                    setState(() => _prefill(project));
                  }
                });
                return _buildForm(formData);
              },
            );
          }
          return _buildForm(formData);
        },
      ),
    );
  }

  Widget _errorView(Object error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ProjectFormData formData) {
    final List<DropdownOption> sectionOptions =
        formData.sectionsForDivision(_selectedDivision);

    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: <Widget>[
                _textField('Project Name *', _nameCtrl, required: true),
                const SizedBox(height: 12),
                _dropdown(
                  'Project Status *',
                  _statusOptions,
                  _selectedStatus,
                  (String? v) => setState(() => _selectedStatus = v),
                  required: true,
                ),
                const SizedBox(height: 12),
                _dropdownFromOptions(
                  'Project Type',
                  formData.projectTypes,
                  _selectedTypeId,
                  (String? v) => setState(() => _selectedTypeId = v),
                ),
                const SizedBox(height: 12),
                _dropdownFromOptions(
                  'Railway Zone',
                  formData.railwayZones,
                  _selectedZone,
                  (String? v) => setState(() => _selectedZone = v),
                ),
                const SizedBox(height: 12),
                _textField('Plan Head Number *', _planHeadCtrl, required: true),
                const SizedBox(height: 12),
                _dropdownFromOptions(
                  'Sanctioned Year',
                  formData.years,
                  _selectedYear,
                  (String? v) => setState(() => _selectedYear = v),
                ),
                const SizedBox(height: 12),
                _textField(
                  'Sanctioned Amount',
                  _amountCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _dateField(
                  'Sanctioned Commissioning Date',
                  _sanctionedCommDate,
                  (DateTime d) => setState(() => _sanctionedCommDate = d),
                ),
                const SizedBox(height: 12),
                _dropdownFromOptions(
                  'Division',
                  formData.divisions,
                  _selectedDivision,
                  (String? v) => setState(() {
                    _selectedDivision = v;
                    _selectedSection = null;
                  }),
                ),
                const SizedBox(height: 12),
                _dropdownFromOptions(
                  'Section',
                  sectionOptions,
                  _selectedSection,
                  (String? v) => setState(() => _selectedSection = v),
                ),
                const SizedBox(height: 12),
                _textField('PB Item No', _pbItemCtrl),
                const SizedBox(height: 12),
                _textField(
                  'Actual Completion Cost',
                  _actualCostCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _dateField(
                  'Actual Completion Date',
                  _actualCompletionDate,
                  (DateTime d) => setState(() => _actualCompletionDate = d),
                ),
                const SizedBox(height: 12),
                _textField(
                  'Proposed Length (km)',
                  _proposedLengthCtrl,
                  hint: 'Enter proposed length',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                _textField('Benefits', _benefitsCtrl, maxLines: 3),
                const SizedBox(height: 12),
                _textField('Remarks', _remarksCtrl, maxLines: 3),
                const SizedBox(height: 20),
                _sectionTitle('Commissioned Length'),
                const SizedBox(height: 8),
                _commissionedTable(),
                const SizedBox(height: 20),
                _sectionTitle('Estimated / Revised Cost'),
                const SizedBox(height: 8),
                _costTable(),
                const SizedBox(height: 20),
                _sectionTitle('KMZ file / Chainage-wise Coordinates Upload'),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.brandAppBar,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () {
                          GlobalDialog.info(
                            'KMZ download will be connected next.',
                            title: 'Download',
                          );
                        },
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Download'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.brandAppBar,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () {
                          GlobalDialog.info(
                            'KMZ upload will be connected next.',
                            title: 'Upload',
                          );
                        },
                        icon: const Icon(Icons.upload_rounded),
                        label: const Text('Upload'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: AppPalette.of(context).stickyBar,
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
                        backgroundColor: AppTheme.brandAppBar,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: _submitting ? null : () => context.pop(),
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : Text(widget.isEdit ? 'UPDATE' : 'ADD'),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.brandAppBar,
          ),
    );
  }

  Widget _commissionedTable() {
    return _dynamicCard(
      headers: const <String>[
        'S. No.',
        'From Chainage (m)',
        'To Chainage (m)',
        'Completed Length (m)',
        '',
      ],
      rows: List<Widget>.generate(_commissionedRows.length, (int index) {
        final _CommissionedCtrls row = _commissionedRows[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 36,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text('${index + 1}', textAlign: TextAlign.center),
                ),
              ),
              Expanded(child: _miniField(row.fromCtrl)),
              const SizedBox(width: 6),
              Expanded(child: _miniField(row.toCtrl)),
              const SizedBox(width: 6),
              Expanded(child: _miniField(row.completedCtrl)),
              IconButton(
                onPressed: _commissionedRows.length == 1
                    ? null
                    : () => setState(() {
                          row.dispose();
                          _commissionedRows.removeAt(index);
                        }),
                icon: const Icon(Icons.cancel, color: Colors.redAccent),
              ),
            ],
          ),
        );
      }),
      onAdd: () => setState(() => _commissionedRows.add(_CommissionedCtrls())),
    );
  }

  Widget _costTable() {
    return _dynamicCard(
      headers: const <String>[
        'Date',
        'Estimated Completion Cost',
        'Revised Completion Date',
        '',
      ],
      rows: List<Widget>.generate(_costRows.length, (int index) {
        final _CostCtrls row = _costRows[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _miniDateField(
                  row.date,
                  (DateTime d) => setState(() => row.date = d),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: _miniField(row.costCtrl)),
              const SizedBox(width: 6),
              Expanded(
                child: _miniDateField(
                  row.revisedDate,
                  (DateTime d) => setState(() => row.revisedDate = d),
                ),
              ),
              IconButton(
                onPressed: _costRows.length == 1
                    ? null
                    : () => setState(() {
                          row.dispose();
                          _costRows.removeAt(index);
                        }),
                icon: const Icon(Icons.cancel, color: Colors.redAccent),
              ),
            ],
          ),
        );
      }),
      onAdd: () => setState(() => _costRows.add(_CostCtrls())),
    );
  }

  Widget _dynamicCard({
    required List<String> headers,
    required List<Widget> rows,
    required VoidCallback onAdd,
  }) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              headers.where((String h) => h.isNotEmpty).join('  •  '),
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 4, 8),
            child: Column(children: rows),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
        ],
      ),
    );
  }

  Widget _miniField(TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
    );
  }

  Widget _miniDateField(DateTime? value, ValueChanged<DateTime> onPicked) {
    return InkWell(
      onTap: () => _pickDate(current: value, onPicked: onPicked),
      child: InputDecorator(
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          suffixIcon: Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(
          value == null ? 'dd/mm/yyyy' : _formatDisplay(value),
          style: TextStyle(
            color: value == null
                ? AppPalette.of(context).mutedText
                : Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (String? v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null
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
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          value == null ? 'dd/mm/yyyy' : _formatDisplay(value),
          style: TextStyle(
            color: value == null
                ? AppPalette.of(context).mutedText
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey<String>('status-$label-$value'),
      initialValue: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((String s) => DropdownMenuItem<String>(value: s, child: Text(s)))
          .toList(),
      onChanged: onChanged,
      validator: required
          ? (String? v) => (v == null || v.isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _dropdownFromOptions(
    String label,
    List<DropdownOption> options,
    String? selectedId,
    ValueChanged<String?> onChanged,
  ) {
    final Set<String> validIds = options.map((DropdownOption o) => o.id).toSet();
    return DropdownButtonFormField<String>(
      key: ValueKey<String>('opt-$label-$selectedId'),
      initialValue: validIds.contains(selectedId) ? selectedId : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      isExpanded: true,
      items: options
          .map(
            (DropdownOption o) => DropdownMenuItem<String>(
              value: o.id,
              child: Text(o.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _CommissionedCtrls {
  _CommissionedCtrls({
    this.id,
    String? from,
    String? to,
    String? completed,
  })  : fromCtrl = TextEditingController(text: from ?? ''),
        toCtrl = TextEditingController(text: to ?? ''),
        completedCtrl = TextEditingController(text: completed ?? '');

  final String? id;
  final TextEditingController fromCtrl;
  final TextEditingController toCtrl;
  final TextEditingController completedCtrl;

  bool get isEmpty =>
      fromCtrl.text.trim().isEmpty &&
      toCtrl.text.trim().isEmpty &&
      completedCtrl.text.trim().isEmpty;

  void dispose() {
    fromCtrl.dispose();
    toCtrl.dispose();
    completedCtrl.dispose();
  }
}

class _CostCtrls {
  _CostCtrls({
    this.date,
    String? estimatedCost,
    this.revisedDate,
  }) : costCtrl = TextEditingController(text: estimatedCost ?? '');

  DateTime? date;
  DateTime? revisedDate;
  final TextEditingController costCtrl;

  bool get isEmpty =>
      date == null &&
      costCtrl.text.trim().isEmpty &&
      revisedDate == null;

  void dispose() {
    costCtrl.dispose();
  }
}
