import 'package:flutter_test/flutter_test.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/data/datasources/project_page_parser.dart';
import 'package:wr_pmis_mobile/src/features/dashboard/domain/entities/project_list_item.dart';

void main() {
  test('parses web #project_table rows', () {
    const String html = '''
<html><body>
<table id="project_table">
  <thead><tr><th>Project ID</th></tr></thead>
  <tbody>
    <tr>
      <td>P01</td>
      <td>Nadiad-Petlad</td>
      <td>Open</td>
      <td>Gauge Conversion</td>
      <td>WR</td>
      <td>14</td>
      <td></td>
      <td>3353400000.00</td>
      <td>2025-12-31</td>
      <td>BRC</td>
      <td>ND-PTD</td>
      <td></td>
      <td class="last-column"><a href="#">edit</a></td>
    </tr>
    <tr>
      <td>P05</td>
      <td>Dahod - Indore New BG lines</td>
      <td>Open</td>
      <td>New Line</td>
      <td>WR</td>
      <td>53</td>
      <td></td>
      <td>4560700000.00</td>
      <td>2029-05-31</td>
      <td>RTM</td>
      <td>DHD-INDB</td>
      <td>Dahod - Indore via Sardarpur, Jhabao &amp; Dhar</td>
      <td></td>
    </tr>
  </tbody>
</table>
</body></html>
''';

    final List<Map<String, dynamic>> rows = ProjectPageParser.parse(html);
    expect(rows, hasLength(2));

    final ProjectListItem p01 = ProjectListItem.fromJson(rows.first);
    expect(p01.projectId, 'P01');
    expect(p01.projectName, 'Nadiad-Petlad');
    expect(p01.projectStatus, 'Open');
    expect(p01.projectTypeName, 'Gauge Conversion');
    expect(p01.railwayZone, 'WR');
    expect(p01.planHeadNumber, '14');
    expect(p01.sanctionedAmount, '3353400000.00');
    expect(p01.sanctionedCompletionDate, '2025-12-31');
    expect(p01.division, 'BRC');
    expect(p01.sections, 'ND-PTD');
    expect(rows.first['project_type_id_fk'], '4');

    final ProjectListItem p05 = ProjectListItem.fromJson(rows[1]);
    expect(p05.projectId, 'P05');
    expect(p05.projectTypeName, 'New Line');
    expect(p05.remarks, 'Dahod - Indore via Sardarpur, Jhabao & Dhar');
    expect(rows[1]['project_type_id_fk'], '1');
  });
}
