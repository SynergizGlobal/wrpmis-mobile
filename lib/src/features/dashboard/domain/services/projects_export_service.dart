import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wr_pmis_mobile/src/core/result/failure.dart';
import 'package:wr_pmis_mobile/src/core/result/result.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/repositories/project_repository.dart';

/// Builds a real Excel (.xlsx) from API-012 and saves it to device Files /
/// Downloads (native Save dialog) — not a share-to-apps sheet.
class ProjectsExportService {
  const ProjectsExportService(this._repository);

  final ProjectRepository _repository;

  static final DateFormat _stamp = DateFormat('yyyyMMdd_HHmmss');

  static const List<String> _projectColumns = <String>[
    'project_id',
    'project_name',
    'project_status',
    'plan_head_number',
    'financial_year',
    'railway',
    'pb_item_no',
    'benefits',
    'remarks',
  ];

  static const List<String> _projectHeaders = <String>[
    'Project ID',
    'Project Name',
    'Project Status',
    'Plan Head Number',
    'Financial Year',
    'Railway',
    'PB Item No',
    'Benefits',
    'Remarks',
  ];

  static const List<String> _pinkBookColumns = <String>[
    'project_id',
    'pb_item_no',
    'financial_year',
  ];

  static const List<String> _pinkBookHeaders = <String>[
    'Project ID',
    'PB Item No',
    'Financial Year',
  ];

  Future<Result<String>> exportAndSaveExcel() async {
    final Result<Map<String, dynamic>> result =
        await _repository.exportProjects();
    if (result.isLeft()) {
      return result.fold(
        (Failure failure) => Left(failure),
        (_) => const Left(Failure('Export failed.')),
      );
    }

    final Map<String, dynamic> json = result.getOrElse(
      () => const <String, dynamic>{},
    );

    try {
      final List<Map<String, dynamic>> projects = _asMapList(json['projects']);
      if (projects.isEmpty) {
        return const Left(Failure('No project data available to export.'));
      }

      final List<Map<String, dynamic>> pinkBook =
          _asMapList(json['projectPinkBook']);

      final Uint8List bytes = _buildExcelBytes(
        projects: projects,
        pinkBook: pinkBook,
      );

      final String stamp = _stamp.format(DateTime.now());
      final String fileName = 'project_data_$stamp';

      // Native Save dialog → user picks Files / Downloads location.
      String? savedPath;
      try {
        savedPath = await FileSaver.instance.saveAs(
          name: fileName,
          bytes: bytes,
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      } on MissingPluginException {
        // Hot-reload without rebuild — fall back to direct file write.
        savedPath = await _saveDirectly(fileName, bytes);
      }

      if (savedPath == null || savedPath.trim().isEmpty) {
        // User cancelled the save dialog.
        return const Left(Failure('Export cancelled. File was not saved.'));
      }

      // Some platforms return "Unknown" when save succeeds via picker.
      final String location = savedPath.trim().toLowerCase() == 'unknown'
          ? 'Files / Downloads'
          : savedPath.trim();

      return Right(
        'Excel downloaded (${projects.length} project(s)).\nSaved to: $location',
      );
    } on MissingPluginException {
      return const Left(
        Failure(
          'Export plugin is not ready. Fully stop the app and run again '
          '(Stop → Run), then try Export.',
        ),
      );
    } catch (error) {
      return Left(Failure(error.toString()));
    }
  }

  Future<String> _saveDirectly(String fileName, Uint8List bytes) async {
    Directory dir;
    try {
      dir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }
    final File file = File('${dir.path}/$fileName.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Uint8List _buildExcelBytes({
    required List<Map<String, dynamic>> projects,
    required List<Map<String, dynamic>> pinkBook,
  }) {
    final Excel workbook = Excel.createExcel();
    final String defaultSheet = workbook.getDefaultSheet() ?? 'Sheet1';
    workbook.rename(defaultSheet, 'Projects');

    _writeSheet(
      workbook: workbook,
      sheetName: 'Projects',
      headers: _projectHeaders,
      columns: _projectColumns,
      rows: projects,
    );

    if (pinkBook.isNotEmpty) {
      _writeSheet(
        workbook: workbook,
        sheetName: 'Pink Book',
        headers: _pinkBookHeaders,
        columns: _pinkBookColumns,
        rows: pinkBook,
      );
    }

    final List<int>? bytes = workbook.save();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Unable to build Excel file.');
    }
    return Uint8List.fromList(bytes);
  }

  void _writeSheet({
    required Excel workbook,
    required String sheetName,
    required List<String> headers,
    required List<String> columns,
    required List<Map<String, dynamic>> rows,
  }) {
    final Sheet sheet = workbook[sheetName];
    sheet.appendRow(
      headers.map((String h) => TextCellValue(h)).toList(growable: false),
    );
    for (final Map<String, dynamic> row in rows) {
      sheet.appendRow(
        columns
            .map((String key) => TextCellValue(_cellText(row[key])))
            .toList(growable: false),
      );
    }
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value
        .whereType<Map>()
        .map(
          (Map row) => row.map(
            (dynamic key, dynamic value) => MapEntry(key.toString(), value),
          ),
        )
        .toList();
  }

  String _cellText(dynamic value) {
    if (value == null) {
      return '';
    }
    final String text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }
    return text;
  }
}
