import '../../models/pairing_code.dart';

/// Abstract interface for generating and watching pairing codes in the parent app.
///
/// Decouples UI / ViewModel logic from the backend storage implementation
/// (Firestore, REST API, etc.).
abstract class BaseParentPairingProvider {
  /// Generates a new 6-digit pairing code for [parentUid] and saves it.
  /// `expiresAt` is set to 5 minutes from creation.
  /// Returns the generated [PairingCode] object.
  Future<PairingCode?> createPairingCode(String parentUid);

  /// Listens to real-time updates for [code].
  /// Emits `true` when `isUsed` becomes `true`.
  Stream<bool> watchPairingStatus(String code);
}
