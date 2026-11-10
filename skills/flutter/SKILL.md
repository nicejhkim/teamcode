---
name: flutter
description: Flutter 클라이언트에 FVM, Riverpod, Firebase Crashlytics, Firebase Analytics, Remote Config 버전 게이트를 넣는다. "/flutter", "Flutter 기본 셋업", "Flutter 클라이언트 시작"에 사용한다.
argument-hint: "[Firebase 프로젝트 ID]"
disable-model-invocation: true
---

# /flutter — Flutter 클라이언트 기본 셋업

한 번 실행하면 이 앱에 아래를 넣는다. 이미 있는 파일과 설정은 덮어쓰지 않고, 빠진 것만 넣는다.

- Flutter SDK는 FVM으로 고정한다. 이후 Flutter 명령은 `fvm flutter`만 쓴다.
- 상태 관리는 Riverpod다. 앱 루트를 `ProviderScope`로 감싼다.
- 충돌 기록은 Firebase Crashlytics, 사용 기록은 Firebase Analytics다.
- 버전 확인은 Firebase Remote Config다. `minimum_version` 미만은 강제 업데이트, `recommended_version` 미만은 권고 업데이트다.

요구사항, PRD, 이슈, 커밋은 만들지 않는다. `/kickoff`와 `/work`를 대신하지 않는다.

템플릿은 이 스킬 디렉터리의 `assets/`에 있다. 복사한 뒤 로직을 다시 짜지 않는다.

## 0단계 — 상태

묻기 전에 읽는다.

- `pubspec.yaml`이 없거나 `sdk: flutter`가 없다 → 앱이 아니다. 한 가지만 묻는다. 추천은 이 폴더에 앱을 만드는 것이다. 프로젝트 이름은 폴더 이름을 소문자와 `_`만 남긴 것, org는 `com.example`.

> 이 폴더에 Flutter 앱을 만들까요? 프로젝트 이름은 `<이름>`, org는 `com.example`입니다.

동의하기 전에는 `flutter create`를 하지 않는다. 다른 이름이나 org를 말하면 그 값을 쓴다.

- `sdk: flutter`는 있는데 `lib/main.dart`가 없다 → 멈춘다. 시작 흐름을 넣을 엔트리가 없다고 알린다.
- `.fvmrc` 또는 `.fvm/fvm_config.json`에 버전이 있으면 그 핀을 유지한다.
- `lib/firebase_options.dart`가 있으면 FlutterFire 설정은 건너뛴다.
- 아래 표의 대상 파일이 이미 있으면 그 파일은 복사하지 않는다.

## 1단계 — FVM

`fvm`이 없으면 한 가지만 묻는다. 추천은 `dart pub global activate fvm`으로 설치하고 계속하는 것이다. `dart`도 없으면 설치 방법만 알리고 멈춘다. Dart SDK는 대신 설치하지 않는다.

> FVM이 없습니다. 설치하고 계속할까요?

핀이 없으면 `fvm use stable --force`. 앱을 만들기로 했으면 그다음 `fvm flutter create --project-name <이름> --org <org> .`

## 2단계 — 패키지

```bash
fvm flutter pub add flutter_riverpod firebase_core firebase_analytics firebase_crashlytics firebase_remote_config package_info_plus url_launcher
```

## 3단계 — 파일

`assets/`를 그대로 복사한다. `version_gate_test.dart`의 `__PACKAGE__`만 `pubspec.yaml`의 `name`으로 바꾼다. 그 외 내용은 고치지 않는다.

| 원본 | 대상 |
|---|---|
| `assets/bootstrap.dart` | `lib/bootstrap.dart` |
| `assets/update/version_gate.dart` | `lib/update/version_gate.dart` |
| `assets/update/gate_scope.dart` | `lib/update/gate_scope.dart` |
| `assets/update/update_gate.dart` | `lib/update/update_gate.dart` |
| `assets/version_gate_test.dart` | `test/version_gate_test.dart` |

