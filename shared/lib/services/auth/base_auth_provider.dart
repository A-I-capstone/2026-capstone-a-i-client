/// Abstract interface for anonymous authentication.
///
/// Both the parent app and child app depend only on this interface.
/// The concrete implementation ([FirebaseAuthProvider]) can be swapped
/// for a different backend without touching any ViewModel or Repository code.
abstract class BaseAuthProvider {
  /// Signs in anonymously and returns the user's UID.
  /// If a session already exists, the existing UID is returned unchanged.
  /// Returns an empty string on failure (never throws).
  Future<String> signInAnonymously();

  /// The UID of the currently signed-in user.
  /// Returns null if no user is signed in.
  String? get currentUid;

  /// Deletes the currently signed-in user's Firebase Auth account.
  /// Fails silently / returns false on error (never throws).
  Future<bool> deleteAccount();

  /// Signs out the currently signed-in user.
  Future<void> signOut();
}
