/// Prefill + submit model for web Update Structure Form
/// (`POST /get-structure-form` → `POST /update-structure-form`).
class StructureFormEditDetail {
  const StructureFormEditDetail({
    required this.structureId,
    this.projectIdFk,
    this.projectLabel,
    this.structureTypeFk,
    this.structureName,
    this.structure,
    this.workStatusFk,
    this.existingWorkStatusFk,
    this.targetDate,
    this.estimatedCost,
    this.estimatedCostUnits,
    this.remarks,
    this.latitude,
    this.longitude,
    this.constructionStartDate,
    this.revisedCompletion,
    this.commissioningDate,
    this.actualCompletionDate,
    this.completionCost,
    this.completionCostUnits,
    this.contractRows = const <StructureFormContractRow>[],
    this.detailRows = const <StructureFormDetailRow>[],
    this.documentRows = const <StructureFormDocumentRow>[],
    this.projects = const <StructureFormOption>[],
    this.structureTypes = const <StructureFormOption>[],
    this.workStatuses = const <StructureFormOption>[],
  });

  final String structureId;
  final String? projectIdFk;
  final String? projectLabel;
  final String? structureTypeFk;
  final String? structureName;
  final String? structure;
  final String? workStatusFk;
  final String? existingWorkStatusFk;
  final String? targetDate;
  final String? estimatedCost;
  final String? estimatedCostUnits;
  final String? remarks;
  final String? latitude;
  final String? longitude;
  final String? constructionStartDate;
  final String? revisedCompletion;
  final String? commissioningDate;
  final String? actualCompletionDate;
  final String? completionCost;
  final String? completionCostUnits;
  final List<StructureFormContractRow> contractRows;
  final List<StructureFormDetailRow> detailRows;
  final List<StructureFormDocumentRow> documentRows;
  final List<StructureFormOption> projects;
  final List<StructureFormOption> structureTypes;
  final List<StructureFormOption> workStatuses;
}

class StructureFormOption {
  const StructureFormOption({required this.id, required this.name});

  final String id;
  final String name;
}

class StructureFormContractRow {
  const StructureFormContractRow({
    this.contractIdFk = '',
    this.executiveIds = const <String>[],
  });

  final String contractIdFk;
  final List<String> executiveIds;
}

class StructureFormDetailRow {
  const StructureFormDetailRow({this.detail = '', this.value = ''});

  final String detail;
  final String value;
}

class StructureFormDocumentRow {
  const StructureFormDocumentRow({
    this.fileType = '',
    this.name = '',
    this.fileId = '',
    this.existingFileName = '',
  });

  final String fileType;
  final String name;
  final String fileId;
  final String existingFileName;
}
