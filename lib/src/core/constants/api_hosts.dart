class ApiHosts {
  const ApiHosts._();

  /// QA WR PMIS (`/wrpmis_qa/`).
  static const String qaBaseUrl = 'http://203.153.40.44:90/wrpmis_qa/';

  /// Production WR PMIS (`/wrpmis/`).
  static const String prodBaseUrl = 'http://203.153.40.44:90/wrpmis/';

  static Uri originUriFor(String baseUrl) {
    final Uri parsed = Uri.parse(baseUrl);
    return Uri(
      scheme: parsed.scheme,
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
    );
  }
}
