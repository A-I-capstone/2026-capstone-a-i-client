import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/placed_item.dart';
import '../models/village_item.dart';
import '../models/village_state.dart';
import '../services/village/base_village_repository.dart';
import '../services/village/shop_item_loader.dart';
import '../services/village/village_placement_validator.dart';

/// ViewModel managing state and business logic for the Village Decorating mini-game.
class VillageViewModel extends ChangeNotifier {
  final BaseVillageRepository _repository;

  VillageState _state = VillageState.empty();
  List<VillageItem> _shopItems = [];
  bool _isLoading = true;
  bool _isShopOpen = false;
  bool _isEditOpen = false;
  bool _isSellOpen = false;

  VillageItemCategory _selectedShopCategory = VillageItemCategory.building;
  VillageItemCategory _selectedEditCategory = VillageItemCategory.building;

  /// Currently selected item ID pending placement on tile map (Option B: Place Mode).
  /// Null if place mode is inactive.
  String? _pendingItemId;

  /// Currently selected instanceId pending sale confirmation (1st tap).
  /// Null if no item is highlighted for sale.
  String? _pendingSellInstanceId;

  String _userId = '';
  String _profileId = '';

  VillageViewModel({required this._repository});

  // Getters
  VillageState get state => _state;
  int get coins => _state.coins;
  List<String> get inventory => _state.inventory;
  List<PlacedItem> get placedItems => _state.placedItems;
  List<VillageItem> get shopItems => _shopItems;
  bool get isLoading => _isLoading;
  bool get isShopOpen => _isShopOpen;
  bool get isEditOpen => _isEditOpen;
  bool get isSellOpen => _isSellOpen;
  VillageItemCategory get selectedShopCategory => _selectedShopCategory;
  VillageItemCategory get selectedEditCategory => _selectedEditCategory;
  String? get pendingItemId => _pendingItemId;
  bool get isPlacingMode => _pendingItemId != null;
  String? get pendingSellInstanceId => _pendingSellInstanceId;

  /// Returns a map of all available item definitions keyed by item ID.
  Map<String, VillageItem> getItemDefinitionsMap() {
    return {for (final item in _shopItems) item.id: item};
  }

