import 'placed_item.dart';

/// Data model representing the village state of a profile.
class VillageState {
  /// Current currency balance (Coins).
  final int coins;

  /// Inventory containing list of item IDs owned but not placed on the map.
  final List<String> inventory;

  /// List of items currently placed on the tile map.
  final List<PlacedItem> placedItems;

  const VillageState({
    required this.coins,
    required this.inventory,
    required this.placedItems,
  });

  /// Default initial state for a new profile.
  factory VillageState.empty() => const VillageState(
        coins: 100,
        inventory: [],
        placedItems: [],
      );

  /// Deserializes [VillageState] from Firestore document map.
  factory VillageState.fromFirestore(Map<String, dynamic> data) {
    final rawInventory = data['inventory'] as List<dynamic>? ?? [];
    final rawPlaced = data['placedItems'] as List<dynamic>? ?? [];

    return VillageState(
      coins: (data['coins'] as num?)?.toInt() ?? 100,
      inventory: rawInventory.map((e) => e.toString()).toList(),
      placedItems: rawPlaced
          .whereType<Map<String, dynamic>>()
          .map((e) => PlacedItem.fromMap(e))
          .toList(),
    );
  }

  /// Serializes [VillageState] for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'coins': coins,
      'inventory': inventory,
      'placedItems': placedItems.map((e) => e.toMap()).toList(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  VillageState copyWith({
    int? coins,
    List<String>? inventory,
    List<PlacedItem>? placedItems,
  }) {
    return VillageState(
      coins: coins ?? this.coins,
      inventory: inventory ?? this.inventory,
      placedItems: placedItems ?? this.placedItems,
    );
  }
}
