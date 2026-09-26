import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

/// Service that reads and writes a child's AI safety settings to Firestore.
///
/// Settings are stored as a sub-field on the existing `families/{familyId}`
/// document so no additional collection is required.
///
/// Firestore path:  families/{familyId}
/// Field written:   safetySettings: { harassment, hateSpeech,
///                                    sexuallyExplicit, dangerousContent }
class SafetySettingsService {
  final FirebaseFirestore? _firestore;

  SafetySettingsService({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the current safety settings for [familyId].
  /// Falls back to defaults if the field does not exist or an error occurs.
  Future<SafetySettingsModel> fetchSafetySettings(String familyId) async {
    if (familyId.isEmpty) return const SafetySettingsModel();

    try {
      final snap = await _db.collection('families').doc(familyId).get();
      final raw = snap.data()?['safetySettings'];
      if (raw is Map<String, dynamic>) {
        return SafetySettingsModel.fromFirestore(raw);
      }
    } catch (e, st) {
      debugPrint('[SafetySettingsService] fetchSafetySettings error: $e\n$st');
    }
    return const SafetySettingsModel();
  }

  /// Persists [settings] for [familyId] to Firestore.
  /// Returns `true` on success, `false` on failure.
  Future<bool> updateSafetySettings(
    String familyId,
    SafetySettingsModel settings,
  ) async {
    if (familyId.isEmpty) return false;

    try {
      await _db.collection('families').doc(familyId).set(
        {'safetySettings': settings.toFirestore()},
        SetOptions(merge: true),
      );
      debugPrint(
        '[SafetySettingsService] 안전 설정 저장 완료 (familyId=$familyId): ${settings.toFirestore()}',
      );
      return true;
    } catch (e, st) {
      debugPrint('[SafetySettingsService] updateSafetySettings error: $e\n$st');
      return false;
    }
  }

  /// Streams live updates of safety settings for [familyId].
  /// Emits a new [SafetySettingsModel] whenever the Firestore document changes.
  Stream<SafetySettingsModel> streamSafetySettings(String familyId) {
    if (familyId.isEmpty) {
      return Stream.value(const SafetySettingsModel());
    }

    return _db
        .collection('families')
        .doc(familyId)
        .snapshots()
        .map((snap) {
          final raw = snap.data()?['safetySettings'];
          if (raw is Map<String, dynamic>) {
            return SafetySettingsModel.fromFirestore(raw);
          }
          return const SafetySettingsModel();
        })
        .handleError((e, st) {
          debugPrint(
            '[SafetySettingsService] streamSafetySettings error: $e\n$st',
          );
          return const SafetySettingsModel();
        });
  }
}