  /// Initialises village state for the given user and profile.
  Future<void> initialize(String userId, String profileId) async {
    _userId = userId;
    _profileId = profileId;
    _isLoading = true;
    notifyListeners();

    try {
      final items = await ShopItemLoader.loadItems();
      _shopItems = items;

      if (_userId.isNotEmpty && _profileId.isNotEmpty) {
        _state = await _repository.loadVillageState(_userId, _profileId);
      }

      // Small delay to ensure smooth loading transition
      await Future.delayed(const Duration(milliseconds: 600));
    } catch (e) {
      // Gracefully degrade using default initial state
      _state = VillageState.empty();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns [VillageItem] definition by ID.
  VillageItem? getItemById(String itemId) {
    for (final item in _shopItems) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  /// Calculates available placement slots for the pending item.
  List<PlacementSlot> getAvailablePlacementSlots() {
    final itemId = _pendingItemId;
    if (itemId == null) return [];

    final item = getItemById(itemId);
    if (item == null) return [];

    return VillagePlacementValidator.getAvailableSlots(
      item: item,
      placedItems: _state.placedItems,
      itemDefinitions: getItemDefinitionsMap(),
    );
  }

  /// Purchase an item from shop.
  /// Deducts coins, adds item to inventory, updates UI immediately, and saves in background.
  void buyItem(VillageItem item) {
    if (_state.coins < item.price) return;

    final updatedCoins = _state.coins - item.price;
    final updatedInventory = List<String>.from(_state.inventory)..add(item.id);

    _state = _state.copyWith(
      coins: updatedCoins,
      inventory: updatedInventory,
    );

    notifyListeners();
    _saveAsync();
  }

  /// Starts item placement mode (Option B).
  void startPlacing(String itemId) {
    if (!_state.inventory.contains(itemId)) return;
    _pendingItemId = itemId;
    _isEditOpen = false;
    _isShopOpen = false;
    _isSellOpen = false;
    _pendingSellInstanceId = null;
    notifyListeners();
  }

  /// Cancels item placement mode.
  void cancelPlacing() {
    _pendingItemId = null;
    notifyListeners();
  }

  /// Confirms placing the pending item at target tile coordinates (tileX, tileY).
  /// Validates grid surface and occupancy via [VillagePlacementValidator].
  void confirmPlace(int tileX, int tileY) {
    final itemId = _pendingItemId;
    if (itemId == null) return;

    final item = getItemById(itemId);
    if (item == null) {
      _pendingItemId = null;
      notifyListeners();
      return;
    }

    final resolvedSlot = VillagePlacementValidator.resolvePlacement(
      item: item,
      tappedX: tileX,
      tappedY: tileY,
      placedItems: _state.placedItems,
      itemDefinitions: getItemDefinitionsMap(),
    );

    if (resolvedSlot == null) {
      // Tapped tile is invalid or occupied for this item type
      return;
    }

    final inventoryIndex = _state.inventory.indexOf(itemId);
    if (inventoryIndex == -1) {
      _pendingItemId = null;
      notifyListeners();
      return;
    }

    final updatedInventory = List<String>.from(_state.inventory)
      ..removeAt(inventoryIndex);

    final instanceId = 'inst_${DateTime.now().microsecondsSinceEpoch}';
    final newPlaced = PlacedItem(
      instanceId: instanceId,
      itemId: itemId,
      tileX: resolvedSlot.originX,
      tileY: resolvedSlot.originY,
    );

    final updatedPlaced = List<PlacedItem>.from(_state.placedItems)
      ..add(newPlaced);

    _state = _state.copyWith(
      inventory: updatedInventory,
      placedItems: updatedPlaced,
    );

    _pendingItemId = null;
    notifyListeners();
    _saveAsync();
  }

  /// Returns a placed item from map back into inventory.
  void returnItem(PlacedItem placed) {
    final updatedPlaced = List<PlacedItem>.from(_state.placedItems)
      ..removeWhere((e) => e.instanceId == placed.instanceId);

    final updatedInventory = List<String>.from(_state.inventory)
      ..add(placed.itemId);

    _state = _state.copyWith(
      inventory: updatedInventory,
      placedItems: updatedPlaced,
    );

    notifyListeners();
    _saveAsync();
  }

  /// Handles tap on a placed item while in Sell Mode.
  /// 1st tap: highlights item with blinking effect.
  /// 2nd tap: confirms sale and permanently deletes item from map with coin refund.
  void handleSellTap(PlacedItem placed) {
    if (!_isSellOpen) return;

    if (_pendingSellInstanceId == placed.instanceId) {
      // 2nd tap: confirm delete and refund
      final itemDef = getItemById(placed.itemId);
      final refundAmount = itemDef?.price ?? 0;

      final updatedPlaced = List<PlacedItem>.from(_state.placedItems)
        ..removeWhere((e) => e.instanceId == placed.instanceId);

      _state = _state.copyWith(
        coins: _state.coins + refundAmount,
        placedItems: updatedPlaced,
      );

      _pendingSellInstanceId = null;
      notifyListeners();
      _saveAsync();
    } else {
      // 1st tap: highlight item for sale
      _pendingSellInstanceId = placed.instanceId;
      notifyListeners();
    }
  }

  /// Clears sell selection if tapping outside.
  void clearSellSelection() {
    if (_pendingSellInstanceId != null) {
      _pendingSellInstanceId = null;
      notifyListeners();
    }
  }

  // Drawer & Mode Toggles
  void toggleShop() {
    _isShopOpen = !_isShopOpen;
    if (_isShopOpen) {
      _isEditOpen = false;
      _isSellOpen = false;
      _pendingItemId = null;
      _pendingSellInstanceId = null;
    }
    notifyListeners();
  }

  void toggleEdit() {
    _isEditOpen = !_isEditOpen;
    if (_isEditOpen) {
      _isShopOpen = false;
      _isSellOpen = false;
      _pendingItemId = null;
      _pendingSellInstanceId = null;
    }
    notifyListeners();
  }

  void toggleSell() {
    _isSellOpen = !_isSellOpen;
    if (_isSellOpen) {
      _isShopOpen = false;
      _isEditOpen = false;
      _pendingItemId = null;
      _pendingSellInstanceId = null;
    } else {
      _pendingSellInstanceId = null;
    }
    notifyListeners();
  }

  void closeDrawers() {
    _isShopOpen = false;
    _isEditOpen = false;
    _isSellOpen = false;
    _pendingSellInstanceId = null;
    notifyListeners();
  }

  void selectShopCategory(VillageItemCategory category) {
    _selectedShopCategory = category;
    notifyListeners();
  }

  void selectEditCategory(VillageItemCategory category) {
    _selectedEditCategory = category;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Debug Helpers (To be removed before release)
  // ---------------------------------------------------------------------------

  /// Debug: Add coins.
  void debugAddCoins(int amount) {
    _state = _state.copyWith(coins: _state.coins + amount);
    notifyListeners();
    _saveAsync();
  }

  /// Debug: Reset village state back to initial empty state.
  void debugResetVillage() {
    _state = VillageState.empty();
    _pendingItemId = null;
    _pendingSellInstanceId = null;
    _isShopOpen = false;
    _isEditOpen = false;
    _isSellOpen = false;
    notifyListeners();
    _saveAsync();
  }

  /// Fire-and-forget background asynchronous save to Firestore.
  void _saveAsync() {
    if (_userId.isEmpty || _profileId.isEmpty) return;
    unawaited(_repository.saveVillageState(_userId, _profileId, _state));
  }
}
