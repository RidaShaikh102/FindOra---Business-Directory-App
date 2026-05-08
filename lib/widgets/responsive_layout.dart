import 'package:flutter/material.dart';

enum ScreenSize { compact, medium, expanded }

class ResponsiveLayout {
  static const double compactMaxWidth = 599;
  static const double mediumMaxWidth = 1023;

  static ScreenSize screenSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= compactMaxWidth) return ScreenSize.compact;
    if (width <= mediumMaxWidth) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  static bool isCompact(BuildContext context) =>
      screenSize(context) == ScreenSize.compact;

  static bool isMediumOrLarger(BuildContext context) =>
      screenSize(context) != ScreenSize.compact;

  static bool isExpanded(BuildContext context) =>
      screenSize(context) == ScreenSize.expanded;

  static double horizontalPadding(BuildContext context) {
    switch (screenSize(context)) {
      case ScreenSize.compact:
        return 12;
      case ScreenSize.medium:
        return 20;
      case ScreenSize.expanded:
        return 28;
    }
  }

  static int adaptiveGridCount(
    BuildContext context, {
    int compact = 1,
    int medium = 2,
    int expanded = 3,
  }) {
    switch (screenSize(context)) {
      case ScreenSize.compact:
        return compact;
      case ScreenSize.medium:
        return medium;
      case ScreenSize.expanded:
        return expanded;
    }
  }
}

class ResponsivePageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsivePageContainer({
    super.key,
    required this.child,
    this.maxWidth = 1280,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final pagePadding =
        padding ??
        EdgeInsets.symmetric(horizontal: ResponsiveLayout.horizontalPadding(context));
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: pagePadding, child: child),
      ),
    );
  }
}

class ResponsivePanelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ResponsivePanelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
