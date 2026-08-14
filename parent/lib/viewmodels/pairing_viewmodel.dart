import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/pairing_code.dart';
import '../services/pairing/base_pairing_provider.dart';
import '../services/pairing/firestore_pairing_provider.dart';

/// ViewModel for managing PIN/QR code generation, 5-minute timer countdown,
/// and real-time pairing status subscription on the parent app.
class ParentPairingViewModel extends ChangeNotifier {
  final BaseParentPairingProvider _pairingProvider;

  ParentPairingViewModel({BaseParentPairingProvider? pairingProvider})
      : _pairingProvider =
            pairingProvider ?? FirestoreParentPairingProvider();

  // State
  PairingCode? _currentPairingCode;
  int _remainingSeconds = 300; // 5 minutes = 300s
  bool _isPaired = false;
  bool _isLoading = false;

  Timer? _timer;
  StreamSubscription<bool>? _pairingSubscription;
  String _parentUid = '';

  // Getters
  PairingCode? get currentPairingCode => _currentPairingCode;
  String get code => _currentPairingCode?.code ?? '';
  int get remainingSeconds => _remainingSeconds;
  bool get isPaired => _isPaired;
  bool get isLoading => _isLoading;

  String get formattedTime {
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Initializes pairing for [parentUid]. Generates a PIN and starts listening.
  Future<void> initialize(String parentUid) async {
    debugPrint('[Parent Pairing VM] initialize 호출 (parentUid: $parentUid)');
    if (_parentUid == parentUid && _currentPairingCode != null) {
      debugPrint('[Parent Pairing VM] 이미 동일 parentUid로 초기화됨, 스킵');
      return;
    }
    _parentUid = parentUid;
    await generateNewCode();
  }

  /// Generates a new PIN and resets the 5-minute countdown.
  Future<void> generateNewCode() async {
    debugPrint('[Parent Pairing VM] generateNewCode 호출 (parentUid: $_parentUid)');
    if (_parentUid.isEmpty) {
      debugPrint('[Parent Pairing VM] parentUid가 비어 있어 PIN 생성 중단');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _pairingSubscription?.cancel();
      _timer?.cancel();

      final pairingCode = await _pairingProvider.createPairingCode(_parentUid);
      _currentPairingCode = pairingCode;
      _remainingSeconds = 300;

      if (pairingCode != null) {
        debugPrint('[Parent Pairing VM] PIN 생성 성공: ${pairingCode.code}, 타이머 및 구독 시작');
        _startTimer();
        _subscribeToPairingStatus(pairingCode.code);
      } else {
        debugPrint('[Parent Pairing VM] PIN 생성 실패 (pairingCode == null)');
      }
    } catch (e, st) {
      debugPrint('[Parent Pairing VM] generateNewCode 예외 발생: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        // Expired after 5 minutes -> Auto refresh
        debugPrint('[Parent Pairing VM] 5분 만료됨 → 자동 갱신 진행');
        generateNewCode();
      }
    });
  }

  void _subscribeToPairingStatus(String code) {
    debugPrint('[Parent Pairing VM] _subscribeToPairingStatus 시작 (code: $code)');
    _pairingSubscription =
        _pairingProvider.watchPairingStatus(code).listen((isUsed) {
      debugPrint('[Parent Pairing VM] watchPairingStatus 이벤트 수신: isUsed=$isUsed');
      if (isUsed) {
        debugPrint('[Parent Pairing VM] isUsed=true 확인됨 → 연동 완료 처리!');
        _isPaired = true;
        _timer?.cancel();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pairingSubscription?.cancel();
    super.dispose();
  }
}
