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
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.showCategoryPill = false,
    this.useComfortableDensity = false,
  });

  @override
  Widget build(BuildContext context) {
    final double scale = MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.3);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final comfortable = useComfortableDensity || screenWidth >= 900;
    final contentPadding = comfortable ? 12.0 : 8.0;
    final titleSize = comfortable ? 14.0 : 13.0;
    final metaSize = comfortable ? 11.0 : 10.0;
    final iconSize = comfortable ? 13.0 : 12.0;

    Widget? overlayWidget;
    if (showCategoryPill) {
      overlayWidget = Positioned(
        left: 6,
        right: 6,
        top: 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (item['category'] != null &&
                item['category'].toString().isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: comfortable ? 8 : 6,
                  vertical: comfortable ? 4 : 3,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.85),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category_rounded,
                      size: iconSize,
                      color: const Color(0xFF0A2D3F),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        item['category'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: metaSize,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0A2D3F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (showSaveButton)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.9),
                ),
                child: IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.red : Colors.teal,
                    size: comfortable ? 20 : 18,
                  ),
                  onPressed: onSave,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ),
          ],
        ),
      );
    } else if (showSaveButton) {
      overlayWidget = Positioned(
        top: 6,
        right: 6,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.9),
          ),
          child: IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? Colors.red : Colors.teal,
              size: 18,
            ),
            onPressed: onSave,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ),
      );
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: Colors.teal.withOpacity(0.25), width: 1),
      ),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Square Image (1:1)
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius.topLeft.x),
                    topRight: Radius.circular(borderRadius.topRight.x),
                  ),
                  child:
                      item['image'] != null &&
                          item['image'].toString().isNotEmpty
                      ? (item['image'].toString().startsWith('http')
                            ? Image.network(
                                item['image'].toString(),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Image.file(
                                File(item['image'].toString()),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ))
                      : Container(
                          color: Colors.grey.shade200,
                  child: Icon(
                            Icons.storefront_outlined,
                    size: comfortable ? 36 : 32,
                            color: Colors.grey,
                          ),
                        ),
                ),
                if (overlayWidget != null) overlayWidget,
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(borderRadius.topLeft.x),
                          topRight: Radius.circular(borderRadius.topRight.x),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Compact text section
          Padding(
            padding: EdgeInsets.fromLTRB(
              contentPadding,
              comfortable ? 8 : 6,
              contentPadding,
              2,
            ),
            child: Text(
              item['name']?.toString() ?? 'Unnamed',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: titleSize * scale,
              ),
            ),
          ),
          if ((item['category'] != null &&
                  item['category'].toString().isNotEmpty) ||
              (item['subcategory'] != null &&
                  item['subcategory'].toString().isNotEmpty))
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: contentPadding,
                vertical: 1,
              ),
              child: Row(
                children: [
                  if (item['category'] != null &&
                      item['category'].toString().isNotEmpty)
                    Expanded(
                      child: Text(
                        item['category'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: metaSize * scale,
                          color: Colors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if ((item['category'] != null &&
                          item['category'].toString().isNotEmpty) &&
                      (item['subcategory'] != null &&
                          item['subcategory'].toString().isNotEmpty))
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: metaSize * scale,
                        color: Colors.grey,
                      ),
                    ),
                  if (item['subcategory'] != null &&
                      item['subcategory'].toString().isNotEmpty)
                    Expanded(
                      child: Text(
                        item['subcategory'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: metaSize * scale,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              contentPadding,
              1,
              contentPadding,
              comfortable ? 8 : 6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item['address'] != null &&
                    item['address'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.place_rounded,
                          size: iconSize,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item['address'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: metaSize * scale,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (item['timing'] != null &&
                    item['timing'].toString().isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: iconSize,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item['timing'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: metaSize * scale,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
