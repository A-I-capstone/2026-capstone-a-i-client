import '../../models/placed_item.dart';
import '../../models/placement_rule.dart';
import '../../models/village_item.dart';

/// Representation of a valid candidate slot on the map for placing an item.
class PlacementSlot {
  final int originX;
  final int originY;
  final int width;
  final int height;

  const PlacementSlot({
    required this.originX,
    required this.originY,
    required this.width,
    required this.height,
  });

  bool containsTile(int x, int y) {
    return x >= originX &&
        x < originX + width &&
        y >= originY &&
        y < originY + height;
  }
}

/// Service class providing grid topology logic, occupancy calculations, and placement validation.
class VillagePlacementValidator {
  static const int mapWidthTiles = 33;
  static const int mapHeightTiles = 13;

  /// Returns true if coordinate [x, y] is a road tile.
  static bool isRoadTile(int x, int y) {
    if (x < 0 || x >= mapWidthTiles || y < 0 || y >= mapHeightTiles) {
      return false;
    }
    return (x % 4 == 0) || (y % 3 == 0);
  }

  /// Returns true if coordinate [x, y] is a grass tile.
  static bool isGrassTile(int x, int y) {
    if (x < 0 || x >= mapWidthTiles || y < 0 || y >= mapHeightTiles) {
      return false;
    }
    return !isRoadTile(x, y);
  }

  /// Builds a set of string keys ("x,y") representing all currently occupied tiles on the map.
  static Set<String> getOccupiedTiles({
    required List<PlacedItem> placedItems,
    required Map<String, VillageItem> itemDefinitions,
  }) {
    final occupied = <String>{};

    for (final placed in placedItems) {
      final itemDef = itemDefinitions[placed.itemId];
      final rule = itemDef?.placementRule ??
          const PlacementRule(
            tileWidth: 1,
            tileHeight: 1,
            allowedSurface: PlacementSurface.any,
          );

      for (int dx = 0; dx < rule.tileWidth; dx++) {
        for (int dy = 0; dy < rule.tileHeight; dy++) {
          occupied.add('${placed.tileX + dx},${placed.tileY + dy}');
        }
      }
    }

    return occupied;
  }

  /// Finds all available slots on the map for placing the specified [item].
  static List<PlacementSlot> getAvailableSlots({
    required VillageItem item,
    required List<PlacedItem> placedItems,
    required Map<String, VillageItem> itemDefinitions,
  }) {
    final occupied = getOccupiedTiles(
      placedItems: placedItems,
      itemDefinitions: itemDefinitions,
    );

    final rule = item.placementRule;
    final slots = <PlacementSlot>[];

    if (rule.snapToPlot && rule.tileWidth == 3 && rule.tileHeight == 2) {
      // Snapping to pre-defined 2x3 grass plots (8 columns x 4 rows = 32 plots)
      for (int gy = 0; gy < 4; gy++) {
        for (int gx = 0; gx < 8; gx++) {
          final originX = 4 * gx + 1;
          final originY = 3 * gy + 1;

          if (_isSlotValid(
            originX: originX,
            originY: originY,
            width: rule.tileWidth,
            height: rule.tileHeight,
            surface: rule.allowedSurface,
            occupied: occupied,
          )) {
            slots.add(PlacementSlot(
              originX: originX,
              originY: originY,
              width: rule.tileWidth,
              height: rule.tileHeight,
            ));
          }
        }
      }
    } else {
      // General grid scan for item dimensions
      for (int y = 0; y <= mapHeightTiles - rule.tileHeight; y++) {
        for (int x = 0; x <= mapWidthTiles - rule.tileWidth; x++) {
          if (_isSlotValid(
            originX: x,
            originY: y,
            width: rule.tileWidth,
            height: rule.tileHeight,
            surface: rule.allowedSurface,
            occupied: occupied,
          )) {
            slots.add(PlacementSlot(
              originX: x,
              originY: y,
              width: rule.tileWidth,
              height: rule.tileHeight,
            ));
          }
        }
      }
    }

    return slots;
  }

  /// Checks if a rectangle at [originX, originY] with [width] and [height] is valid.
  static bool _isSlotValid({
    required int originX,
    required int originY,
    required int width,
    required int height,
    required PlacementSurface surface,
    required Set<String> occupied,
  }) {
    for (int dy = 0; dy < height; dy++) {
      for (int dx = 0; dx < width; dx++) {
        final tx = originX + dx;
        final ty = originY + dy;

        // Check map boundaries
        if (tx < 0 || tx >= mapWidthTiles || ty < 0 || ty >= mapHeightTiles) {
          return false;
        }

        // Check occupancy
        if (occupied.contains('$tx,$ty')) {
          return false;
        }

        // Check surface requirements
        switch (surface) {
          case PlacementSurface.grassOnly:
            if (!isGrassTile(tx, ty)) return false;
            break;

          case PlacementSurface.roadOnly:
            if (!isRoadTile(tx, ty)) return false;
            break;

          case PlacementSurface.any:
            break;
        }
      }
    }

    return true;
  }

  /// Resolves user tap at [tappedX, tappedY] into a valid origin coordinate for [item].
  /// Returns null if placement is not allowed at the tapped location.
  static PlacementSlot? resolvePlacement({
    required VillageItem item,
    required int tappedX,
    required int tappedY,
    required List<PlacedItem> placedItems,
    required Map<String, VillageItem> itemDefinitions,
  }) {
    final availableSlots = getAvailableSlots(
      item: item,
      placedItems: placedItems,
      itemDefinitions: itemDefinitions,
    );

    for (final slot in availableSlots) {
      if (slot.containsTile(tappedX, tappedY)) {
        return slot;
      }
    }

    return null;
  }
}
