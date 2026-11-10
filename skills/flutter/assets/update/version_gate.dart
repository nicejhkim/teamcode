/// 설치 버전과 Remote Config 버전을 비교한 결과.
enum VersionDecision {
  /// 업데이트가 필요 없다.
  none,

  /// 닫을 수 있는 업데이트 권고.
  recommend,

  /// 앱 사용을 막는 강제 업데이트.
  force,
}

/// `1.2.3` 형태만 남긴다. `+` 뒤의 빌드 번호와 `-` 뒤는 비교하지 않는다.
List<int>? parseVersion(String raw) {
  final core = raw.split('+').first.split('-').first.trim();
  if (core.isEmpty) return null;
  final parts = <int>[];
  for (final piece in core.split('.')) {
    final value = int.tryParse(piece);
    if (value == null || value < 0) return null;
    parts.add(value);
  }
  return parts;
}

/// 왼쪽이 낮으면 음수, 같으면 0, 높으면 양수. 둘 중 하나라도 버전이 아니면 null.
int? compareVersions(String left, String right) {
  final a = parseVersion(left);
  final b = parseVersion(right);
  if (a == null || b == null) return null;
  final length = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < length; i++) {
    final av = i < a.length ? a[i] : 0;
    final bv = i < b.length ? b[i] : 0;
    if (av != bv) return av.compareTo(bv);
  }
  return 0;
}

/// 이번 실행에서 설정을 가져왔을 때만 판단한다. 가져오지 못하면 앱을 막지 않는다.
VersionDecision decideUpdate({
  required bool fetched,
  required String installed,
  required String minSupported,
  required String latest,
}) {
  if (!fetched) return VersionDecision.none;
  final belowMin = compareVersions(installed, minSupported);
  if (belowMin != null && belowMin < 0) return VersionDecision.force;
  final belowLatest = compareVersions(installed, latest);
  if (belowLatest != null && belowLatest < 0) return VersionDecision.recommend;
  return VersionDecision.none;
}
