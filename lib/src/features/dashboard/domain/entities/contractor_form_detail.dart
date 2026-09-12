import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

class ContractorFormDetail {
  const ContractorFormDetail({
    this.contractorId,
    this.panNumber,
    this.specialization,
    this.contractorName,
    this.address,
    this.primaryContact,
    this.phoneNumber,
    this.email,
    this.gstNumber,
    this.bankName,
    this.ifscCode,
    this.accountNumber,
    this.bankAddress,
    this.remarks,
    this.specializations = const <DropdownOption>[],
  });

  final String? contractorId;
  final String? panNumber;
  final String? specialization;
  final String? contractorName;
  final String? address;
  final String? primaryContact;
  final String? phoneNumber;
  final String? email;
  final String? gstNumber;
  final String? bankName;
  final String? ifscCode;
  final String? accountNumber;
  final String? bankAddress;
  final String? remarks;
  final List<DropdownOption> specializations;

  Map<String, dynamic> toSubmitMap() {
    return <String, dynamic>{
      if (contractorId != null && contractorId!.isNotEmpty)
        'contractor_id': contractorId,
      'pan_number': panNumber ?? '',
      'contractor_specilization_fk': specialization ?? '',
      'contractor_name': contractorName ?? '',
      'address': address ?? '',
      'primary_contact_name': primaryContact ?? '',
      'phone_number': phoneNumber ?? '',
      'email_id': email ?? '',
      'gst_number': gstNumber ?? '',
      'bank_name': bankName ?? '',
      'ifsc_code': ifscCode ?? '',
      'account_number': accountNumber ?? '',
      'bank_address': bankAddress ?? '',
      'remarks': remarks ?? '',
    };
  }
}
