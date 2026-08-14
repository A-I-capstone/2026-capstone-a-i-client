import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/pairing/base_child_pairing_provider.dart';
import '../services/pairing/firestore_child_pairing_provider.dart';

/// Possible states of the child pairing flow.
enum ChildPairingStatus { idle, loading, success, failure }

/// ViewModel managing PIN entry / QR scan pairing from the child device.
///
/// Extends [ChangeNotifier]; does not import material.dart or reference
/// BuildContext.
class ChildPairingViewModel extends ChangeNotifier {
  final BaseChildPairingProvider _pairingProvider;

  ChildPairingViewModel({BaseChildPairingProvider? pairingProvider})
      : _pairingProvider =
            pairingProvider ?? FirestoreChildPairingProvider();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  ChildPairingStatus _status = ChildPairingStatus.idle;
  String _errorMessage = '';
  String _familyId = '';
  bool _isQrMode = false;

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  ChildPairingStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get familyId => _familyId;
  bool get isQrMode => _isQrMode;
  bool get isLoading => _status == ChildPairingStatus.loading;
  bool get isPaired => _status == ChildPairingStatus.success;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Toggle between PIN input mode and QR scan mode.
  void toggleMode() {
    _isQrMode = !_isQrMode;
    _errorMessage = '';
    debugPrint('[Child Pairing VM] 모드 전환: isQrMode=$_isQrMode');
    notifyListeners();
  }

  /// Submits [code] (from PIN input or QR scan) for validation.
  /// [childUid] is the anonymous UID of this device obtained from Auth.
  Future<void> submitCode({
    required String code,
    required String childUid,
  }) async {
    debugPrint('[Child Pairing VM] submitCode 호출 (code: "$code", childUid: "$childUid")');
    if (code.length != 6 || childUid.isEmpty) {
      debugPrint(
        '[Child Pairing VM] 유효성 검사 실패 (code 길이: ${code.length}, childUid 비어있음 여부: ${childUid.isEmpty})',
      );
      return;
    }

    _status = ChildPairingStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _pairingProvider.submitPairingCode(
        code: code,
        childUid: childUid,
      );

      debugPrint('[Child Pairing VM] submitPairingCode 결과 수신: "$result"');

      if (result.isNotEmpty) {
        _familyId = result;
        _status = ChildPairingStatus.success;
        debugPrint('[Child Pairing VM] 페어링 성공 상태로 전환! familyId: $_familyId');
      } else {
        // Increment attempts counter in background
        final provider = _pairingProvider;
        if (provider is FirestoreChildPairingProvider) {
          unawaited(provider.incrementAttempts(code));
        }
        _status = ChildPairingStatus.failure;
        _errorMessage = '코드가 올바르지 않거나 만료되었어요. 다시 확인해 보세요!';
        debugPrint('[Child Pairing VM] 페어링 실패 상태로 전환 (코드 불일치/만료/오류)');
      }
    } catch (e, st) {
      debugPrint('[Child Pairing VM] submitCode 예외 발생: $e\n$st');
      _status = ChildPairingStatus.failure;
      _errorMessage = '연결에 문제가 생겼어요. 잠시 후 다시 시도해 보세요!';
    } finally {
      notifyListeners();
    }
  }

  /// Resets to idle state so the user can try again.
  void reset() {
    _status = ChildPairingStatus.idle;
    _errorMessage = '';
    notifyListeners();
  }
}
