import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../viewmodels/pairing_viewmodel.dart';

/// Child-device pairing screen.
///
/// Allows the child to enter the 6-digit PIN from the parent app, or scan
/// the QR code instead. The child cannot proceed to the main app until
/// pairing succeeds.
///
/// Pure UI — all business logic lives in [ChildPairingViewModel].
class ChildPairingView extends StatelessWidget {
  /// The anonymous UID obtained after sign-in; passed to the ViewModel.
  final String childUid;

  /// Callback triggered when pairing completes successfully.
  final ValueChanged<String>? onPaired;

  const ChildPairingView({
    super.key,
    required this.childUid,
    this.onPaired,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChildPairingViewModel(),
      child: _ChildPairingContent(childUid: childUid, onPaired: onPaired),
    );
  }
}

class _ChildPairingContent extends StatefulWidget {
  final String childUid;
  final ValueChanged<String>? onPaired;

  const _ChildPairingContent({
    required this.childUid,
    this.onPaired,
  });

  @override
  State<_ChildPairingContent> createState() => _ChildPairingContentState();
}

class _ChildPairingContentState extends State<_ChildPairingContent> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChildPairingViewModel>();

    if (vm.isPaired) {
      debugPrint(
        '[Child Pairing View] vm.isPaired=true 감지! familyId: ${vm.familyId} → onPaired 콜백 호출 예정',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onPaired?.call(vm.familyId);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _PairingHeader(),
              const SizedBox(height: 32),
              _ModeToggleButton(isQrMode: vm.isQrMode),
              const SizedBox(height: 32),
              if (vm.isQrMode)
                _QrScannerPanel(childUid: widget.childUid)
              else
                _PinInputPanel(childUid: widget.childUid),
              if (vm.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 20),
                _ErrorMessage(message: vm.errorMessage),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PairingHeader extends StatelessWidget {
  const _PairingHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE772),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF3A3936), width: 2.5),
          ),
          child: const Icon(Icons.link_rounded, size: 40, color: Color(0xFF3A3936)),
        ),
        const SizedBox(height: 20),
        Text(
          '부모님 앱과 연결하기',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3A3936),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '부모님 앱에 표시된 숫자를 입력하거나\nQR 코드를 스캔해 주세요!',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF3A3936).withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ModeToggleButton extends StatelessWidget {
  final bool isQrMode;
  const _ModeToggleButton({required this.isQrMode});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ChildPairingViewModel>();
    return GestureDetector(
      onTap: vm.toggleMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF3A3936),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isQrMode ? Icons.keyboard_alt_outlined : Icons.qr_code_scanner,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isQrMode ? '숫자로 입력하기' : 'QR 코드 스캔하기',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinInputPanel extends StatelessWidget {
  final String childUid;
  const _PinInputPanel({required this.childUid});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ChildPairingViewModel>();
    final isLoading = context.watch<ChildPairingViewModel>().isLoading;

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: Color(0xFF3A3936),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFADAAA4), width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFF0440FE), width: 2.5),
    );

    return Column(
      children: [
        Pinput(
          length: 6,
          keyboardType: TextInputType.number,
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: focusedPinTheme,
          onCompleted: isLoading
              ? null
              : (code) {
                  debugPrint('[Child Pairing View] PIN 입력 완료 이벤트: "$code"');
                  vm.submitCode(code: code, childUid: childUid);
                },
        ),
        const SizedBox(height: 24),
        if (isLoading)
          const CircularProgressIndicator(color: Color(0xFF3A3936)),
      ],
    );
  }
}

class _QrScannerPanel extends StatefulWidget {
  final String childUid;
  const _QrScannerPanel({required this.childUid});

  @override
  State<_QrScannerPanel> createState() => _QrScannerPanelState();
}

class _QrScannerPanelState extends State<_QrScannerPanel> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ChildPairingViewModel>();
    final isLoading = context.watch<ChildPairingViewModel>().isLoading;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 280,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF3A3936)),
              )
            : MobileScanner(
                onDetect: (capture) {
                  if (_scanned) return;
                  final barcode = capture.barcodes.firstOrNull;
                  final raw = barcode?.rawValue ?? '';
                  debugPrint('[Child Pairing View] QR 코드 감지: "$raw"');
                  if (raw.length == 6 && RegExp(r'^\d{6}$').hasMatch(raw)) {
                    _scanned = true;
                    debugPrint('[Child Pairing View] 유효한 6자리 QR 코드 확인됨 → 제출');
                    vm
                        .submitCode(code: raw, childUid: widget.childUid)
                        .then((_) {
                      if (!vm.isPaired) _scanned = false;
                    });
                  } else {
                    debugPrint('[Child Pairing View] 유효하지 않은 QR 코드 형식: "$raw"');
                  }
                },
              ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9849).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9849), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF9849), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF3A3936),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
