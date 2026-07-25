class ApiHosts {
  const ApiHosts._();

  /// QA base URL — set when provided.
  static const String qaBaseUrl = 'http://203.153.40.44:90/wrpmis/';

  /// Production WR PMIS.
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
