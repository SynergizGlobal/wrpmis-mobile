import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/project_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/structure_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/structures/providers/structure_form_providers.dart';

/// Shared Add/Edit Structure form.
/// Pass [structureId] to edit; omit for add.
class StructureFormPage extends ConsumerStatefulWidget {
  const StructureFormPage({super.key, this.structureId});

  static const String routeName = 'structure-form';
  static const String routePath = '/structure-form';

  final String? structureId;

  bool get isEdit => structureId != null && structureId!.isNotEmpty;

  @override
  ConsumerState<StructureFormPage> createState() => _StructureFormPageState();
}

class _StructureFormPageState extends ConsumerState<StructureFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  final _nameCtrl = TextEditingController();
  final _structureCtrl = TextEditingController();

  String? _selectedProject;
  String? _selectedType;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _structureCtrl.dispose();
    super.dispose();
  }

  void _prefill(StructureDetail detail) {
    if (_prefilled) return;
    _prefilled = true;
    _nameCtrl.text = detail.structureName ?? '';
    _structureCtrl.text = detail.structure ?? '';
    _selectedProject = detail.projectIdFk;
    _selectedType = detail.structureTypeFk;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final repo = ref.read(projectRepositoryProvider);
    final dynamic result;

    if (widget.isEdit) {
      result = await repo.updateStructures({
        'project_id_fk': _selectedProject,
        'structure_type_fks': [_selectedType ?? ''],
        'structures': [_structureCtrl.text.trim()],
        'structure_names': [_nameCtrl.text.trim()],
        'structure_ids': [widget.structureId],
      });
    } else {
      result = await repo.addStructures({
        'project_id_fk': _selectedProject,
        'structure_type_fks': [_selectedType ?? ''],
        'structure_names': [_nameCtrl.text.trim()],
      });
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    await result.fold(
      (failure) async {
        await GlobalDialog.error(failure.message);
      },
      (message) async {
        await GlobalDialog.success(message);
        if (mounted) {
          context.pop(true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formDataAsync = ref.watch(structureFormDataProvider);
    final editAsync = widget.isEdit
        ? ref.watch(structureByIdProvider(widget.structureId!))
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Structure' : 'Add Structure'),
      ),
      body: formDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (formData) {
          if (widget.isEdit && editAsync != null) {
            return editAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (detail) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_prefilled && mounted) {
                    setState(() => _prefill(detail));
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

  Widget _buildForm(StructureFormData formData) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: <Widget>[
                _dropdownFromOptions(
                  'Project *',
                  formData.projects,
                  _selectedProject,
                  (v) => setState(() => _selectedProject = v),
                  required: true,
                ),
                const SizedBox(height: 14),
                _dropdownFromOptions(
                  'Structure Type *',
                  formData.structures,
                  _selectedType,
                  (v) => setState(() => _selectedType = v),
                  required: true,
                ),
                const SizedBox(height: 14),
                _textField('Structure Name *', _nameCtrl, required: true),
                const SizedBox(height: 14),
                if (widget.isEdit) ...[
                  _textField('Structure', _structureCtrl),
                  const SizedBox(height: 14),
                ],
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
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        minimumSize: const Size(0, 48),
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

  Widget _textField(
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
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _dropdownFromOptions(
    String label,
    List<DropdownOption> options,
    String? selectedId,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) {
    final validIds = options.map((o) => o.id).toSet();
    return DropdownButtonFormField<String>(
      key: ValueKey<String>('struct-$label-$selectedId'),
      initialValue: validIds.contains(selectedId) ? selectedId : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      isExpanded: true,
      items: options
          .map((o) => DropdownMenuItem(value: o.id, child: Text(o.name)))
          .toList(),
      onChanged: onChanged,
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Required' : null
          : null,
    );
  }
}
