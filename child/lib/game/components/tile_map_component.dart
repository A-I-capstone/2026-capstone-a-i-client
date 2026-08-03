import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../services/village/village_placement_validator.dart';

/// Renders orthogonal top-down tile map (33x13 tiles, 32x32px each).
///
/// Top-down layout:
/// - Road tiles (1-tile wide/high): `x % 4 == 0` or `y % 3 == 0`
/// - Grass tiles (2x3 plots): `x % 4 != 0` and `y % 3 != 0`
///
/// Also handles pulse-highlight rendering for candidate placement slots.
class TileMapComponent extends PositionComponent {
  static const int mapWidthTiles = VillagePlacementValidator.mapWidthTiles;
  static const int mapHeightTiles = VillagePlacementValidator.mapHeightTiles;
  static const double tileSize = 32.0;

  final Paint _grassPaint = Paint()..color = const Color(0xFF7EC850);
  final Paint _walkwayPaint = Paint()..color = const Color(0xFFC4B088);
  final Paint _gridPaint = Paint()
    ..color = const Color(0x22000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  final Paint _pulseFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _pulseBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;

  List<PlacementSlot> _highlightSlots = [];
  double _pulseTimer = 0.0;

  TileMapComponent() {
    size = Vector2(
      mapWidthTiles * tileSize,
      mapHeightTiles * tileSize,
    );
  }

  /// Updates active candidate placement slots to highlight.
  void setHighlightSlots(List<PlacementSlot> slots) {
    _highlightSlots = slots;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_highlightSlots.isNotEmpty) {
      _pulseTimer += dt * 5.0; // Pulse speed
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Render map grid
    for (int y = 0; y < mapHeightTiles; y++) {
      for (int x = 0; x < mapWidthTiles; x++) {
        final rect = Rect.fromLTWH(
          x * tileSize,
          y * tileSize,
          tileSize,
          tileSize,
        );

        final isRoad = VillagePlacementValidator.isRoadTile(x, y);
        canvas.drawRect(rect, isRoad ? _walkwayPaint : _grassPaint);
        canvas.drawRect(rect, _gridPaint);
      }
    }

    // 2. Render pulsing placement highlights
    if (_highlightSlots.isNotEmpty) {
      // Sine wave oscillating between 0.35 and 0.85 opacity
      final pulseFactor = (sin(_pulseTimer) + 1.0) / 2.0;
      final fillOpacity = 0.25 + 0.35 * pulseFactor;
      final borderOpacity = 0.6 + 0.4 * pulseFactor;

      _pulseFillPaint.color = const Color(0xFFFECE01).withValues(alpha: fillOpacity);
      _pulseBorderPaint.color = const Color(0xFFFF9849).withValues(alpha: borderOpacity);

      for (final slot in _highlightSlots) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            slot.originX * tileSize,
            slot.originY * tileSize,
            slot.width * tileSize,
            slot.height * tileSize,
          ),
          const Radius.circular(6),
        );

        canvas.drawRRect(rect, _pulseFillPaint);
        canvas.drawRRect(rect, _pulseBorderPaint);
      }
    }
  }
}
