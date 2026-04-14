import 'package:flutter/material.dart';

/// A small responsive wrapper that keeps the app's UI visually identical on
/// small screens but centers and constrains content on wide screens (web).
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 900,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // If narrow (mobile), just return child as-is to preserve exact layout.
    if (width <= maxWidth) return child;

    // For wider screens (web, desktop) center and constrain the content so the
    // UI doesn't stretch too wide while keeping proportions similar.
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: child,
        ),
      ),
    );
  }
}
