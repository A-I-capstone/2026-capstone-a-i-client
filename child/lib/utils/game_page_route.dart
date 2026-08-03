import 'package:flutter/material.dart';

/// Custom PageRoute providing smooth game screen transitions.
///
/// Designed for easy customization and modular replacement (e.g. Fade, Zoom, Slide, Circular Wipe).
class GamePageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  GamePageRoute({
    required this.builder,
    super.settings,
    super.transitionDuration = const Duration(milliseconds: 400),
    super.reverseTransitionDuration = const Duration(milliseconds: 350),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return buildGameTransition(
              context: context,
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
        );

  /// Modular transition builder function.
  /// Replace or enhance this implementation to change the visual transition across the app.
  static Widget buildGameTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    // Smooth cubic easing for entry and exit
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    // Fade in / out transition combined with very subtle scale
    final scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(curvedAnimation);

    return FadeTransition(
      opacity: curvedAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: child,
      ),
    );
  }
}
