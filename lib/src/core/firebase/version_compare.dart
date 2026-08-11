class VersionCompare {
  const VersionCompare._();

  /// Returns negative if [a] < [b], zero if equal, positive if [a] > [b].
  static int compare(String a, String b) {
    final List<int> left = _parts(a);
    final List<int> right = _parts(b);
    final int length = left.length > right.length ? left.length : right.length;
    for (int i = 0; i < length; i++) {
      final int l = i < left.length ? left[i] : 0;
      final int r = i < right.length ? right[i] : 0;
      if (l != r) {
        return l.compareTo(r);
      }
    }
    return 0;
  }

  static bool isLower(String a, String b) => compare(a, b) < 0;

  static List<int> _parts(String version) {
    final String cleaned = version.trim().split('+').first.split('-').first;
    if (cleaned.isEmpty) {
      return <int>[0];
    }
    return cleaned
        .split('.')
        .map((String part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList(growable: false);
  }
}
