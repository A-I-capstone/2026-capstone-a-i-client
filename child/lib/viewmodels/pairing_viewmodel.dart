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
    notifyListeners();
  }

  /// Submits [code] (from PIN input or QR scan) for validation.
  /// [childUid] is the anonymous UID of this device obtained from Auth.
  Future<void> submitCode({
    required String code,
    required String childUid,
  }) async {
    if (code.length != 6 || childUid.isEmpty) return;

    _status = ChildPairingStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _pairingProvider.submitPairingCode(
        code: code,
        childUid: childUid,
      );

      if (result.isNotEmpty) {
        _familyId = result;
        _status = ChildPairingStatus.success;
      } else {
        // Increment attempts counter in background
        final provider = _pairingProvider;
        if (provider is FirestoreChildPairingProvider) {
          unawaited(provider.incrementAttempts(code));
        }
        _status = ChildPairingStatus.failure;
        _errorMessage = '코드가 올바르지 않거나 만료되었어요. 다시 확인해 보세요!';
      }
    } catch (e, st) {
      debugPrint('[ChildPairingViewModel] submitCode 오류: $e\n$st');
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
