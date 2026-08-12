import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../viewmodels/pairing_viewmodel.dart';

/// Pairing View for Parent App.
/// Shows QR code and 6-digit PIN with a 5-minute countdown.
/// User CANNOT pop/go back without pairing completion.
class ParentPairingView extends StatelessWidget {
  final String parentUid;
  final VoidCallback onPairingComplete;
  final bool isFirstSetup;

  const ParentPairingView({
    super.key,
    required this.parentUid,
    required this.onPairingComplete,
    this.isFirstSetup = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParentPairingViewModel()..initialize(parentUid),
      child: _ParentPairingContent(
        onPairingComplete: onPairingComplete,
        isFirstSetup: isFirstSetup,
      ),
    );
  }
}

class _ParentPairingContent extends StatefulWidget {
  final VoidCallback onPairingComplete;
  final bool isFirstSetup;

  const _ParentPairingContent({
    required this.onPairingComplete,
    required this.isFirstSetup,
  });

  @override
  State<_ParentPairingContent> createState() => _ParentPairingContentState();
}

class _ParentPairingContentState extends State<_ParentPairingContent> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ParentPairingViewModel>();

    if (vm.isPaired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onPairingComplete();
      });
    }

    return PopScope(
      canPop: !widget.isFirstSetup, // Allow go back if not first setup
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F4F2),
        appBar: AppBar(
          title: const Text('자녀 앱 연동'),
          centerTitle: true,
          automaticallyImplyLeading: !widget.isFirstSetup,
          leading: widget.isFirstSetup
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF3A3936),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '자녀 기기 연동하기',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3A3936),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '자녀 앱에서 QR 코드를 스캔하거나\n아래 6자리 PIN 번호를 입력해 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF667595),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // QR Code Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFADAAA4), width: 1.5),
                  ),
                  child: vm.isLoading
                      ? const SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3A3936),
                            ),
                          ),
                        )
                      : QrImageView(
                          data: vm.code,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                ),
                const SizedBox(height: 28),

                // 6-digit PIN Display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE772),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3A3936), width: 2),
                  ),
                  child: Text(
                    vm.isLoading ? '생성 중...' : _formatPinCode(vm.code),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: Color(0xFF3A3936),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Countdown Timer & Refresh Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Color(0xFFEC8D42),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '남은 시간: ${vm.formattedTime}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEC8D42),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: vm.isLoading ? null : vm.generateNewCode,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('재발급'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3A3936),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  widget.isFirstSetup
                      ? '* 5분이 지나면 PIN 번호가 자동으로 갱신됩니다.\n* 연동을 완료하기 전까지 앱을 이탈할 수 없습니다.'
                      : '* 5분이 지나면 PIN 번호가 자동으로 갱신됩니다.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFADAAA4),
                    height: 1.4,
                  ),
                ),
                if (!widget.isFirstSetup) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3A3936), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: const Color(0xFF3A3936),
                      ),
                      child: const Text(
                        '연동 취소',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  String _formatPinCode(String code) {
    if (code.length != 6) return code;
    return '${code.substring(0, 3)} ${code.substring(3)}';
  }
}
