import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

/// Subscribes to the child's safety settings stored by the parent in Firestore
/// and exposes live updates as a [Stream<SafetySettingsModel>].
///
/// Firestore path:  families/{familyId}  (field: safetySettings)
///
/// On any error the stream emits a safe default [SafetySettingsModel] so the
/// app never crashes due to a missing or malformed document.
class SafetySettingsListener {
  final String familyId;
  final FirebaseFirestore? _firestore;

  SafetySettingsListener({
    required this.familyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Stream<SafetySettingsModel>? _stream;

  /// Returns a broadcast stream of [SafetySettingsModel] that emits whenever
  /// the parent changes the safety settings in Firestore.
  ///
  /// The stream is memoised — multiple callers share the same subscription.
  Stream<SafetySettingsModel> get updates {
    _stream ??= _buildStream();
    return _stream!;
  }

  Stream<SafetySettingsModel> _buildStream() {
    if (familyId.isEmpty) {
      debugPrint(
        '[SafetySettingsListener] familyId가 비어 있음 — 기본 안전 설정을 사용합니다.',
      );
      return Stream.value(const SafetySettingsModel()).asBroadcastStream();
    }

    return _db
        .collection('families')
        .doc(familyId)
        .snapshots()
        .map((snap) {
          final raw = snap.data()?['safetySettings'];
          if (raw is Map<String, dynamic>) {
            final model = SafetySettingsModel.fromFirestore(raw);
            debugPrint(
              '[SafetySettingsListener] 안전 설정 수신: ${model.toFirestore()}',
            );
            return model;
          }
          return const SafetySettingsModel();
        })
        .handleError((e, st) {
          debugPrint('[SafetySettingsListener] 스트림 오류 (기본값 사용): $e\n$st');
          return const SafetySettingsModel();
        })
        .asBroadcastStream();
  }

  /// Fetches the current safety settings once (non-streaming).
  /// Used during app startup before the stream is established.
  Future<SafetySettingsModel> fetchOnce() async {
    if (familyId.isEmpty) return const SafetySettingsModel();

    try {
      final snap = await _db.collection('families').doc(familyId).get();
      final raw = snap.data()?['safetySettings'];
      if (raw is Map<String, dynamic>) {
        return SafetySettingsModel.fromFirestore(raw);
      }
    } catch (e, st) {
      debugPrint('[SafetySettingsListener] fetchOnce error: $e\n$st');
    }
    return const SafetySettingsModel();
  }
}
