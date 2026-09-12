import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_global_loader.dart';
import 'package:wr_pmis_mobile/src/core/widgets/app_select_sheet_field.dart';
import 'package:wr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/contractor_repository.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/contractor_form_detail.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/presentation/contracts/providers/contractor_providers.dart';

/// Add / Update Contractor.
class ContractorFormPage extends ConsumerStatefulWidget {
  const ContractorFormPage({super.key, this.contractorId});

  static const String routeName = 'contractor-form';
  static const String routePath = '/contractor-form';

  final String? contractorId;

  @override
  ConsumerState<ContractorFormPage> createState() => _ContractorFormPageState();
}

class _ContractorFormPageState extends ConsumerState<ContractorFormPage> {
  static const double _labelSlotHeight = 40;
  static const EdgeInsets _controlPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 14,
  );

  final TextEditingController _pan = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _primaryContact = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _gst = TextEditingController();
  final TextEditingController _bankName = TextEditingController();
  final TextEditingController _ifsc = TextEditingController();
  final TextEditingController _account = TextEditingController();
  final TextEditingController _bankAddress = TextEditingController();
  final TextEditingController _remarks = TextEditingController();

  bool _prefilled = false;
  bool _saving = false;
  String? _specialization;

  bool get _isEdit =>
      widget.contractorId != null && widget.contractorId!.isNotEmpty;

  @override
  void dispose() {
    _pan.dispose();
    _name.dispose();
    _address.dispose();
    _primaryContact.dispose();
    _phone.dispose();
    _email.dispose();
    _gst.dispose();
    _bankName.dispose();
    _ifsc.dispose();
    _account.dispose();
    _bankAddress.dispose();
    _remarks.dispose();
    super.dispose();
  }

  void _prefill(ContractorFormDetail detail) {
    _prefilled = true;
    _pan.text = detail.panNumber ?? '';
    _name.text = detail.contractorName ?? '';
    _address.text = detail.address ?? '';
    _primaryContact.text = detail.primaryContact ?? '';
    _phone.text = detail.phoneNumber ?? '';
    _email.text = detail.email ?? '';
    _gst.text = detail.gstNumber ?? '';
    _bankName.text = detail.bankName ?? '';
    _ifsc.text = detail.ifscCode ?? '';
    _account.text = detail.accountNumber ?? '';
    _bankAddress.text = detail.bankAddress ?? '';
    _remarks.text = detail.remarks ?? '';
    _specialization = detail.specialization;
  }

  ContractorFormDetail _detailFromForm(ContractorFormDetail seed) {
    return ContractorFormDetail(
      contractorId: widget.contractorId,
      panNumber: _pan.text.trim(),
      specialization: _specialization,
      contractorName: _name.text.trim(),
      address: _address.text.trim(),
      primaryContact: _primaryContact.text.trim(),
      phoneNumber: _phone.text.trim(),
      email: _email.text.trim(),
      gstNumber: _gst.text.trim(),
      bankName: _bankName.text.trim(),
      ifscCode: _ifsc.text.trim(),
      accountNumber: _account.text.trim(),
      bankAddress: _bankAddress.text.trim(),
      remarks: _remarks.text.trim(),
      specializations: seed.specializations,
    );
  }

  String? _validate() {
    if (_pan.text.trim().isEmpty) {
      return 'PAN Number is required.';
    }
    if (_specialization == null || _specialization!.isEmpty) {
      return 'Specialization is required.';
    }
    if (_name.text.trim().isEmpty) {
      return 'Contractor Name is required.';
    }
    if (_isEdit) {
      if (_primaryContact.text.trim().isEmpty) {
        return 'Primary Contact is required.';
      }
      if (_phone.text.trim().isEmpty) {
        return 'Phone Number is required.';
      }
      if (_gst.text.trim().isEmpty) {
        return 'GST Number is required.';
      }
    }
    return null;
  }

  Future<void> _save(ContractorFormDetail seed) async {
    final String? error = _validate();
    if (error != null) {
      await GlobalDialog.info(error, title: _isEdit ? 'Update' : 'Add');
      return;
    }
    if (!_isEdit) {
      final panResult = await ref.read(contractorRepositoryProvider).isPanTaken(
            _pan.text.trim(),
          );
      final bool taken = panResult.fold((_) => false, (bool v) => v);
      if (taken) {
        await GlobalDialog.info(
          'PAN number already exist',
          title: 'Add',
        );
        return;
      }
    }

    setState(() => _saving = true);
    final result = await ref
        .read(contractorRepositoryProvider)
        .saveContractor(_detailFromForm(seed));
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    result.fold(
      (failure) => GlobalDialog.error(failure.message),
      (String message) async {
        await GlobalDialog.info(message, title: _isEdit ? 'Update' : 'Add');
        if (mounted) {
          context.pop(true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ContractorFormDetail> async =
        ref.watch(contractorFormProvider(widget.contractorId ?? ''));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'Update Contractor (${widget.contractorId})'
              : 'Add Contractor',
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
                  onPressed: () => ref.invalidate(
                    contractorFormProvider(widget.contractorId ?? ''),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (ContractorFormDetail detail) {
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

  Widget _body(ContractorFormDetail detail) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: <Widget>[
                  _grid(<Widget>[
                    _isEdit
                        ? _readOnly('PAN Number *', _pan.text)
                        : _text('PAN Number *', _pan),
                    _isEdit
                        ? _readOnly(
                            'Specialization *',
                            _specialization ?? '',
                          )
                        : _dropdown(
                            'Specialization *',
                            detail.specializations,
                            _specialization,
                            (String? v) => setState(() => _specialization = v),
                          ),
                  ]),
                  const SizedBox(height: 10),
                  _isEdit
                      ? _readOnly('Contractor Name *', _name.text)
                      : _text('Contractor Name *', _name),
                  const SizedBox(height: 10),
                  _text('Address', _address, maxLines: 3),
                  const SizedBox(height: 10),
                  _grid(<Widget>[
                    _text(_isEdit ? 'Primary Contact *' : 'Primary Contact', _primaryContact),
                    _text(_isEdit ? 'Phone Number *' : 'Phone Number', _phone),
                    _text('Email Address', _email),
                    _text(_isEdit ? 'GST Number *' : 'GST Number', _gst),
                    _text('Bank Name', _bankName),
                    _text('IFSC Code', _ifsc),
                    _text('Account No', _account),
                  ]),
                  const SizedBox(height: 10),
                  _text('Bank Address', _bankAddress, maxLines: 3),
                  const SizedBox(height: 10),
                  _text('Remarks', _remarks, maxLines: 3),
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
                        onPressed: _saving ? null : () => _save(detail),
                        child: Text(_isEdit ? 'UPDATE' : 'ADD'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => context.pop(),
                        child: const Text('CANCEL'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_saving) const AppGlobalLoader(),
      ],
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

  InputDecoration _controlDecoration({bool enabled = true}) {
    return InputDecoration(
      filled: true,
      enabled: enabled,
      isDense: true,
      contentPadding: _controlPadding,
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

  Widget _readOnly(String label, String value) {
    return _labeled(
      label,
      InputDecorator(
        decoration: _controlDecoration(enabled: false),
        child: Text(value.isEmpty ? '—' : value),
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

  Widget _dropdown(
    String label,
    List<DropdownOption> options,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    final List<DropdownOption> items = <DropdownOption>[
      const DropdownOption(id: '', name: 'Select'),
      ...options,
    ];
    return _labeled(
      label,
      AppSelectSheetField<String>(
        label: '',
        title: label,
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
}
