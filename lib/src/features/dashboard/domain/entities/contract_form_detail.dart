import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_form_data.dart';

class ContractFormOptions {
  const ContractFormOptions({
    this.projects = const <DropdownOption>[],
    this.departments = const <DropdownOption>[],
    this.contractTypes = const <DropdownOption>[],
    this.contractors = const <DropdownOption>[],
    this.costUnits = const <DropdownOption>[],
    this.fileTypes = const <DropdownOption>[],
  });

  final List<DropdownOption> projects;
  final List<DropdownOption> departments;
  final List<DropdownOption> contractTypes;
  final List<DropdownOption> contractors;
  final List<DropdownOption> costUnits;
  final List<DropdownOption> fileTypes;
}

class ContractExecutiveRow {
  const ContractExecutiveRow({
    this.departmentId,
    this.executiveIds = const <String>[],
  });

  final String? departmentId;
  final List<String> executiveIds;
}

class ContractRevisionRow {
  const ContractRevisionRow({
    this.revisionNo,
    this.estimatedCost,
    this.plannedAward,
    this.plannedCompletion,
    this.noticeInvitingTender,
    this.tenderOpeningDate,
    this.technicalEvalApproval,
    this.financialEvalApproval,
    this.remarks,
  });

  final String? revisionNo;
  final String? estimatedCost;
  final String? plannedAward;
  final String? plannedCompletion;
  final String? noticeInvitingTender;
  final String? tenderOpeningDate;
  final String? technicalEvalApproval;
  final String? financialEvalApproval;
  final String? remarks;
}

class ContractDocumentRow {
  const ContractDocumentRow({
    this.fileType,
    this.name,
    this.fileId,
  });

  final String? fileType;
  final String? name;
  final String? fileId;
}

class ContractFormDetail {
  const ContractFormDetail({
    this.contractId,
    this.projectId,
    this.projectLabel,
    this.hodUserId,
    this.dyHodUserId,
    this.contractDepartment,
    this.bankFunded,
    this.awarded,
    this.shortName,
    this.contractName,
    this.contractType,
    this.contractorId,
    this.contractCode,
    this.scope,
    this.loaLetterNumber,
    this.loaDate,
    this.caNo,
    this.caDate,
    this.dateOfStart,
    this.originalDoc,
    this.targetDoc,
    this.awardedCost,
    this.awardedCostUnit,
    this.estimatedCost,
    this.estimatedCostUnit,
    this.workStatus,
    this.plannedDateOfAward,
    this.plannedDateOfCompletion,
    this.noticeInvitingTender,
    this.tenderOpeningDate,
    this.technicalEvalSubmission,
    this.financialEvalSubmission,
    this.bgRequired,
    this.insuranceRequired,
    this.milestoneRequired,
    this.revisionRequired,
    this.keyPersonnelRequired,
    this.gstInclusive,
    this.gstRate,
    this.executives = const <ContractExecutiveRow>[],
    this.revisions = const <ContractRevisionRow>[],
    this.documents = const <ContractDocumentRow>[],
    this.options = const ContractFormOptions(),
  });

  final String? contractId;
  final String? projectId;
  final String? projectLabel;
  final String? hodUserId;
  final String? dyHodUserId;
  final String? contractDepartment;
  final String? bankFunded;
  final String? awarded;
  final String? shortName;
  final String? contractName;
  final String? contractType;
  final String? contractorId;
  final String? contractCode;
  final String? scope;
  final String? loaLetterNumber;
  final String? loaDate;
  final String? caNo;
  final String? caDate;
  final String? dateOfStart;
  final String? originalDoc;
  final String? targetDoc;
  final String? awardedCost;
  final String? awardedCostUnit;
  final String? estimatedCost;
  final String? estimatedCostUnit;
  final String? workStatus;
  final String? plannedDateOfAward;
  final String? plannedDateOfCompletion;
  final String? noticeInvitingTender;
  final String? tenderOpeningDate;
  final String? technicalEvalSubmission;
  final String? financialEvalSubmission;
  final String? bgRequired;
  final String? insuranceRequired;
  final String? milestoneRequired;
  final String? revisionRequired;
  final String? keyPersonnelRequired;
  final String? gstInclusive;
  final String? gstRate;
  final List<ContractExecutiveRow> executives;
  final List<ContractRevisionRow> revisions;
  final List<ContractDocumentRow> documents;
  final ContractFormOptions options;
}
