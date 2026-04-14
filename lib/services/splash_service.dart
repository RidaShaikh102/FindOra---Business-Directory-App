import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../firebase_options.dart';

import '../services/analytics_service.dart';
import '../services/migration_service.dart';

class SplashService {
  static Future<SharedPreferences> initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Initialize analytics and migrations
    await AnalyticsService.incrementAppOpens();
    await MigrationService.migrateSharedData();
    await MigrationService.migrateUserDataIfNeeded();

    await dotenv.load();

    return prefs;
  }
}
