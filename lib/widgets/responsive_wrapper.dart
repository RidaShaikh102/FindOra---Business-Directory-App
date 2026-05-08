import 'package:flutter/material.dart';
import 'package:findora/widgets/responsive_layout.dart';

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
    return ResponsivePageContainer(
      maxWidth: maxWidth < 1100 ? 1100 : maxWidth,
      child: child,
    );
  }
}
