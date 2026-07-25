import 'dart:convert';

class UpdateFormSubItem {
  const UpdateFormSubItem({
    required this.formId,
    required this.formName,
    required this.priority,
    this.webFormUrl,
    this.mobileFormUrl,
    this.showInMobile = true,
    this.level2Menus = const <UpdateFormSubItem>[],
  });

  final String formId;
  final String formName;
  final int priority;
  final String? webFormUrl;
  final String? mobileFormUrl;
  final bool showInMobile;
  final List<UpdateFormSubItem> level2Menus;

  factory UpdateFormSubItem.fromJson(Map<String, dynamic> json) {
    return UpdateFormSubItem(
      formId: json['formId']?.toString() ?? '',
      formName: json['formName']?.toString() ?? '',
      priority: int.tryParse(json['priority']?.toString() ?? '') ?? 0,
      webFormUrl: json['webFormUrl']?.toString(),
      mobileFormUrl: json['mobileFormUrl']?.toString(),
      showInMobile: _parseShowInMobile(json['displayInMobile']),
      level2Menus: _parseSubMenus(json['formsSubMenuLevel2']),
    );
  }
}

class UpdateFormItem {
  const UpdateFormItem({
    required this.formId,
    required this.formName,
    required this.priority,
    this.webFormUrl,
    this.mobileFormUrl,
    this.showInMobile = true,
    required this.subMenus,
  });

  final String formId;
  final String formName;
  final int priority;
  final String? webFormUrl;
  final String? mobileFormUrl;
  final bool showInMobile;
  final List<UpdateFormSubItem> subMenus;

  List<UpdateFormSubItem> get orderedSubMenus {
    final List<UpdateFormSubItem> ordered =
        List<UpdateFormSubItem>.from(subMenus)
          ..sort(
            (UpdateFormSubItem a, UpdateFormSubItem b) =>
                a.priority.compareTo(b.priority),
          );
    return ordered;
  }

  bool get hasSubMenus => orderedSubMenus.isNotEmpty;

  factory UpdateFormItem.fromJson(Map<String, dynamic> json) {
    return UpdateFormItem(
      formId: json['formId']?.toString() ?? '',
      formName: json['formName']?.toString() ?? '',
      priority: int.tryParse(json['priority']?.toString() ?? '') ?? 0,
      webFormUrl: json['webFormUrl']?.toString(),
      mobileFormUrl: json['mobileFormUrl']?.toString(),
      showInMobile: _parseShowInMobile(json['displayInMobile']),
      subMenus: _parseSubMenus(json['formsSubMenu']),
    );
  }
}

bool _parseShowInMobile(dynamic value) {
  final String normalized = value?.toString().trim().toLowerCase() ?? '';
  if (normalized.isEmpty) {
    return true;
  }
  return normalized == 'yes' || normalized == 'y' || normalized == 'true';
}

List<UpdateFormSubItem> _parseSubMenus(dynamic raw) {
  if (raw is! List) {
    return const <UpdateFormSubItem>[];
  }
  final List<UpdateFormSubItem> items = <UpdateFormSubItem>[];
  for (final dynamic entry in raw) {
    if (entry is Map) {
      final Map<String, dynamic> map = entry.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );
      items.add(UpdateFormSubItem.fromJson(map));
      continue;
    }
    if (entry is String && entry.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(entry);
        if (decoded is Map) {
          final Map<String, dynamic> map = decoded.map(
            (dynamic key, dynamic value) => MapEntry(key.toString(), value),
          );
          items.add(UpdateFormSubItem.fromJson(map));
        }
      } catch (_) {}
    }
  }
  return items;
}
