import 'package:flutter_test/flutter_test.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/home_major_items_parser.dart';

void main() {
  test('reads the major-items table and skips write urls', () {
    const String html = '''
<html><body>
<h2>Status of Major Items in Nadiad-Petlad</h2>
<table>
  <tr><th>Item</th><th>Scope</th><th>Completed</th><th>Progress</th><th>TDC</th></tr>
  <tr><td>Earthwork Cutting</td><td>39,295 CuM</td><td>3,240 CuM</td><td>8.25%</td><td>2027-01-10</td></tr>
</table>
<script>
  var extra = [{"project_name":"Petlad-Bhadran","structure_type":"Blanketing","scope":"193811","unit":"CuM","completed":"0","physical_progress":"0.00","revised_target_date":"2027-03-31"}];
  \$.get('/ajax/getProjectMajorItems', function () {});
  \$.ajax({ url: '/ajax/approveActivityProgress', type: 'POST' });
  \$.get('/ajax/getSomethingUnrelated');
</script>
</body></html>
''';

    final HomeMajorItemsParse parsed = HomeMajorItemsParser.parse(html);

    expect(parsed.rows, hasLength(2));
    expect(parsed.rows.first['project_name'], 'Nadiad-Petlad');
    expect(parsed.rows.first['structure_type'], 'Earthwork Cutting');
    expect(parsed.rows.first['scope'], '39,295 CuM');
    expect(parsed.rows.last['project_name'], 'Petlad-Bhadran');
    expect(parsed.getPaths, <String>['/ajax/getProjectMajorItems']);
  });

  test('ignores the login page', () {
    const String html = '<html><head><title>Login</title></head></html>';
    final HomeMajorItemsParse parsed = HomeMajorItemsParser.parse(html);
    expect(parsed.rows, isEmpty);
    expect(parsed.getPaths, isEmpty);
  });
}
