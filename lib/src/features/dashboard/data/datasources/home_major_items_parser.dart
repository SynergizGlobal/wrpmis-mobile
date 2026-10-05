import 'dart:convert';

/// Pulls "Status of Major Items" rows out of the logged-in home page.
///
/// `GET /api/v1/projects/list` and `GET /project` (`#project_table`) do not
/// carry Item / Scope / Completed / Progress / TDC. That table is rendered
/// from `/home` (embedded JSON or HTML, plus the GET urls in its scripts).
class HomeMajorItemsParser {
  const HomeMajorItemsParser._();

  static const List<String> _itemKeys = <String>[
    'structure_type',
    'structureType',
    'item',
    'item_name',
    'activity_name',
  ];

  static const List<String> _measureKeys = <String>[
    'scope',
    'completed',
    'physical_progress',
    'physicalProgress',
    'financial_progress',
    'progress',
    'revised_target_date',
    'tdc',
  ];

  static HomeMajorItemsParse parse(String html) {
    if (_isLoginPage(html)) {
      return const HomeMajorItemsParse(
        rows: <Map<String, dynamic>>[],
        getPaths: <String>[],
      );
    }

    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
      ..._rowsFromTables(html),
      ..._rowsFromEmbeddedJson(html),
    ];
    return HomeMajorItemsParse(
      rows: rows,
      getPaths: _getPaths(html),
    );
  }

  static bool looksLikeMajorItem(Map<String, dynamic> row) {
    bool present(dynamic value) {
      if (value == null) {
        return false;
      }
      final String text = value.toString().trim();
      return text.isNotEmpty && text.toLowerCase() != 'null';
    }

    final bool hasItem = _itemKeys.any((String key) => present(row[key]));
    final bool hasMeasure =
        _measureKeys.any((String key) => present(row[key]));
    return hasItem && hasMeasure;
  }

  static bool _isLoginPage(String html) {
    return html.toLowerCase().contains('<title>login</title>');
  }

  static List<Map<String, dynamic>> _rowsFromTables(String html) {
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    final RegExp table = RegExp(
      r'<table\b[^>]*>[\s\S]*?</table>',
      caseSensitive: false,
    );
    for (final RegExpMatch match in table.allMatches(html)) {
      final String block = match.group(0)!;
      final List<List<String>> grid = _grid(block);
      if (grid.length < 2) {
        continue;
      }
      final List<String> header = grid.first
          .map((String cell) => cell.trim().toLowerCase())
          .toList();
      if (!_isMajorItemHeader(header)) {
        continue;
      }
      final String projectName = _projectNameBefore(
        html,
        match.start,
      );
      final int itemIndex = _column(header, 'item');
      final int scopeIndex = _column(header, 'scope');
      final int completedIndex = _column(header, 'completed');
      final int progressIndex = _column(header, 'progress');
      final int tdcIndex = _column(header, 'tdc');
      for (final List<String> cells in grid.skip(1)) {
        String cell(int index) =>
            index >= 0 && index < cells.length ? cells[index].trim() : '';
        final String item = cell(itemIndex);
        if (item.isEmpty) {
          continue;
        }
        rows.add(<String, dynamic>{
          if (projectName.isNotEmpty) 'project_name': projectName,
          'structure_type': item,
          'scope': cell(scopeIndex),
          'completed': cell(completedIndex),
          'physical_progress': cell(progressIndex),
          'revised_target_date': cell(tdcIndex),
        });
      }
    }
    return rows;
  }

  static bool _isMajorItemHeader(List<String> header) {
    bool has(String name) => header.any((String cell) => cell == name);
    return has('item') &&
        has('scope') &&
        has('completed') &&
        has('progress') &&
        has('tdc');
  }

  static int _column(List<String> header, String name) {
    return header.indexWhere((String cell) => cell == name);
  }

  static String _projectNameBefore(String html, int tableStart) {
    final int from = tableStart > 800 ? tableStart - 800 : 0;
    final String window = html.substring(from, tableStart);
    final RegExp heading = RegExp(
      r'Status of Major Items in\s+([^<]+)',
      caseSensitive: false,
    );
    final Iterable<RegExpMatch> matches = heading.allMatches(window);
    if (matches.isEmpty) {
      final RegExp dataName = RegExp(
        r'''data-project(?:-name)?=["']([^"']+)["']''',
        caseSensitive: false,
      );
      final Iterable<RegExpMatch> dataMatches = dataName.allMatches(window);
      if (dataMatches.isEmpty) {
        return '';
      }
      return _plain(dataMatches.last.group(1) ?? '');
    }
    return _plain(matches.last.group(1) ?? '');
  }

  static List<List<String>> _grid(String tableHtml) {
    final List<List<String>> rows = <List<String>>[];
    for (final RegExpMatch row in RegExp(
      r'<tr\b[^>]*>([\s\S]*?)</tr>',
      caseSensitive: false,
    ).allMatches(tableHtml)) {
      final List<String> cells = RegExp(
        r'<t[hd]\b[^>]*>([\s\S]*?)</t[hd]>',
        caseSensitive: false,
      )
          .allMatches(row.group(1)!)
          .map((RegExpMatch match) => _plain(match.group(1) ?? ''))
          .toList();
      if (cells.isNotEmpty) {
        rows.add(cells);
      }
    }
    return rows;
  }

  static List<Map<String, dynamic>> _rowsFromEmbeddedJson(String html) {
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    for (final RegExpMatch script in RegExp(
      r'<script\b[^>]*>([\s\S]*?)</script>',
      caseSensitive: false,
    ).allMatches(html)) {
      final String body = script.group(1) ?? '';
      for (final String blob in _balancedArrays(body)) {
        if (blob.length > 500000) {
          continue;
        }
        final dynamic decoded = _tryDecode(blob);
        rows.addAll(_mapsFromDecoded(decoded));
      }
    }
    return rows.where(looksLikeMajorItem).toList();
  }

  static List<Map<String, dynamic>> _mapsFromDecoded(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (Map entry) => entry.map(
              (dynamic key, dynamic value) => MapEntry(key.toString(), value),
            ),
          )
          .where(looksLikeMajorItem)
          .toList();
    }
    if (decoded is Map) {
      final Map<String, dynamic> map = decoded.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );
      final List<Map<String, dynamic>> nested = <Map<String, dynamic>>[];
      for (final dynamic value in map.values) {
        nested.addAll(_mapsFromDecoded(value));
      }
      if (looksLikeMajorItem(map)) {
        nested.add(map);
      }
      return nested;
    }
    return const <Map<String, dynamic>>[];
  }

  static dynamic _tryDecode(String blob) {
    try {
      return jsonDecode(blob);
    } catch (_) {
      return null;
    }
  }

  static Iterable<String> _balancedArrays(String source) sync* {
    for (int i = 0; i < source.length; i++) {
      if (source.codeUnitAt(i) != 91) {
        continue;
      }
      int depth = 0;
      bool inString = false;
      String quote = '';
      for (int j = i; j < source.length; j++) {
        final int unit = source.codeUnitAt(j);
        if (inString) {
          if (unit == quote.codeUnitAt(0) &&
              (j == 0 || source.codeUnitAt(j - 1) != 92)) {
            inString = false;
          }
          continue;
        }
        if (unit == 34 || unit == 39) {
          inString = true;
          quote = source[j];
          continue;
        }
        if (unit == 91) {
          depth++;
        } else if (unit == 93) {
          depth--;
          if (depth == 0) {
            yield source.substring(i, j + 1);
            break;
          }
        }
      }
    }
  }

  /// GET urls the home page itself calls. Skips approve/reject and other writes.
  static List<String> _getPaths(String html) {
    final List<String> paths = <String>[];
    final Set<String> seen = <String>{};
    for (final RegExpMatch script in RegExp(
      r'<script\b[^>]*>([\s\S]*?)</script>',
      caseSensitive: false,
    ).allMatches(html)) {
      final String body = script.group(1) ?? '';
      for (final RegExpMatch match in RegExp(
        r'''\$\.(?:get|getJSON)\s*\(\s*['"]([^'"]+)['"]''',
      ).allMatches(body)) {
        _addGetPath(paths, seen, match.group(1)!);
      }
      for (final RegExpMatch match in RegExp(
        r'''url\s*:\s*['"]([^'"]+)['"]''',
      ).allMatches(body)) {
        final int at = match.start;
        final String around = body.substring(
          at,
          at + 160 > body.length ? body.length : at + 160,
        );
        if (_isPostCall(around)) {
          continue;
        }
        _addGetPath(paths, seen, match.group(1)!);
      }
    }
    return paths;
  }

  static void _addGetPath(
    List<String> paths,
    Set<String> seen,
    String raw,
  ) {
    final String trimmed = raw.trim();
    if (_isWritePath(trimmed)) {
      return;
    }
    final String? path = _normalizePath(trimmed);
    if (path == null || !seen.add(path)) {
      return;
    }
    paths.add(path);
  }

  static bool _isWritePath(String value) {
    final String lower = value.toLowerCase();
    const List<String> blocked = <String>[
      'approve',
      'reject',
      'update',
      'delete',
      'remove',
      'insert',
      'upload',
      'save',
      'add-',
      'add_',
      '/add',
      'login',
      'logout',
      'password',
    ];
    return blocked.any(lower.contains);
  }

  static bool _isPostCall(String around) {
    final String lower = around.toLowerCase();
    return lower.contains("type: 'post'") ||
        lower.contains('type: "post"') ||
        lower.contains('type:"post"') ||
        lower.contains("method: 'post'") ||
        lower.contains('method: "post"') ||
        lower.contains('method:"post"');
  }

  static String? _normalizePath(String raw) {
    if (raw.contains(r'${') || raw.contains('+') || raw.contains(' ')) {
      return null;
    }
    final Uri? uri = Uri.tryParse(raw);
    if (uri == null) {
      return null;
    }
    if (uri.hasScheme && uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }
    String path = uri.hasScheme ? uri.path : raw;
    if (path.isEmpty || !path.contains('/')) {
      return null;
    }
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    final String query = uri.hasQuery ? '?${uri.query}' : '';
    final String full = '$path$query';
    final String lower = full.toLowerCase();
    const List<String> hints = <String>[
      'major',
      'item',
      'progress',
      'dashboard',
      'project',
      'structure',
      'status',
      'tdc',
      'work',
    ];
    if (!hints.any(lower.contains)) {
      return null;
    }
    return full;
  }

  static String _plain(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class HomeMajorItemsParse {
  const HomeMajorItemsParse({
    required this.rows,
    required this.getPaths,
  });

  final List<Map<String, dynamic>> rows;
  final List<String> getPaths;
}
