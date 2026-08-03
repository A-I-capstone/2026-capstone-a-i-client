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
    if (_parentUid == parentUid && _currentPairingCode != null) return;
    _parentUid = parentUid;
    await generateNewCode();
  }

  /// Generates a new PIN and resets the 5-minute countdown.
  Future<void> generateNewCode() async {
    if (_parentUid.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _pairingSubscription?.cancel();
      _timer?.cancel();

      final pairingCode = await _pairingProvider.createPairingCode(_parentUid);
      _currentPairingCode = pairingCode;
      _remainingSeconds = 300;

      if (pairingCode != null) {
        _startTimer();
        _subscribeToPairingStatus(pairingCode.code);
      }
    } catch (e, st) {
      debugPrint('[ParentPairingViewModel] generateNewCode error: $e\n$st');
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
        debugPrint('[ParentPairingViewModel] 5분 만료됨 → 자동 갱신 진행');
        generateNewCode();
      }
    });
  }

  void _subscribeToPairingStatus(String code) {
    _pairingSubscription =
        _pairingProvider.watchPairingStatus(code).listen((isUsed) {
      if (isUsed) {
        debugPrint('[ParentPairingViewModel] isUsed=true 수신 → 연동 완료!');
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
