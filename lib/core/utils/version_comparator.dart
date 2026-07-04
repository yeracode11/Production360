/// Сравнение semver-подобных версий (`1.0.1` vs `1.0.0`).
int compareAppVersions(String a, String b) {
  final pa = _parseParts(a);
  final pb = _parseParts(b);
  final length = pa.length > pb.length ? pa.length : pb.length;

  for (var i = 0; i < length; i++) {
    final left = i < pa.length ? pa[i] : 0;
    final right = i < pb.length ? pb[i] : 0;
    if (left != right) {
      return left.compareTo(right);
    }
  }
  return 0;
}

bool isAppVersionLower(String current, String minimum) {
  return compareAppVersions(current, minimum) < 0;
}

List<int> _parseParts(String value) {
  return value
      .trim()
      .split('.')
      .map((part) => int.tryParse(part.trim()) ?? 0)
      .toList();
}