`Makefile`이 없으면 `assets/Makefile`을 복사한다. 있으면 `analyze`와 `test` 타깃이 없을 때만 그 타깃을 추가한다. 기존 타깃은 바꾸지 않는다.

## 4단계 — main.dart

`lib/main.dart`에 빠진 연결만 잇는다. 화면과 기존 상태는 옮기지 않는다.

- `main`을 `async`로 두고, `runApp` 앞에 `final gate = await bootstrap();`을 둔다.
- `runApp`의 최상위를 `ProviderScope`로 감싼다. 이미 있으면 한 번만 감싼다.
- 그 안을 `GateScope(decision: gate.decision, storeUrl: gate.storeUrl, child: ...)`로 감싼다.
- 루트 `MaterialApp` 또는 `CupertinoApp`의 `builder`가 없으면 `UpdateGate(child: child ?? const SizedBox.shrink())`를 넣는다. 있으면 그 결과만 `UpdateGate`로 감싼다.
- `navigatorObservers`에 `FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)`를 더한다.

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap.dart';
import 'update/gate_scope.dart';
import 'update/update_gate.dart';
```

`const`는 기존 위젯이 이미 `const`일 때만 유지한다.

## 5단계 — Firebase 연결

`lib/firebase_options.dart`가 있으면 건너뛴다.

없으면 FlutterFire CLI로 만든다. CLI가 없으면 `dart pub global activate flutterfire_cli`. 패키지를 넣은 뒤에 실행한다. Crashlytics Gradle 플러그인은 이 명령이 넣는다.

플랫폼은 `android`, `ios`, `web`, `macos`, `windows` 중 폴더가 있는 것이다.

`flutterfire`가 PATH에 없으면 `dart pub global run flutterfire_cli:flutterfire`로 같은 인자를 실행한다.

- 인자에 Firebase 프로젝트 ID가 있으면 `flutterfire configure --project=<id> --platforms=<플랫폼> --yes`
- 없으면 사용자가 프로젝트를 고르도록 `flutterfire configure --platforms=<플랫폼>`를 실행한다. 이 셸에서 고를 수 없으면 그 명령을 사용자에게 알리고, 고른 뒤에 이어서 한다.

로그인되어 있지 않거나 프로젝트를 고르지 못하면 `firebase login`이 필요하다고 알린다. 가짜 `firebase_options.dart`는 만들지 않는다. 나머지 셋업은 남겨 둔다.

## 6단계 — 검사

항상 `fvm flutter test test/version_gate_test.dart`.

`lib/firebase_options.dart`가 있을 때만 `fvm flutter analyze`. 없으면 bootstrap이 그 파일을 가져오므로, analyze 실패를 이 원인과 그 밖의 원인으로 나눠 보고한다.

## 7단계 — 불변 규칙

`AGENTS.md`가 없으면 아래만 만든다. 있으면 `불변 규칙`에 없는 항목만 더한다.

```markdown
## 불변 규칙
- 상태관리는 Riverpod만 쓴다.
- Flutter SDK는 이 저장소의 FVM 핀만 쓴다. Flutter 명령은 `fvm flutter`로 실행한다.
- 충돌 기록은 Firebase Crashlytics, 사용 기록은 Firebase Analytics다. 앱 시작 연결을 빼지 않는다.
- 버전 확인은 Firebase Remote Config다. `min_supported_version` 미만은 강제 업데이트, `latest_version` 미만은 권고 업데이트다. 스토어 주소 키는 `ios_store_url`, `android_store_url`이다.
- 검사는 `fvm flutter analyze`와 `fvm flutter test`다.
```

## 8단계 — 보고

커밋하지 않는다. 다음을 알린다.

- FVM 핀
- 추가한 파일과, 이미 있어 건너뛴 파일
- Firebase 연결이 끝났는지. 끝났으면 콘솔 Remote Config에 위 네 키를 만들어야 게이트가 동작한다. 앱 기본값은 `0.0.0`과 빈 주소라, 올리기 전에는 게이트가 열리지 않는다.
- 이번 실행에서 Remote Config를 가져오지 못하면 앱을 막지 않는다.
- analyze와 버전 테스트 결과
