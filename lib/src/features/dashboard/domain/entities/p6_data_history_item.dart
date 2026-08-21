/// One row from P6 Data History (`/ajax/getP6NewActivityData`).
class P6DataHistoryItem {
  const P6DataHistoryItem({
    this.contractId,
    this.dataType,
    this.dataDate,
    this.status,
    this.uploadedFile,
    this.uploadedBy,
    this.uploadedDate,
  });

  final String? contractId;
  final String? dataType;
  final String? dataDate;
  final String? status;
  final String? uploadedFile;
  final String? uploadedBy;
  final String? uploadedDate;

  /// Basename of [uploadedFile] for compact table display.
  String get uploadedFileDisplay {
    final String path = (uploadedFile ?? '').trim();
    if (path.isEmpty) return '-';
    final String normalized = path.replaceAll('\\', '/');
    final int slash = normalized.lastIndexOf('/');
    if (slash < 0 || slash >= normalized.length - 1) return path;
    return normalized.substring(slash + 1);
  }

  factory P6DataHistoryItem.fromJson(Map<String, dynamic> json) {
    return P6DataHistoryItem(
      contractId: _n(json['contract_id_fk'] ?? json['contract_id']),
      dataType: _n(json['upload_type'] ?? json['data_type'] ?? json['dataType']),
      dataDate: _n(json['data_date'] ?? json['dataDate']),
      status: _n(
        json['soft_delete_status_fk'] ??
            json['status_fk'] ??
            json['status'],
      ),
      uploadedFile: _n(json['p6_file_path'] ?? json['uploaded_file']),
      uploadedBy: _n(
        json['user_name'] ??
            json['uploaded_by_user_id_fk'] ??
            json['uploaded_by'],
      ),
      uploadedDate: _n(json['uploaded_date'] ?? json['uploadedDate']),
    );
  }

  bool matchesSearch(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return <String?>[
      contractId,
      dataType,
      dataDate,
      status,
      uploadedFile,
      uploadedFileDisplay,
      uploadedBy,
      uploadedDate,
    ].any((String? v) => (v ?? '').toLowerCase().contains(q));
  }

  static String? _n(dynamic v) {
    if (v == null) return null;
    final String t = v.toString().trim();
    return t.isEmpty || t.toLowerCase() == 'null' ? null : t;
  }
}

class P6DataHistoryListResult {
  const P6DataHistoryListResult({
    required this.items,
    required this.totalRecords,
    required this.filteredRecords,
  });

  final List<P6DataHistoryItem> items;
  final int totalRecords;
  final int filteredRecords;
}
