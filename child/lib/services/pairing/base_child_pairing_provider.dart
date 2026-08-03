/// Abstract interface for pairing from the child device.
///
/// The child device submits a PIN code; all validation and family mapping
/// logic is handled by the backend (currently Firestore, later Cloud Functions).
///
/// The ViewModel depends only on this interface so the backend can be swapped
/// (e.g., to a REST API or Cloud Function) without touching any UI code.
abstract class BaseChildPairingProvider {
  /// Submits [code] for validation.
  ///
  /// On success, creates the `families/{id}` document atomically and returns
  /// the generated familyId (non-empty string).
  ///
  /// On failure (invalid code, expired, attempts exceeded, etc.) returns an
  /// empty string and never throws — callers should treat '' as failure.
  Future<String> submitPairingCode({
    required String code,
    required String childUid,
  });
}
