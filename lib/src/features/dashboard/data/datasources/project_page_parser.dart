/// Parses the web Update Forms → Projects HTML table (`#project_table`).
class ProjectPageParser {
  const ProjectPageParser._();

  static const List<String> _headers = <String>[
    'project_id',
    'project_name',
    'project_status',
    'project_type_name',
    'railway_zone',
    'plan_head_number',
    'sanctioned_year',
    'sanctioned_amount',
    'sanctioned_commissioning_date',
    'division',
    'sections',
    'remarks',
  ];

  static const Map<String, String> _typeIds = <String, String>{
    'new line': '1',
    'doubling/multitracking': '2',
    'gauge conversion': '4',
    'station redevelopment': '10',
  };

  static List<Map<String, dynamic>> parse(String html) {
    final RegExpMatch? tableMatch = RegExp(
      r'''<table[^>]*id=["']project_table["'][\s\S]*?</table>''',
      caseSensitive: false,
    ).firstMatch(html);
    if (tableMatch == null) {
      return const <Map<String, dynamic>>[];
    }

    final String table = tableMatch.group(0)!;
    final RegExpMatch? tbodyMatch = RegExp(
      r'<tbody[^>]*>([\s\S]*?)</tbody>',
      caseSensitive: false,
    ).firstMatch(table);
    final String body = tbodyMatch?.group(1) ?? '';

    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    for (final RegExpMatch rowMatch in RegExp(
      r'<tr[^>]*>([\s\S]*?)</tr>',
      caseSensitive: false,
    ).allMatches(body)) {
      final List<String> cells = RegExp(
        r'<td[^>]*>([\s\S]*?)</td>',
        caseSensitive: false,
      )
          .allMatches(rowMatch.group(1)!)
          .map((RegExpMatch match) => _text(match.group(1)!))
          .toList();
      if (cells.length < 2 || cells.first.isEmpty) {
        continue;
      }

      final Map<String, dynamic> row = <String, dynamic>{};
      for (int i = 0; i < _headers.length && i < cells.length; i++) {
        final String value = cells[i];
        row[_headers[i]] = value.isEmpty ? null : value;
      }
      final String typeName =
          (row['project_type_name'] ?? '').toString().trim().toLowerCase();
      row['project_type_id_fk'] = _typeIds[typeName];
      rows.add(row);
    }
    return rows;
  }

  static String _text(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
