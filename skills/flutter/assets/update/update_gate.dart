import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'gate_scope.dart';
import 'version_gate.dart';

/// 스토어 주소를 외부 앱으로 연다. 주소가 비었거나 열리지 않으면 돌아온다.
Future<void> openStore(String storeUrl) async {
  final uri = Uri.tryParse(storeUrl.trim());
  if (uri == null || !uri.hasScheme) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (error, stack) {
    debugPrint('스토어를 열지 못했습니다: $error\n$stack');
  }
}

/// `MaterialApp` 또는 `CupertinoApp`의 builder에 넣는다.
/// 강제 업데이트는 앱 대신 안내를 보여주고, 권고는 닫을 수 있는 안내를 위에 올린다.
class UpdateGate extends StatefulWidget {
  /// 앱의 실제 화면을 감싼다.
  const UpdateGate({required this.child, super.key});

  /// builder가 받은 앱 화면.
  final Widget child;

  /// 권고 안내를 닫을 수 있는 상태를 만든다.
  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

/// 권고 안내를 사용자가 닫기 전까지 유지한다.
class _UpdateGateState extends State<UpdateGate> {
  var _recommendVisible = true;

  /// 권고 안내를 닫는다.
  void _closeRecommend() {
    setState(() => _recommendVisible = false);
  }

  /// 강제면 앱을 가리고, 권고면 앱 위에 안내를 올린다.
  @override
  Widget build(BuildContext context) {
    final gate = GateScope.maybeOf(context);
    if (gate == null || gate.decision == VersionDecision.none) {
      return widget.child;
    }
    if (gate.decision == VersionDecision.force) {
      return _ForceUpdate(storeUrl: gate.storeUrl);
    }
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        if (_recommendVisible)
          Positioned.fill(
            child: _RecommendNotice(
              storeUrl: gate.storeUrl,
              onClose: _closeRecommend,
            ),
          ),
      ],
    );
  }
}

/// 앱을 열 수 없게 막는 강제 업데이트 안내.
class _ForceUpdate extends StatelessWidget {
  /// 스토어 주소가 있을 때만 이동 버튼을 둔다.
  const _ForceUpdate({required this.storeUrl});

  final String storeUrl;

  /// 가운데에 안내 문구와 스토어 이동을 둔다.
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFFFFF),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '업데이트가 필요합니다',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  '이 버전은 더 이상 사용할 수 없습니다. 스토어에서 업데이트한 뒤 다시 열어 주세요.',
                  textAlign: TextAlign.center,
                ),
                if (storeUrl.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => openStore(storeUrl),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('스토어로 이동'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 앱 사용을 막지 않고 닫을 수 있는 업데이트 권고.
class _RecommendNotice extends StatelessWidget {
  /// 닫기와 스토어 이동을 받는다.
  const _RecommendNotice({required this.storeUrl, required this.onClose});

  final String storeUrl;

  /// 안내를 닫는다.
  final VoidCallback onClose;

  /// 어두운 막 위에 권고 문구를 올린다.
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x88000000),
      child: Center(
        child: ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '업데이트가 있습니다',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  '더 나은 사용을 위해 최신 버전으로 업데이트할 수 있습니다.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onClose,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('나중에'),
                      ),
                    ),
                    if (storeUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          onClose();
                          openStore(storeUrl);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('업데이트'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
