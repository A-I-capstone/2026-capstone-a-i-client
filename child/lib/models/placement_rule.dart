import 'village_item.dart';

/// Allowed surface types for item placement on the village map.
enum PlacementSurface {
  grassOnly,
  roadOnly,
  any,
}

/// Flexible placement rule defining footprint, allowed surface, and snapping behavior.
class PlacementRule {
  final int tileWidth;
  final int tileHeight;
  final PlacementSurface allowedSurface;
  final bool snapToPlot;

  const PlacementRule({
    required this.tileWidth,
    required this.tileHeight,
    required this.allowedSurface,
    this.snapToPlot = false,
  });

  /// Default placement rules per category if not overridden by specific item configuration.
  factory PlacementRule.forCategory(VillageItemCategory category) {
    switch (category) {
      case VillageItemCategory.building:
        return const PlacementRule(
          tileWidth: 3,
          tileHeight: 2,
          allowedSurface: PlacementSurface.grassOnly,
          snapToPlot: true,
        );
      case VillageItemCategory.nature:
      case VillageItemCategory.facility:
      case VillageItemCategory.fence:
        return const PlacementRule(
          tileWidth: 1,
          tileHeight: 1,
          allowedSurface: PlacementSurface.roadOnly,
          snapToPlot: false,
        );
    }
  }

  /// Deserialize from JSON map if item JSON overrides placement rules.
  factory PlacementRule.fromJson(Map<String, dynamic> json) {
    final surfaceStr = json['allowedSurface'] as String? ?? 'any';
    final surface = PlacementSurface.values.firstWhere(
      (e) => e.name == surfaceStr,
      orElse: () => PlacementSurface.any,
    );

    return PlacementRule(
      tileWidth: (json['tileWidth'] as num?)?.toInt() ?? 1,
      tileHeight: (json['tileHeight'] as num?)?.toInt() ?? 1,
      allowedSurface: surface,
      snapToPlot: json['snapToPlot'] as bool? ?? false,
    );
  }

  /// Serialize to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'tileWidth': tileWidth,
      'tileHeight': tileHeight,
      'allowedSurface': allowedSurface.name,
      'snapToPlot': snapToPlot,
    };
  }
}
