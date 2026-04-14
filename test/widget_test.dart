import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:findora/main.dart';
import 'package:findora/screens/detail_screen.dart';

void main() {
  // setUpAll commented to avoid Firebase init errors in test
  // await SplashService.initializeApp();

  group('Existing Tests', () {
    testWidgets('FindOraApp splash screen renders', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: FindOraApp(),
          ),
        ),
      );

      expect(find.byType(FindOraApp), findsOneWidget);
      expect(find.text('FindOra'), findsOneWidget);
    });
  });

  const Map<String, dynamic> mockBusiness = {
    'id': 'test-id-1',
    'name': 'Test Restaurant',
    'image': 'https://via.placeholder.com/400x300/cccccc/969696?text=Test',
    'address': '123 Test Street, Test City',
    'contact': '1234567890',
    'whatsapp': '1234567890',
    'website': 'https://test.com',
    'liveLocation': 'https://maps.google.com?q=test',
    'subcategory': 'Italian Restaurant',
    'timing': '9AM - 10PM',
    'description': 'Test business.',
    'category': 'Restaurant',
    'ownerEmail': 'owner@test.com',
    'instagram': 'https://instagram.com/test',
    'facebook': 'https://facebook.com/test',
    'latitude': 40.7128,
    'longitude': -74.0060,
  };

  group('DetailScreen Golden Tests', () {
    testWidgets('DetailScreen loading state golden', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: DetailScreen(item: mockBusiness)),
      );

      // First pump shows shimmer loading
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('detail_screen_loading.golden.png'),
      );
    });

    testWidgets('DetailScreen loaded state golden', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: DetailScreen(item: mockBusiness)),
      );

      // Pump and settle for loaded state
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('detail_screen_loaded.golden.png'),
      );

      // Verify key UI elements
      expect(find.text('Test Restaurant'), findsOneWidget);
      expect(find.text('Quick actions'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });
  });
}
