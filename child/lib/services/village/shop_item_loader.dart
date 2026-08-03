import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/village_item.dart';

/// Helper service to load shop items.
///
/// TODO: Currently loads static items from `assets/game/data/shop_items.json`.
///       In future phases, migrate to load dynamically from Firebase Remote Config
///       or Firestore `shopItems` collection using [VillageItem.fromJson].
class ShopItemLoader {
  static const String jsonPath = 'assets/game/data/shop_items.json';

  /// Loads list of available [VillageItem]s from asset bundle.
  static Future<List<VillageItem>> loadItems([AssetBundle? bundle]) async {
    final assetBundle = bundle ?? rootBundle;
    try {
      final jsonString = await assetBundle.loadString(jsonPath);
      final List<dynamic> rawList = jsonDecode(jsonString) as List<dynamic>;
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((json) => VillageItem.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback empty list on error
      return [];
    }
  }
}
