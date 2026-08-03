import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../models/placed_item.dart';
import '../../models/village_item.dart';
import 'tile_map_component.dart';

/// Component representing an item placed on the village tile map.
class PlacedItemComponent extends PositionComponent with TapCallbacks {
  final PlacedItem placedItem;
  final VillageItem itemDefinition;
  final Function(PlacedItem) onTapPlaced;
  final bool isHighlightedForSale;

  final Paint _fillPaint = Paint();
  final Paint _borderPaint = Paint()
    ..color = const Color(0xFF3A3936)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  final Paint _highlightBorderPaint = Paint()
    ..color = const Color(0xFFFF0055) // Neon Red / Pink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5;

  double _blinkTimer = 0.0;

  PlacedItemComponent({
    required this.placedItem,
    required this.itemDefinition,
    required this.onTapPlaced,
    this.isHighlightedForSale = false,
  }) {
    final rule = itemDefinition.placementRule;
    position = Vector2(
      placedItem.tileX * TileMapComponent.tileSize,
      placedItem.tileY * TileMapComponent.tileSize,
    );
    size = Vector2(
      rule.tileWidth * TileMapComponent.tileSize,
      rule.tileHeight * TileMapComponent.tileSize,
    );
    _fillPaint.color = _getColorForCategory(itemDefinition.category);
  }

  Color _getColorForCategory(VillageItemCategory category) {
    switch (category) {
      case VillageItemCategory.building:
        return const Color(0xFFFF9849); // Tangerine
      case VillageItemCategory.nature:
        return const Color(0xFF8BE5B5); // Mint
      case VillageItemCategory.facility:
        return const Color(0xFF2672F1); // Ocean soft
      case VillageItemCategory.fence:
        return const Color(0xFF9B6C53); // Sand
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isHighlightedForSale) {
      _blinkTimer += dt * 6.0; // Blink frequency
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(6),
    );

    if (isHighlightedForSale) {
      // Blinking opacity effect when highlighted for sale (1st tap)
      final opacity = 0.3 + 0.7 * ((sin(_blinkTimer) + 1.0) / 2.0);
      _fillPaint.color =
          _getColorForCategory(itemDefinition.category).withValues(alpha: opacity);
      canvas.drawRRect(rect, _fillPaint);
      canvas.drawRRect(rect, _highlightBorderPaint);
    } else {
      _fillPaint.color = _getColorForCategory(itemDefinition.category);
      canvas.drawRRect(rect, _fillPaint);
      canvas.drawRRect(rect, _borderPaint);
    }

    // Render item name text in center if footprint is multi-tile
    if (size.x > TileMapComponent.tileSize || size.y > TileMapComponent.tileSize) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: itemDefinition.name,
          style: const TextStyle(
            color: Color(0xFFFFFFFE),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.x - 8);

      textPainter.paint(
        canvas,
        Offset(
          (size.x - textPainter.width) / 2,
          (size.y - textPainter.height) / 2,
        ),
      );
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    onTapPlaced(placedItem);
  }
}
