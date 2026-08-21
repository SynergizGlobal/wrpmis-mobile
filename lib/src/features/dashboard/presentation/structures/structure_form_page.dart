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

/// Shared Add/Update Structure form matching the web screens.
/// Pass [structureId] (list-row id) to update; omit for add.
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _prefilled = false;

  String? _selectedProjectId;
  String? _projectLabel;
  final List<_TypeBlockState> _blocks = <_TypeBlockState>[];

  @override
  void initState() {
    super.initState();
    if (!widget.isEdit) {
      _blocks.add(_TypeBlockState());
    }
  }

  @override
  void dispose() {
    for (final _TypeBlockState b in _blocks) {
      b.dispose();
    }
    super.dispose();
  }

  void _prefill(StructureDetail detail) {
    if (_prefilled) return;
    _prefilled = true;
    _selectedProjectId = detail.projectIdFk;
    _projectLabel = detail.projectLabel ?? detail.projectIdFk;

    for (final _TypeBlockState b in _blocks) {
      b.dispose();
    }
    _blocks.clear();

    if (detail.groups.isEmpty) {
      _blocks.add(_TypeBlockState());
    } else {
      for (final StructureTypeGroup group in detail.groups) {
        _blocks.add(_TypeBlockState.fromGroup(group));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!widget.isEdit &&
        (_selectedProjectId == null || _selectedProjectId!.isEmpty)) {
      await GlobalDialog.error('Please select a project.');
      return;
    }

    final List<StructureTypeGroup> groups = <StructureTypeGroup>[];
    for (final _TypeBlockState block in _blocks) {
      final String type = block.structureType?.trim() ?? '';
      if (type.isEmpty) continue;
      final List<StructureNameRow> rows = <StructureNameRow>[];
      for (final _NameRowState row in block.rows) {
        final String structure = row.structureCtrl.text.trim();
        final String name = row.nameCtrl.text.trim();
        if (structure.isEmpty && name.isEmpty) continue;
        rows.add(
          StructureNameRow(
            structureId: row.structureId,
            structure: structure.isEmpty ? name : structure,
            structureName: name.isEmpty ? structure : name,
          ),
        );
      }
      // Keep edit type groups even if all name rows were cleared (deletion intent).
      if (rows.isEmpty && widget.isEdit) {
        continue;
      }
      if (rows.isEmpty && !widget.isEdit) {
        await GlobalDialog.error(
          'Add at least one Structure Id / Name under each structure type.',
        );
        return;
      }
      groups.add(StructureTypeGroup(structureType: type, rows: rows));
    }

    if (groups.isEmpty) {
      await GlobalDialog.error('Add at least one structure type.');
      return;
    }

    // Add mode requires nested rows; edit may only manage types (keep loaded rows).
    if (widget.isEdit) {
      for (int i = 0; i < groups.length; i++) {
        if (groups[i].rows.isEmpty) {
          // Restore empty placeholder so type-only add still posts one blank row.
          groups[i] = StructureTypeGroup(
            structureType: groups[i].structureType,
            rows: const <StructureNameRow>[
              StructureNameRow(structure: '', structureName: ''),
            ],
          );
        }
      }
    }

    setState(() => _submitting = true);
    final StructureDetail draft = StructureDetail(
      structureId: widget.structureId ?? '',
      projectIdFk: _selectedProjectId,
      projectLabel: _projectLabel,
      groups: groups,
    );
    final Map<String, dynamic> payload = draft.toPayload();

    final repo = ref.read(projectRepositoryProvider);
    final dynamic result = widget.isEdit
        ? await repo.updateStructures(payload)
        : await repo.addStructures(payload);

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

  void _addTypeBlock() {
    setState(() => _blocks.add(_TypeBlockState(isNew: true)));
  }

  void _removeTypeBlock(int index) {
    if (_blocks.length <= 1) return;
    setState(() {
      _blocks.removeAt(index).dispose();
    });
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
        title: Text(widget.isEdit ? 'Update Structure' : 'Add Structure'),
      ),
      body: formDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (StructureFormData formData) {
          if (widget.isEdit && editAsync != null) {
            return editAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (StructureDetail detail) {
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
    final List<DropdownOption> projects = formData.projects;
    final List<DropdownOption> types = formData.structureTypes;

    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: <Widget>[
                if (widget.isEdit)
                  _readOnlyProjectField(
                    palette,
                    _projectLabel ?? _selectedProjectId ?? '',
                  )
                else
                  _projectDropdown(projects, palette),
                const SizedBox(height: 16),
                _structureTypesCard(types, palette, scheme),
              ],
            ),
          ),
          _stickyActions(palette, scheme),
        ],
      ),
    );
  }

  Widget _readOnlyProjectField(AppPalette palette, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Project *',
          style: TextStyle(fontSize: 12, color: palette.mutedText),
        ),
        const SizedBox(height: 6),
        Text(
          label.isEmpty ? '—' : label,
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Divider(height: 20, color: palette.borderSubtle),
      ],
    );
  }

  Widget _projectDropdown(List<DropdownOption> projects, AppPalette palette) {
    final Set<String> validIds = projects.map((DropdownOption o) => o.id).toSet();
    return DropdownButtonFormField<String>(
      key: ValueKey<String>('project-$_selectedProjectId'),
      initialValue:
          validIds.contains(_selectedProjectId) ? _selectedProjectId : null,
      decoration: InputDecoration(
        labelText: 'Project *',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: palette.cardSurface,
      ),
      isExpanded: true,
      items: projects
          .map(
            (DropdownOption o) => DropdownMenuItem<String>(
              value: o.id,
              child: Text(_projectDisplay(o), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (String? v) {
        setState(() {
          _selectedProjectId = v;
          DropdownOption? match;
          for (final DropdownOption o in projects) {
            if (o.id == v) {
              match = o;
              break;
            }
          }
          _projectLabel = match == null ? v : _projectDisplay(match);
        });
      },
      validator: (String? v) =>
          (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  String _projectDisplay(DropdownOption o) {
    final String name = o.name.trim();
    if (name.startsWith(o.id)) return name;
    return '${o.id}- $name';
  }

  Widget _structureTypesCard(
    List<DropdownOption> types,
    AppPalette palette,
    ColorScheme scheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Material(
            color: palette.cardSurface,
            elevation: 1,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < _blocks.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 12),
                    _typeBlock(i, types, palette, scheme),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Material(
            color: scheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _addTypeBlock,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.add, color: scheme.onPrimary, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _typeBlock(
    int index,
    List<DropdownOption> types,
    AppPalette palette,
    ColorScheme scheme,
  ) {
    final _TypeBlockState block = _blocks[index];
    final Set<String> validIds = types.map((DropdownOption o) => o.id).toSet();
    final String? selected =
        validIds.contains(block.structureType) ? block.structureType : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Structure Type :',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey<String>('type-$index-$selected'),
                initialValue: selected,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? palette.tableRowEven
                      : const Color(0xFFE8E8E8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                ),
                isExpanded: true,
                items: types
                    .map(
                      (DropdownOption o) => DropdownMenuItem<String>(
                        value: o.id,
                        child: Text(o.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (String? v) {
                  setState(() => block.structureType = v);
                },
                validator: (String? v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: scheme.primary,
              child: Text(
                '${widget.isEdit ? block.rows.length : block.filledCount}',
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: Colors.red.shade600,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _removeTypeBlock(index),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        // Add: always show Structure Id/Name rows.
        // Update: type+count only (screenshot); show rows when adding a new type.
        if (!widget.isEdit || block.isNew) ...<Widget>[
          const SizedBox(height: 10),
          _nameRowsTable(block, palette, scheme),
        ],
      ],
    );
  }

  Widget _nameRowsTable(
    _TypeBlockState block,
    AppPalette palette,
    ColorScheme scheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: palette.borderSubtle),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: <Widget>[
          Container(
            color: palette.tableRowEven,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Structure Id',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Structure Name',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
          for (int r = 0; r < block.rows.length; r++)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: block.rows[r].structureCtrl,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: block.rows[r].nameCtrl,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: block.rows.length <= 1
                        ? null
                        : () {
                            setState(() {
                              block.rows.removeAt(r).dispose();
                            });
                          },
                    icon: Icon(Icons.close, color: Colors.red.shade600),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
              child: Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    setState(() => block.rows.add(_NameRowState()));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.add, size: 18, color: scheme.onPrimary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stickyActions(AppPalette palette, ColorScheme scheme) {
    return SafeArea(
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
                  shape: const StadiumBorder(),
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
                    : Text(widget.isEdit ? 'UPDATE' : 'ADD'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBlockState {
  _TypeBlockState({
    this.structureType,
    List<_NameRowState>? rows,
    this.isNew = false,
  }) : rows = rows ?? <_NameRowState>[_NameRowState()];

  factory _TypeBlockState.fromGroup(StructureTypeGroup group) {
    final List<_NameRowState> rows = group.rows.isEmpty
        ? <_NameRowState>[_NameRowState()]
        : group.rows.map(_NameRowState.fromEntity).toList();
    return _TypeBlockState(structureType: group.structureType, rows: rows);
  }

  String? structureType;
  final List<_NameRowState> rows;
  final bool isNew;

  int get filledCount => rows
      .where(
        (_NameRowState r) =>
            r.structureCtrl.text.trim().isNotEmpty ||
            r.nameCtrl.text.trim().isNotEmpty ||
            r.structureId.isNotEmpty,
      )
      .length
      .clamp(0, 999);

  void dispose() {
    for (final _NameRowState r in rows) {
      r.dispose();
    }
  }
}

class _NameRowState {
  _NameRowState({
    this.structureId = '',
    String structure = '',
    String name = '',
  })  : structureCtrl = TextEditingController(text: structure),
        nameCtrl = TextEditingController(text: name);

  factory _NameRowState.fromEntity(StructureNameRow row) {
    return _NameRowState(
      structureId: row.structureId,
      structure: row.structure,
      name: row.structureName,
    );
  }

  final String structureId;
  final TextEditingController structureCtrl;
  final TextEditingController nameCtrl;

  void dispose() {
    structureCtrl.dispose();
    nameCtrl.dispose();
  }
}
