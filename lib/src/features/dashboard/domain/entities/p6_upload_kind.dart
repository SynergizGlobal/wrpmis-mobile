import 'package:wr_pmis_mobile/src/core/config/environment.dart';
import 'package:wr_pmis_mobile/src/core/constants/api_constants.dart';

/// P6 New Data upload kinds (web: Baseline / Revised Baseline / Update).
enum P6UploadKind {
  baseline,
  revisedBaseline,
  update;

  String get label => switch (this) {
        P6UploadKind.baseline => 'Baseline',
        P6UploadKind.revisedBaseline => 'Revised Baseline',
        P6UploadKind.update => 'Update',
      };

  String get actionLabel => switch (this) {
        P6UploadKind.baseline => 'Upload',
        P6UploadKind.revisedBaseline => 'Update',
        P6UploadKind.update => 'Update',
      };

  String get apiPath => switch (this) {
        P6UploadKind.baseline => ApiConstants.p6UploadBaselinePath,
        P6UploadKind.revisedBaseline => ApiConstants.p6RevisedActivitiesPath,
        P6UploadKind.update => ApiConstants.p6UpdateActivitiesPath,
      };

  String get templateFileName => switch (this) {
        P6UploadKind.baseline => ApiConstants.p6BaselineTemplateFile,
        P6UploadKind.revisedBaseline => ApiConstants.p6RevisedTemplateFile,
        P6UploadKind.update => ApiConstants.p6UpdateTemplateFile,
      };

  /// Absolute URL for the static template (same as web "Click here").
  String get templateUrl => '${Environment.wrBaseUrl}$templateFileName';

  /// Allowed file extensions for the file picker.
  List<String> get allowedExtensions => switch (this) {
        P6UploadKind.baseline => const <String>['xls', 'xlsx'],
        P6UploadKind.revisedBaseline => const <String>['xls', 'xlsx'],
        P6UploadKind.update => const <String>['xer'],
      };

  String get fileHint => switch (this) {
        P6UploadKind.baseline => 'Excel (.xls / .xlsx)',
        P6UploadKind.revisedBaseline => 'Excel (.xls / .xlsx)',
        P6UploadKind.update => 'P6 export (.xer)',
      };
}
