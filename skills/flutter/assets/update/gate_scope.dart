import 'package:flutter/widgets.dart';

import 'version_gate.dart';

/// 앱 시작 시 정한 업데이트 판단을 아래 위젯에 전달한다.
class GateScope extends InheritedWidget {
  /// 버전 판단과 스토어 주소를 하위 위젯에 넘긴다.
  const GateScope({
    required this.decision,
    required this.storeUrl,
    required super.child,
    super.key,
  });

  /// 강제, 권고, 통과 중 하나.
  final VersionDecision decision;

  /// 현재 플랫폼의 스토어 주소. 없으면 빈 문자열.
  final String storeUrl;

  /// 위쪽에 [GateScope]가 없으면 null.
  static GateScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GateScope>();
  }

  /// 판단이나 스토어 주소가 바뀌면 아래 위젯을 다시 그린다.
  @override
  bool updateShouldNotify(GateScope oldWidget) {
    return decision != oldWidget.decision || storeUrl != oldWidget.storeUrl;
  }
}
