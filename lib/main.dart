import 'package:findora/screens/onboarding_screen.dart';
import 'package:findora/screens/login_screen.dart';
import 'package:findora/screens/role_gate.dart';
import 'package:findora/screens/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:findora/widgets/responsive_wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:findora/providers/onboarding_provider.dart';
import 'package:findora/providers/auth_provider.dart';
import 'package:findora/services/splash_service.dart';
import 'package:findora/services/deep_link_service.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:findora/screens/shared_profile_screen.dart';

Future<void> main() async {
  final prefs = await SplashService.initializeApp();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const FindOraApp(),
    ),
  );
}

class FindOraApp extends StatefulWidget {
  const FindOraApp({super.key});

  @override
  State<FindOraApp> createState() => _FindOraAppState();
}

class _FindOraAppState extends State<FindOraApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinking();
  }

  void _initDeepLinking() {
    DeepLinkService().init((Uri uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // Handle different deep link patterns
    if (uri.scheme == 'findora' && uri.host == 'business') {
      final businessId = uri.queryParameters['id'];
      if (businessId != null) {
        _navigateToBusiness(businessId);
      }
    } else if (uri.pathSegments.length >= 2 &&
        uri.pathSegments[0] == 'business') {
      final businessId = uri.pathSegments[1];
      _navigateToBusiness(businessId);
    } else if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'profile') {
      _navigateToSharedProfile(uri);
    }
  }

  Future<void> _navigateToBusiness(String businessId) async {
    // Wait for the app to be ready
    await Future.delayed(const Duration(milliseconds: 500));

    if (_navigatorKey.currentState != null) {
      final storage = LocalStorageService();
      final business =
          await storage.getBusinessById(businessId) ?? <String, dynamic>{};

      if (business.isNotEmpty) {
        _navigatorKey.currentState!.pushNamed('/business', arguments: business);
      }
    }
  }

  Future<void> _navigateToSharedProfile(Uri uri) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_navigatorKey.currentState == null) return;

    final usernameFromPath = uri.pathSegments.length >= 2
        ? Uri.decodeComponent(uri.pathSegments[1])
        : '';
    final username = usernameFromPath.isNotEmpty
        ? usernameFromPath
        : (uri.queryParameters['username'] ?? 'FindOra User');
    final role = uri.queryParameters['role'] ?? '';
    final city = uri.queryParameters['city'] ?? '';

    _navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) =>
            SharedProfileScreen(username: username, role: role, city: city),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'FindOra',
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          ResponsiveWrapper(child: child ?? const SizedBox()),
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: const Color(0xFFF7F9FB),
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
          accentColor: const Color(0xFF66D6C6),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF137B75),
          elevation: 0.5,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: const InitialSplashScreen(),
      routes: {
        '/business': (context) {
          final business =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return DetailScreen(item: business);
        },
      },
    );
  }

  @override
  void dispose() {
    DeepLinkService().dispose();
    super.dispose();
  }
}

// 1. Initial Splash Screen (for initial loading/delay)
class InitialSplashScreen extends StatefulWidget {
  const InitialSplashScreen({super.key});

  @override
  State<InitialSplashScreen> createState() => _InitialSplashScreenState();
}

class _InitialSplashScreenState extends State<InitialSplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Add a minimum delay for the splash screen visibility
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // ➡️ Navigate to the AppWrapper which decides Onboarding/Login/Home
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AppWrapper()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash Screen UI with logo
    return Scaffold(
      backgroundColor: const Color(0xFF0A2D3F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x4D009688),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.asset('lib/assets/logo.png', width: 120),
            ),
            const SizedBox(height: 20),
            const Text(
              'FindOra',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Discover. Connect. Explore.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Colors.teal,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. AppWrapper (decides final destination: Onboarding, Login, or MainScreen)
class AppWrapper extends ConsumerWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);
    final authState = ref.watch(authProvider);

    // 3. Check the onboarding state first
    if (!onboardingCompleted) {
      // 🚀 Go to Onboarding if not completed
      return OnboardingScreen(
        onFinish: () async {
          await ref
              .read(onboardingCompletedProvider.notifier)
              .completeOnboarding();
        },
      );
    }

    // 🔒 Check AuthService login state
    switch (authState) {
      case AuthState.checking:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.teal)),
        );
      case AuthState.authenticated:
        return const RoleGate();
      case AuthState.unauthenticated:
        return const LoginScreen();
    }
  }
}
