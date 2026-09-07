import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/project_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/p6_upload_kind.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_list_item.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/projects/providers/project_list_provider.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/structures/providers/structure_form_edit_providers.dart';

/// Mobile P6 New Data sheet: type → project → contract → date → file → upload.
Future<bool?> showP6NewDataSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => const _P6NewDataSheet(),
  );
}

class _P6NewDataSheet extends ConsumerStatefulWidget {
  const _P6NewDataSheet();

  @override
  ConsumerState<_P6NewDataSheet> createState() => _P6NewDataSheetState();
}

class _P6NewDataSheetState extends ConsumerState<_P6NewDataSheet> {
  static final DateFormat _apiDate = DateFormat('dd-MM-yyyy');
  static final DateFormat _displayDate = DateFormat('dd/MM/yyyy');

  P6UploadKind _kind = P6UploadKind.baseline;
  String? _projectId;
  String? _contractId;
  DateTime? _dataDate;
  PlatformFile? _file;
  bool _submitting = false;

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataDate ?? now,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      setState(() => _dataDate = picked);
    }
  }

  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _kind.allowedExtensions,
      withData: false,
    );
    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }
    final PlatformFile file = result.files.first;
    if (file.path == null || file.path!.isEmpty) {
      await GlobalDialog.error('Unable to read the selected file path.');
      return;
    }
    setState(() => _file = file);
  }

  Future<void> _openTemplate() async {
    final Uri uri = Uri.parse(_kind.templateUrl);
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      await GlobalDialog.error('Unable to open the file format template.');
    }
  }

  Future<void> _submit() async {
    if (_projectId == null || _projectId!.isEmpty) {
      await GlobalDialog.error('Please select a project.');
      return;
    }
    if (_contractId == null || _contractId!.isEmpty) {
      await GlobalDialog.error('Please select a contract.');
      return;
    }
    if (_dataDate == null) {
      await GlobalDialog.error('Please select a data date.');
      return;
    }
    if (_file == null || _file!.path == null) {
      await GlobalDialog.error('Please upload a P6 data file.');
      return;
    }

    setState(() => _submitting = true);
    final result = await ref.read(projectRepositoryProvider).uploadP6Data(
          apiPath: _kind.apiPath,
          projectId: _projectId!,
          contractId: _contractId!,
          dataDate: _apiDate.format(_dataDate!),
          filePath: _file!.path!,
          fileName: _file!.name,
        );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);

    await result.fold(
      (Failure failure) => GlobalDialog.error(failure.message),
      (String message) async {
        await GlobalDialog.success(message, title: '${_kind.label} uploaded');
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      },
    );
  }

  void _onKindChanged(P6UploadKind kind) {
    setState(() {
      _kind = kind;
      _file = null;
    });
  }

  void _onProjectChanged(String? projectId) {
    setState(() {
      _projectId = projectId;
      _contractId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final MediaQueryData media = MediaQuery.of(context);
    final AsyncValue<List<ProjectListItem>> projectsAsync =
        ref.watch(projectListProvider);
    final AsyncValue<List<DropdownOption>> contractsAsync = _projectId == null
        ? const AsyncValue<List<DropdownOption>>.data(<DropdownOption>[])
        : ref.watch(structureFormContractsProvider(_projectId!));

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
          child: Material(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 10),
                Container(
                  width: 46,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'P6 New Data',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppSelectSheetField<P6UploadKind>(
                          label: 'Update Type *',
                          title: 'Select Update Type',
                          items: P6UploadKind.values,
                          value: _kind,
                          itemLabelBuilder: (P6UploadKind e) => e.label,
                          onChanged: _onKindChanged,
                          leadingIcon: Icons.tune_rounded,
                        ),
                        const SizedBox(height: 12),
                        projectsAsync.when(
                          loading: () =>
                              const LinearProgressIndicator(minHeight: 2),
                          error: (Object e, StackTrace _) => Text(
                            'Unable to load projects: $e',
                            style: TextStyle(color: scheme.error, fontSize: 12),
                          ),
                          data: (List<ProjectListItem> projects) {
                            final List<DropdownOption> items =
                                <DropdownOption>[
                              const DropdownOption(id: '', name: 'Select'),
                              ...projects.map(
                                (ProjectListItem p) => DropdownOption(
                                  id: p.projectId,
                                  name: '${p.projectId} — ${p.projectName}',
                                ),
                              ),
                            ];
                            return AppSelectSheetField<String>(
                              label: 'Project *',
                              title: 'Select Project',
                              items:
                                  items.map((DropdownOption e) => e.id).toList(),
                              value: _projectId ?? '',
                              itemLabelBuilder: (String id) {
                                return items
                                    .firstWhere(
                                      (DropdownOption e) => e.id == id,
                                      orElse: () => const DropdownOption(
                                        id: '',
                                        name: 'Select',
                                      ),
                                    )
                                    .name;
                              },
                              onChanged: (String id) =>
                                  _onProjectChanged(id.isEmpty ? null : id),
                              leadingIcon: Icons.folder_outlined,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        contractsAsync.when(
                          loading: () =>
                              const LinearProgressIndicator(minHeight: 2),
                          error: (Object e, StackTrace _) => Text(
                            'Unable to load contracts: $e',
                            style: TextStyle(color: scheme.error, fontSize: 12),
                          ),
                          data: (List<DropdownOption> contracts) {
                            final List<DropdownOption> items =
                                <DropdownOption>[
                              const DropdownOption(id: '', name: 'Select'),
                              ...contracts,
                            ];
                            return AppSelectSheetField<String>(
                              label: 'Contract *',
                              title: 'Select Contract',
                              enabled: _projectId != null,
                              placeholderText: _projectId == null
                                  ? 'Select project first'
                                  : 'Select',
                              items:
                                  items.map((DropdownOption e) => e.id).toList(),
                              value: _contractId ?? '',
                              itemLabelBuilder: (String id) {
                                return items
                                    .firstWhere(
                                      (DropdownOption e) => e.id == id,
                                      orElse: () => const DropdownOption(
                                        id: '',
                                        name: 'Select',
                                      ),
                                    )
                                    .name;
                              },
                              onChanged: (String id) => setState(
                                () => _contractId = id.isEmpty ? null : id,
                              ),
                              leadingIcon: Icons.description_outlined,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _submitting ? null : _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Data Date *',
                              prefixIcon: Icon(Icons.calendar_month_rounded),
                            ),
                            child: Text(
                              _dataDate == null
                                  ? 'Select date'
                                  : _displayDate.format(_dataDate!),
                              style: TextStyle(
                                color: _dataDate == null
                                    ? palette.mutedText
                                    : scheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _submitting ? null : _pickFile,
                          icon: const Icon(Icons.upload_file_rounded),
                          label: Text(
                            _file == null
                                ? 'Upload P6 Export File *'
                                : _file!.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            'Allowed: ${_kind.fileHint}',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.mutedText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: palette.mutedText,
                                  height: 1.35,
                                ),
                            children: <InlineSpan>[
                              const TextSpan(
                                text:
                                    'Note: Please make sure the uploading P6 data file will be in the given format. Click ',
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                  onTap: _openTemplate,
                                  child: Text(
                                    'here',
                                    style: TextStyle(
                                      color: scheme.secondary,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: scheme.secondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: ' for the file format.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary,
                                  ),
                                )
                              : Text(_kind.actionLabel.toUpperCase()),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
