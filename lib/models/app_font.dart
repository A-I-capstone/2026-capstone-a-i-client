/// Represents a selectable font option in the settings screen.
class AppFont {
  /// The human-readable label shown in the UI.
  final String displayName;

  /// The fontFamily string used in [TextStyle].
  /// null means the system/platform default font.
  final String? fontFamily;

  const AppFont({required this.displayName, this.fontFamily});
}
