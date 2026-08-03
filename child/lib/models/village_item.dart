import 'placement_rule.dart';

/// Category of village shop items.
enum VillageItemCategory {
  building,
  nature,
  facility,
  fence,
}

/// Data model representing an item available in the village shop or stored in inventory.
///
/// TODO: Currently loaded from assets/game/data/shop_items.json.
///       When migrating to Firebase Remote Config or Firestore `shopItems` collection,
///       use [VillageItem.fromJson] factory directly.
class VillageItem {
  final String id;
  final String name;
  final VillageItemCategory category;
  final int price;

  /// Path to asset image. Null if image asset is not ready yet.
  final String? assetPath;

  /// Optional custom placement rule. If null, defaults to [PlacementRule.forCategory].
  final PlacementRule? customPlacementRule;

  const VillageItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.assetPath,
    this.customPlacementRule,
  });

  /// Effective placement rule for this item.
  PlacementRule get placementRule =>
      customPlacementRule ?? PlacementRule.forCategory(category);

  /// Factory constructor to deserialize [VillageItem] from JSON map.
  factory VillageItem.fromJson(Map<String, dynamic> json) {
    final categoryStr = json['category'] as String? ?? 'building';
    final category = VillageItemCategory.values.firstWhere(
      (e) => e.name == categoryStr,
      orElse: () => VillageItemCategory.building,
    );

    PlacementRule? customRule;
    if (json.containsKey('placementRule') && json['placementRule'] is Map) {
      customRule = PlacementRule.fromJson(
        Map<String, dynamic>.from(json['placementRule'] as Map),
      );
    }

    return VillageItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '아이템',
      category: category,
      price: (json['price'] as num?)?.toInt() ?? 0,
      assetPath: json['assetPath'] as String?,
      customPlacementRule: customRule,
    );
  }

  /// Serialize to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'price': price,
      'assetPath': assetPath,
      if (customPlacementRule != null)
        'placementRule': customPlacementRule!.toJson(),
    };
  }
}

