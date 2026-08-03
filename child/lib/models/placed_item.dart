/// Data model representing an item placed on the village tile map.
class PlacedItem {
  /// Unique identifier for each placed instance on the map.
  final String instanceId;

  /// ID of the [VillageItem] definition.
  final String itemId;

  /// Tile grid X coordinate (0 ~ 19).
  final int tileX;

  /// Tile grid Y coordinate (0 ~ 19).
  final int tileY;

  const PlacedItem({
    required this.instanceId,
    required this.itemId,
    required this.tileX,
    required this.tileY,
  });

  /// Factory constructor to deserialize from Map.
  factory PlacedItem.fromMap(Map<String, dynamic> map) {
    return PlacedItem(
      instanceId: map['instanceId'] as String? ?? '',
      itemId: map['itemId'] as String? ?? '',
      tileX: (map['tileX'] as num?)?.toInt() ?? 0,
      tileY: (map['tileY'] as num?)?.toInt() ?? 0,
    );
  }

  /// Serialize to Map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'instanceId': instanceId,
      'itemId': itemId,
      'tileX': tileX,
      'tileY': tileY,
    };
  }

  PlacedItem copyWith({
    String? instanceId,
    String? itemId,
    int? tileX,
    int? tileY,
  }) {
    return PlacedItem(
      instanceId: instanceId ?? this.instanceId,
      itemId: itemId ?? this.itemId,
      tileX: tileX ?? this.tileX,
      tileY: tileY ?? this.tileY,
    );
  }
}
