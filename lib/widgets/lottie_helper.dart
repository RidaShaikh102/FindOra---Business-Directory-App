import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class LottieOrPlaceholder extends StatelessWidget {
  final String assetPath;
  final double? height;

  const LottieOrPlaceholder({super.key, required this.assetPath, this.height});

  @override
  Widget build(BuildContext context) {
    // Ensure we always load from the correct assets root defined in pubspec.yaml
    final String fullPath = 'lib/assets/$assetPath';

    return FutureBuilder<String>(
      future: rootBundle.loadString(fullPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height ?? 200,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          debugPrint(
            'Failed to load Lottie asset `$fullPath`: ${snapshot.error}`',
          );
          return SizedBox(
            height: height ?? 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.animation, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Animation unavailable',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Asset loaded successfully — show Lottie
        return Lottie.asset(fullPath, height: height);
      },
    );
  }
}
