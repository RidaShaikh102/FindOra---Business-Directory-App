import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/lottie_helper.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinish;

  const OnboardingScreen({super.key, this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final Color themeColor = const Color(0xFF0A2D3F);

  final List<Map<String, String>> _onboardingData = [
    {
      'image': 'lottie/onboarding1.json',
      'title': 'Discover Local Businesses',
      'description':
          'Find trusted services and products near you effortlessly.',
    },
    {
      'image': 'lottie/onboarding2.json',
      'title': 'Save Your Favorites',
      'description': 'Keep track of businesses you love and revisit anytime.',
    },
    {
      'image': 'lottie/onboarding3.json',
      'title': 'Connect and Explore',
      'description':
          'Get directions, call, or visit websites directly from the app.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_currentPage < _onboardingData.length - 1) {
        _controller.animateToPage(
          _currentPage + 1,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        );
      } else {
        _timer?.cancel();
      }
    });
  }

  void _startApp() {
    _timer?.cancel();
    widget.onFinish?.call();
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _onboardingData.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 22 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? themeColor : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(
    String lottiePath,
    String title,
    String description,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallHeight = constraints.maxHeight < 650;
        final double lottieHeight = isSmallHeight
            ? constraints.maxHeight * 0.35
            : 270;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LottieOrPlaceholder(
                  assetPath: lottiePath,
                  height: lottieHeight,
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallHeight ? 22 : 26,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallHeight ? 14 : 16,
                    height: 1.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLastPage = _currentPage == _onboardingData.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _onboardingData.length,
              onPageChanged: (index) {
                _timer?.cancel();
                _startAutoScroll();
                setState(() => _currentPage = index);
              },
              itemBuilder: (_, index) {
                final data = _onboardingData[index];
                return _buildOnboardingPage(
                  data['image']!,
                  data['title']!,
                  data['description']!,
                );
              },
            ),

            // Dots + (optional) Get Started Button
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDots(),
                    const SizedBox(height: 25),
                    if (isLastPage)
                      ElevatedButton(
                        onPressed: _startApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 55,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Get Started",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
