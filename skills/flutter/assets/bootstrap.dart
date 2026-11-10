import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'firebase_options.dart';
import 'update/version_gate.dart';

/// 이 버전 미만이면 앱을 막는다.
const minSupportedVersionKey = 'min_supported_version';

/// 이 버전 미만이면 업데이트를 권한다.
const latestVersionKey = 'latest_version';

/// iOS 스토어 주소.
const iosStoreUrlKey = 'ios_store_url';

/// Android 스토어 주소.
const androidStoreUrlKey = 'android_store_url';

/// 이번 실행의 버전 판단과 스토어 주소.
class StartupGate {
  /// 버전 비교 결과와 이 플랫폼의 스토어 주소를 담는다.
  const StartupGate({required this.decision, required this.storeUrl});

  /// 강제, 권고, 통과 중 하나.
  final VersionDecision decision;

  /// 현재 플랫폼의 스토어 주소. 없으면 빈 문자열.
  final String storeUrl;
}

/// Firebase를 준비하고 충돌 기록, 사용 로그, 버전 게이트를 반환한다.
/// 초기화나 가져오기가 실패하면 앱을 막지 않고 통과를 반환한다.
Future<StartupGate> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stack) {
    debugPrint('Firebase 초기화 실패: $error\n$stack');
    return const StartupGate(decision: VersionDecision.none, storeUrl: '');
  }

  _recordCrashes();

  try {
    await FirebaseAnalytics.instance.logAppOpen();
  } catch (error, stack) {
    debugPrint('Analytics 기록 실패: $error\n$stack');
  }

  try {
    return await _readGate();
  } catch (error, stack) {
    debugPrint('버전 게이트를 읽지 못했습니다: $error\n$stack');
    return const StartupGate(decision: VersionDecision.none, storeUrl: '');
  }
}

/// 프레임워크 오류와 비동기 오류를 Crashlytics에 남긴다.
void _recordCrashes() {
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Remote Config와 설치 버전으로 업데이트 판단을 만든다.
Future<StartupGate> _readGate() async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: kDebugMode
          ? Duration.zero
          : const Duration(hours: 1),
    ),
  );
  await remoteConfig.setDefaults(const {
    minSupportedVersionKey: '0.0.0',
    latestVersionKey: '0.0.0',
    iosStoreUrlKey: '',
    androidStoreUrlKey: '',
  });

  var fetched = false;
  try {
    await remoteConfig.fetchAndActivate();
    fetched = true;
  } catch (error, stack) {
    debugPrint('Remote Config 가져오기 실패: $error\n$stack');
  }

  final info = await PackageInfo.fromPlatform();
  final storeUrl = switch (defaultTargetPlatform) {
    TargetPlatform.iOS => remoteConfig.getString(iosStoreUrlKey),
    TargetPlatform.android => remoteConfig.getString(androidStoreUrlKey),
    _ => '',
  };
  return StartupGate(
    decision: decideUpdate(
      fetched: fetched,
      installed: info.version,
      minSupported: remoteConfig.getString(minSupportedVersionKey),
      latest: remoteConfig.getString(latestVersionKey),
    ),
    storeUrl: storeUrl,
  );
}
