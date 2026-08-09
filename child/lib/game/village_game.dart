import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/placed_item.dart';
import '../viewmodels/village_viewmodel.dart';
import 'components/placed_item_component.dart';
import 'components/tile_map_component.dart';

/// Flame game instance managing town rendering, gesture navigation (zoom/pan), and tap interactions.
class VillageGame extends FlameGame with TapCallbacks, ScaleDetector {
  final VillageViewModel viewModel;

  late final TileMapComponent _tileMapComponent;
  final List<PlacedItemComponent> _itemComponents = [];

  double _startZoom = 1.0;

  VillageGame({required this.viewModel});

  @override
  Color backgroundColor() => const Color(0xFF7EC850);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _tileMapComponent = TileMapComponent();
    await world.add(_tileMapComponent);

    // Restrict camera to map boundaries (fixed bounds regardless of zoom)
    camera.setBounds(
      Rectangle.fromLTWH(
        0,
        0,
        _tileMapComponent.size.x,
        _tileMapComponent.size.y,
      ),
      considerViewport: false,
    );

    // Center camera on map center
    final mapCenter = _tileMapComponent.size / 2;
    camera.moveTo(mapCenter);

    _syncPlacedItems();
    _updatePlacementHighlights();

    viewModel.addListener(_onViewModelUpdated);
  }

  @override
  void onRemove() {
    viewModel.removeListener(_onViewModelUpdated);
    super.onRemove();
  }

  void _onViewModelUpdated() {
    _syncPlacedItems();
    _updatePlacementHighlights();
  }

  /// Synchronizes Flame components with current ViewModel's placed items list.
  void _syncPlacedItems() {
    for (final comp in _itemComponents) {
      comp.removeFromParent();
    }
    _itemComponents.clear();

    for (final placed in viewModel.placedItems) {
      final definition = viewModel.getItemById(placed.itemId);
      if (definition != null) {
        final isHighlighted =
            viewModel.pendingSellInstanceId == placed.instanceId;
        final comp = PlacedItemComponent(
          placedItem: placed,
          itemDefinition: definition,
          isHighlightedForSale: isHighlighted,
          onTapPlaced: _handleItemTap,
        );
        _itemComponents.add(comp);
        world.add(comp);
      }
    }
  }

  /// Updates pulse highlights on TileMapComponent during item placement mode.
  void _updatePlacementHighlights() {
    if (viewModel.isPlacingMode) {
      final slots = viewModel.getAvailablePlacementSlots();
      _tileMapComponent.setHighlightSlots(slots);
    } else {
      _tileMapComponent.setHighlightSlots([]);
    }
  }

  void _handleItemTap(PlacedItem placed) {
    if (viewModel.isSellOpen) {
      // Sell Mode: 1st tap highlights, 2nd tap confirms sale/delete
      viewModel.handleSellTap(placed);
    } else if (viewModel.isEditOpen) {
      // Edit Mode: Tapping a placed item returns it to inventory
      viewModel.returnItem(placed);
    }
  }

  // ---------------------------------------------------------------------------
  // Gesture Handlers: Pan (Drag) & Pinch Zoom via ScaleDetector
  // ---------------------------------------------------------------------------

  @override
  void onScaleStart(ScaleStartInfo info) {
    _startZoom = camera.viewfinder.zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    // Single or multi-finger pan
    camera.moveBy(-info.delta.global / camera.viewfinder.zoom);

    // Two-finger pinch zoom
    if (info.scale.global.x != 1.0) {
      final targetZoom = (_startZoom * info.scale.global.x).clamp(0.7, 1.8);
      camera.viewfinder.zoom = targetZoom;
    }
  }

  // ---------------------------------------------------------------------------
  // Tap Event Handler
  // ---------------------------------------------------------------------------

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);

    final worldPoint = camera.globalToLocal(event.canvasPosition);
    final tileX = (worldPoint.x / TileMapComponent.tileSize).floor();
    final tileY = (worldPoint.y / TileMapComponent.tileSize).floor();

    if (tileX < 0 ||
        tileX >= TileMapComponent.mapWidthTiles ||
        tileY < 0 ||
        tileY >= TileMapComponent.mapHeightTiles) {
      if (viewModel.isSellOpen) {
        viewModel.clearSellSelection();
      }
      return;
    }

    if (viewModel.isPlacingMode) {
      viewModel.confirmPlace(tileX, tileY);
    } else if (viewModel.isSellOpen) {
      viewModel.clearSellSelection();
    } else if (viewModel.isShopOpen || viewModel.isEditOpen) {
      viewModel.closeDrawers();
    }
  }
}
