import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static const String _keyAppOpens = 'app_open_count';
  static const String _keyScreenViews = 'analytics_screen_views';
  static const String _keyActions = 'analytics_actions';
  static const String _analyticsDocPath = 'analytics_counters/global';

  static FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static Future<int> incrementAppOpens() async {
    final next = await _incrementLocalInt(_keyAppOpens);
    await _logAppOpen();
    await _incrementFirestoreField('appOpens', 1);
    return next;
  }

  static Future<int> getAppOpens() async {
    final remote = await _getRemoteMap();
    if (remote != null && remote['appOpens'] is num) {
      return (remote['appOpens'] as num).toInt();
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAppOpens) ?? 0;
  }

  static Future<Map<String, int>> getScreenViews() async {
    final remote = await _getRemoteMap();
    final views = remote?['screenViews'];
    if (views is Map) {
      return _mapToInt(views);
    }
    return _getLocalMap(_keyScreenViews);
  }

  static Future<Map<String, int>> getActions() async {
    final remote = await _getRemoteMap();
    final actions = remote?['actions'];
    if (actions is Map) {
      return _mapToInt(actions);
    }
    return _getLocalMap(_keyActions);
  }

  static Future<void> logScreenView(String name) async {
    await _incrementLocal(_keyScreenViews, name);
    await _logScreen(name);
    await _incrementFirestoreNested('screenViews', name);
  }

  static Future<void> logAction(String name) async {
    await _incrementLocal(_keyActions, name);
    await _logActionEvent(name);
    await _incrementFirestoreNested('actions', name);
  }

  static Future<Map<String, int>> _getLocalMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    final decoded = Map<String, dynamic>.from(jsonDecode(raw));
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  static Future<void> _incrementLocal(String key, String name) async {
    final map = await _getLocalMap(key);
    map[name] = (map[name] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(map));
  }

  static Future<int> _incrementLocalInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(key) ?? 0;
    final next = current + 1;
    await prefs.setInt(key, next);
    return next;
  }

  static Future<void> _logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (_) {}
  }

  static Future<void> _logScreen(String name) async {
    try {
      await _analytics.logScreenView(screenName: name);
    } catch (_) {}
  }

  static Future<void> _logActionEvent(String name) async {
    try {
      await _analytics.logEvent(name: 'app_action', parameters: {'name': name});
    } catch (_) {}
  }

  static Future<void> _logEvent(
    String name,
    Map<String, Object> parameters,
  ) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }

  static Future<void> logBusinessViewed(
    String businessId, {
    String? businessName,
  }) async {
    await _incrementLocal(_keyActions, 'business_viewed');
    await _logEvent('business_viewed', {
      'businessId': businessId,
      'businessName': businessName ?? '',
    });
    await _incrementFirestoreNested('actions', 'business_viewed');
  }

  static Future<void> logReviewWritten(
    String businessId, {
    String? businessName,
  }) async {
    await _incrementLocal(_keyActions, 'review_written');
    await _logEvent('review_written', {
      'businessId': businessId,
      'businessName': businessName ?? '',
    });
    await _incrementFirestoreNested('actions', 'review_written');
  }

  static Future<void> _incrementFirestoreField(String field, int by) async {
    try {
      await _firestore.doc(_analyticsDocPath).set({
        field: FieldValue.increment(by),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<void> _incrementFirestoreNested(
    String root,
    String name,
  ) async {
    final key = _sanitizeKey(name);
    final fieldPath = '$root.$key';
    try {
      await _firestore.doc(_analyticsDocPath).set({
        fieldPath: FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> _getRemoteMap() async {
    try {
      final doc = await _firestore.doc(_analyticsDocPath).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  static Map<String, int> _mapToInt(Map<dynamic, dynamic> raw) {
    final result = <String, int>{};
    raw.forEach((key, value) {
      result[key.toString()] = (value as num).toInt();
    });
    return result;
  }

  static String _sanitizeKey(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}
