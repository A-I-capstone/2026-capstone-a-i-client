import '../../models/village_state.dart';

/// Abstract repository interface for village state persistence.
abstract class BaseVillageRepository {
  /// Loads [VillageState] for a specific profile under a user.
  Future<VillageState> loadVillageState(String userId, String profileId);

  /// Saves [VillageState] for a specific profile under a user.
  Future<void> saveVillageState(
    String userId,
    String profileId,
    VillageState state,
  );
}
