import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MigrationService {
  static const String _globalMigratedKey = 'firebase_migrated_global';
  static const String _savedMigratedPrefix = 'firebase_migrated_saved_';

  static Future<void> migrateSharedData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_globalMigratedKey) == true) return;

    try {
      final businesses = _decodeMapList(prefs, 'businesses');
      final reviews = _decodeMapList(prefs, 'reviews');
      final services = _decodeServices(prefs, 'services');

      await _upsertBusinesses(businesses);
      await _upsertReviews(reviews);
      await _upsertServices(services);

      await prefs.setBool(_globalMigratedKey, true);
    } catch (_) {
      // Ignore migration failures; app should still run.
    }
  }

  static Future<void> migrateUserDataIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_savedMigratedPrefix${user.uid}';
    if (prefs.getBool(key) == true) return;

    final saved = prefs.getStringList('saved_businesses') ?? [];
    if (saved.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'savedBusinessIds': FieldValue.arrayUnion(saved),
      }, SetOptions(merge: true));
    }

    await prefs.setBool(key, true);
  }

  static List<Map<String, dynamic>> _decodeMapList(
    SharedPreferences prefs,
    String key,
  ) {
    final list = prefs.getStringList(key);
    if (list != null) {
      return list
          .map((e) => Map<String, dynamic>.from(jsonDecode(e)))
          .toList();
    }

    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  static Map<String, List<Map<String, dynamic>>> _decodeServices(
    SharedPreferences prefs,
    String key,
  ) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return {};
    return decoded.map(
      (k, v) => MapEntry(
        k,
        (v as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      ),
    );
  }

  static Future<void> _upsertBusinesses(
    List<Map<String, dynamic>> businesses,
  ) async {
    if (businesses.isEmpty) return;
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('businesses');

    WriteBatch batch = firestore.batch();
    int count = 0;
    for (final business in businesses) {
      final id =
          (business['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
              .toString();
      business['id'] = id;
      batch.set(collection.doc(id), business, SetOptions(merge: true));
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = firestore.batch();
        count = 0;
      }
    }
    if (count > 0) {
      await batch.commit();
    }
  }

  static Future<void> _upsertReviews(
    List<Map<String, dynamic>> reviews,
  ) async {
    if (reviews.isEmpty) return;
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('reviews');

    WriteBatch batch = firestore.batch();
    int count = 0;
    for (final review in reviews) {
      final id =
          (review['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
              .toString();
      review['id'] = id;
      batch.set(collection.doc(id), review, SetOptions(merge: true));
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = firestore.batch();
        count = 0;
      }
    }
    if (count > 0) {
      await batch.commit();
    }
  }

  static Future<void> _upsertServices(
    Map<String, List<Map<String, dynamic>>> services,
  ) async {
    if (services.isEmpty) return;
    final firestore = FirebaseFirestore.instance;
    for (final entry in services.entries) {
      final businessId = entry.key;
      for (final service in entry.value) {
        final id =
            (service['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
                .toString();
        service['id'] = id;
        await firestore
            .collection('businesses')
            .doc(businessId)
            .collection('services')
            .doc(id)
            .set(service, SetOptions(merge: true));
      }
    }
  }
}
