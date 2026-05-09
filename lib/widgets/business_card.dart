import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';

class BusinessCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool showSaveButton;
  final bool isSaved;
  final VoidCallback? onSave;
  final BorderRadius borderRadius;
  final bool showCategoryPill;
  final bool useComfortableDensity;

  const BusinessCard({
    super.key,
    required this.item,
    this.showSaveButton = false,
    this.isSaved = false,
    this.onSave,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.showCategoryPill = true,
    this.useComfortableDensity = false,
  });

  static const Color _cardBorderColor = Color(0xFFDCEBE5);
  static const Color _titleColor = Color(0xFF1F2431);
  static const Color _subtitleColor = Color(0xFF8C929D);
  static const Color _accentColor = Color(0xFF3C9E92);
  static const Color _pillTextColor = Color(0xFF243447);

  static double recommendedMainAxisExtent(
    double cardWidth, {
    double textScale = 1.0,
    bool comfortable = false,
  }) {
    final density = (cardWidth / 185).clamp(0.82, 1.08).toDouble();
    final compact = cardWidth < 170;
    final adjustedTextScale = textScale.clamp(1.0, 1.4).toDouble();
    final verticalPadding = (10.5 * density).clamp(8.0, 14.0).toDouble();
    final bottomPadding = (verticalPadding * 0.65).clamp(6.0, 10.0).toDouble();
    final sectionGap = (7.0 * density).clamp(5.0, 8.5).toDouble();
    final metaGap = (5.0 * density).clamp(4.0, 6.5).toDouble();
    final titleSize = (cardWidth * (comfortable ? 0.09 : 0.095))
        .clamp(14.0, 18.0)
        .toDouble();
    final detailSize = (cardWidth * 0.073).clamp(10.8, 12.8).toDouble();
    final metaSize = (cardWidth * 0.069).clamp(10.0, 12.2).toDouble();
    final lineIconSize = (cardWidth * 0.085).clamp(12.0, 16.0).toDouble();
    final imageAspectRatio = comfortable
        ? 1.34
        : compact
        ? 1.30
        : 1.24;
    final imageHeight = cardWidth / imageAspectRatio;
    final titleHeight = titleSize * adjustedTextScale * 1.2;
    final detailHeight = detailSize * adjustedTextScale * 1.2;
    final metaLineHeight = math.max(
      lineIconSize,
      metaSize * adjustedTextScale * 1.25,
    );
    final contentHeight =
        verticalPadding +
        bottomPadding +
        titleHeight +
        sectionGap +
        detailHeight +
        (sectionGap + 1) +
        metaLineHeight +
        metaGap +
        metaLineHeight;

    return imageHeight + contentHeight + 18;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final comfortable = useComfortableDensity || screenWidth >= 900;
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
    final category = _textValue(item['category']);
    final subcategory = _textValue(item['subcategory']);
    final address = _textValue(item['address']);
    final timing = _textValue(item['timing']);
    final name = _textValue(item['name'], fallback: 'Unnamed Business');
    final imagePath = _textValue(item['image']);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screenWidth / 2;
        final density = ((cardWidth / 185) * (1 + ((textScale - 1) * 0.15)))
            .clamp(0.82, 1.16)
            .toDouble();
        final compact = cardWidth < 170;
        final contentHorizontalPadding = (11.5 * density)
            .clamp(9.0, 15.0)
            .toDouble();
        final contentVerticalPadding = (10.5 * density)
            .clamp(8.0, 14.0)
            .toDouble();
        final contentBottomPadding = (contentVerticalPadding * 0.65)
            .clamp(6.0, 10.0)
            .toDouble();
        final sectionGap = (7.0 * density).clamp(5.0, 8.5).toDouble();
        final metaGap = (5.0 * density).clamp(4.0, 6.5).toDouble();
        final overlayInset = (9.5 * density).clamp(8.0, 12.0).toDouble();
        final titleSize = (cardWidth * (comfortable ? 0.09 : 0.095))
            .clamp(14.0, 18.0)
            .toDouble();
        final detailSize = (cardWidth * 0.073).clamp(10.8, 12.8).toDouble();
        final metaSize = (cardWidth * 0.069).clamp(10.0, 12.2).toDouble();
        final lineIconSize = (cardWidth * 0.085).clamp(12.0, 16.0).toDouble();
        final pillIconSize = (cardWidth * 0.088).clamp(13.0, 16.0).toDouble();
        final pillFontSize = (cardWidth * 0.074).clamp(11.0, 12.8).toDouble();
        final pillHorizontalPadding = (10.5 * density)
            .clamp(8.5, 12.0)
            .toDouble();
        final pillVerticalPadding = (7.5 * density).clamp(6.0, 8.0).toDouble();
        final pillMaxWidth = (cardWidth * 0.62).clamp(110.0, 160.0).toDouble();
        final saveButtonSize = (cardWidth * 0.24).clamp(34.0, 42.0).toDouble();
        final saveIconSize = (cardWidth * 0.14).clamp(18.0, 24.0).toDouble();
        final imageIconSize = (cardWidth * 0.19).clamp(28.0, 34.0).toDouble();
        final imageAspectRatio = comfortable
            ? 1.34
            : compact
            ? 1.30
            : 1.24;

        return Card(
          margin: EdgeInsets.zero,
          color: Colors.white,
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: const BorderSide(color: _cardBorderColor, width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: imageAspectRatio,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _buildImage(imagePath, iconSize: imageIconSize),
                    ),
                    if (showCategoryPill && category.isNotEmpty)
                      Positioned(
                        left: overlayInset,
                        top: overlayInset,
                        child: _CategoryPill(
                          label: category,
                          icon: _categoryIcon(category),
                          iconSize: pillIconSize,
                          fontSize: pillFontSize,
                          maxWidth: pillMaxWidth,
                          horizontalPadding: pillHorizontalPadding,
                          verticalPadding: pillVerticalPadding,
                        ),
                      ),
                    if (showSaveButton)
                      Positioned(
                        right: overlayInset,
                        top: overlayInset,
                        child: _SaveButton(
                          isSaved: isSaved,
                          buttonSize: saveButtonSize,
                          iconSize: saveIconSize,
                          onPressed: onSave,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  contentHorizontalPadding,
                  contentVerticalPadding,
                  contentHorizontalPadding,
                  contentBottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleSize,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                    if (category.isNotEmpty || subcategory.isNotEmpty) ...[
                      SizedBox(height: sectionGap),
                      Row(
                        children: [
                          if (category.isNotEmpty)
                            Flexible(
                              child: Text(
                                category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: detailSize,
                                  fontWeight: FontWeight.w600,
                                  color: _accentColor,
                                ),
                              ),
                            ),
                          if (category.isNotEmpty &&
                              subcategory.isNotEmpty) ...[
                            SizedBox(width: sectionGap),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFFC7CCD4),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: sectionGap),
                          ],
                          if (subcategory.isNotEmpty)
                            Flexible(
                              child: Text(
                                subcategory,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: detailSize,
                                  color: _subtitleColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (address.isNotEmpty || timing.isNotEmpty)
                      SizedBox(height: sectionGap + 1),
                    if (address.isNotEmpty)
                      _MetaLine(
                        icon: Icons.location_on_rounded,
                        text: address,
                        iconSize: lineIconSize,
                        fontSize: metaSize,
                        gap: metaGap,
                      ),
                    if (timing.isNotEmpty) ...[
                      SizedBox(height: metaGap),
                      _MetaLine(
                        icon: Icons.access_time_rounded,
                        text: timing,
                        iconSize: lineIconSize,
                        fontSize: metaSize,
                        gap: metaGap,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(String imagePath, {required double iconSize}) {
    final placeholder = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade200, Colors.grey.shade100],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          size: iconSize,
          color: Colors.grey.shade500,
        ),
      ),
    );

    if (imagePath.isEmpty) {
      return placeholder;
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    final imageFile = File(imagePath);
    if (!imageFile.existsSync()) {
      return placeholder;
    }

    return Image.file(
      imageFile,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  String _textValue(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  IconData _categoryIcon(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('shop')) return Icons.shopping_bag_rounded;
    if (normalized.contains('food') || normalized.contains('dining')) {
      return Icons.restaurant_rounded;
    }
    if (normalized.contains('health') || normalized.contains('beauty')) {
      return Icons.favorite_rounded;
    }
    if (normalized.contains('education')) return Icons.school_rounded;
    if (normalized.contains('service')) return Icons.handyman_rounded;
    if (normalized.contains('entertainment')) return Icons.movie_rounded;
    if (normalized.contains('online')) return Icons.language_rounded;
    return Icons.storefront_rounded;
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconSize;
  final double fontSize;
  final double maxWidth;
  final double horizontalPadding;
  final double verticalPadding;

  const _CategoryPill({
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.fontSize,
    required this.maxWidth,
    required this.horizontalPadding,
    required this.verticalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: BusinessCard._pillTextColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: BusinessCard._pillTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaved;
  final double buttonSize;
  final double iconSize;
  final VoidCallback? onPressed;

  const _SaveButton({
    required this.isSaved,
    required this.buttonSize,
    required this.iconSize,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        constraints: BoxConstraints.tightFor(
          width: buttonSize,
          height: buttonSize,
        ),
        padding: EdgeInsets.zero,
        icon: Icon(
          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          size: iconSize,
          color: isSaved
              ? const Color(0xFFE74C5B)
              : BusinessCard._pillTextColor,
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final double iconSize;
  final double fontSize;
  final double gap;

  const _MetaLine({
    required this.icon,
    required this.text,
    required this.iconSize,
    required this.fontSize,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize, color: const Color(0xFFB4BAC4)),
        SizedBox(width: gap),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              color: BusinessCard._subtitleColor,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}
