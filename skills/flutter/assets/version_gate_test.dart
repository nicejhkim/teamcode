import 'package:__PACKAGE__/update/version_gate.dart';
import 'package:flutter_test/flutter_test.dart';

/// 버전 비교와 업데이트 판단을 확인한다.
void main() {
  // 자리마다 숫자를 비교한다.
  test('낮은 버전은 음수', () {
    expect(compareVersions('1.0.0', '1.0.1'), lessThan(0));
  });

  // 빠진 자리는 0으로 본다.
  test('짧은 버전과 0으로 메운 버전은 같다', () {
    expect(compareVersions('1.2', '1.2.0'), 0);
  });

  // 스토어 버전 비교에서는 출시 전 표기를 보지 않는다.
  test('붙임표 뒤는 비교하지 않는다', () {
    expect(compareVersions('1.0.0-beta', '1.0.0'), 0);
  });

  // 가져오기에 실패하면 최소 버전보다 낮아도 앱을 막지 않는다.
  test('가져오지 못하면 통과', () {
    expect(
      decideUpdate(
        fetched: false,
        installed: '1.0.0',
        minSupported: '2.0.0',
        latest: '3.0.0',
      ),
      VersionDecision.none,
    );
  });

  // 최소 버전이 최신 버전보다 높아도 최소 버전을 먼저 본다.
  test('최소 버전 미만은 강제', () {
    expect(
      decideUpdate(
        fetched: true,
        installed: '1.0.0',
        minSupported: '1.2.0',
        latest: '2.0.0',
      ),
      VersionDecision.force,
    );
  });

  // 최소 버전은 지났고 최신 버전보다 낮으면 권고다.
  test('최신 버전 미만은 권고', () {
    expect(
      decideUpdate(
        fetched: true,
        installed: '1.5.0',
        minSupported: '1.2.0',
        latest: '2.0.0',
      ),
      VersionDecision.recommend,
    );
  });

  // 최신 버전과 같으면 안내하지 않는다.
  test('최신 버전 이상이면 통과', () {
    expect(
      decideUpdate(
        fetched: true,
        installed: '2.0.0',
        minSupported: '1.0.0',
        latest: '2.0.0',
      ),
      VersionDecision.none,
    );
  });
}
