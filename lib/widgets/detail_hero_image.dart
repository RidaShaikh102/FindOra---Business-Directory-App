import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DetailHeroImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onBack;
  final VoidCallback onToggleSave;
  final bool isSaved;

  const DetailHeroImage({
    super.key,
    required this.imageUrl,
    required this.onBack,
    required this.onToggleSave,
    required this.isSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 350,
          width: double.infinity,
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) =>
                      Image.asset('lib/assets/logo.png', fit: BoxFit.cover),
                )
              : Image.asset('lib/assets/logo.png', fit: BoxFit.cover),
        ),
        Container(
          height: 350,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0x80000000),
                const Color(0x33000000),
                Colors.transparent,
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleIcon(icon: Icons.arrow_back, onTap: onBack),
                _circleIcon(
                  icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                  onTap: onToggleSave,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleIcon({required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(242),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.teal.withAlpha(76), width: 1),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: const Color(0xFF0A2D3F), size: 20),
          ),
        ),
      ),
    );
  }
}
