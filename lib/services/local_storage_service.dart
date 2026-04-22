import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

class LocalStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _businesses =>
      _firestore.collection('businesses');
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _claims =>
      _firestore.collection('claims');

  Future<void> saveBusiness(Map<String, dynamic> business) async {
    final id =
        (business['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
            .toString();
    business['id'] = id;
    await _businesses.doc(id).set(business, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getBusinesses() async {
    final snapshot = await _businesses.get();
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = data['id'] ?? doc.id;
      return data;
    }).toList();
  }

  Future<void> saveBusinesses(List<Map<String, dynamic>> businesses) async {
    if (businesses.isEmpty) return;
    WriteBatch batch = _firestore.batch();
    int count = 0;
    for (final business in businesses) {
      final id =
          (business['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
              .toString();
      business['id'] = id;
      batch.set(_businesses.doc(id), business, SetOptions(merge: true));
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) {
      await batch.commit();
    }
  }

  Future<List<Map<String, dynamic>>> getVisibleBusinesses({
    String? role,
    String? email,
  }) async {
    final businesses = await getBusinesses();
    if (role == 'super_admin') return businesses;

    bool isApproved(Map<String, dynamic> b) {
      final status = b['status'];
      return status == null || status == 'approved';
    }

    if (role == 'owner' && email != null && email.isNotEmpty) {
      return businesses
          .where((b) => isApproved(b) || b['ownerEmail'] == email)
          .toList();
    }
    return businesses.where((b) => isApproved(b)).toList();
  }

  Future<void> updateBusiness(
    String id,
    Map<String, dynamic> updatedBusiness,
  ) async {
    updatedBusiness['id'] = id;
    await _businesses.doc(id).set(updatedBusiness, SetOptions(merge: true));
  }

  Future<void> deleteBusiness(String id) async {
    await _businesses.doc(id).delete();
  }

  Future<void> saveSavedBusiness(String businessId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _users.doc(user.uid).set({
      'savedBusinessIds': FieldValue.arrayUnion([businessId]),
    }, SetOptions(merge: true));
  }

  Future<void> removeSavedBusiness(String businessId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _users.doc(user.uid).set({
      'savedBusinessIds': FieldValue.arrayRemove([businessId]),
    }, SetOptions(merge: true));
  }

  Future<List<String>> getSavedBusinesses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final doc = await _users.doc(user.uid).get();
    if (!doc.exists) return [];
    final data = doc.data();
    final list = (data?['savedBusinessIds'] as List?) ?? [];
    return list.map((e) => e.toString()).toList();
  }

  Future<void> saveReview(Map<String, dynamic> review) async {
    final id =
        (review['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
            .toString();
    review['id'] = id;
    await _reviews.doc(id).set(review, SetOptions(merge: true));
  }

  Future<void> saveClaim(Map<String, dynamic> claim) async {
    final id = (claim['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
        .toString();
    claim['id'] = id;
    claim['status'] = claim['status'] ?? 'pending';
    claim['timestamp'] = FieldValue.serverTimestamp();
    await _claims.doc(id).set(claim, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getClaims() async {
    final snapshot = await _claims.orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = data['id'] ?? doc.id;
      if (data['timestamp'] is Timestamp) {
        data['timestamp'] =
            (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
      }
      return data;
    }).toList();
  }

  Future<void> updateClaimStatus(String claimId, String status) async {
    await _claims.doc(claimId).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> approveClaim(String claimId) async {
    final claimSnapshot = await _claims.doc(claimId).get();
    if (!claimSnapshot.exists) return;

    final claim = Map<String, dynamic>.from(claimSnapshot.data()!);
    final businessId = claim['businessId']?.toString() ?? '';
    final userId = claim['userId']?.toString() ?? '';
    if (businessId.isEmpty || userId.isEmpty) return;

    final userSnapshot = await _users.doc(userId).get();
    final userData = userSnapshot.exists
        ? Map<String, dynamic>.from(userSnapshot.data()!)
        : <String, dynamic>{};
    final ownerEmail = userData['email']?.toString() ?? '';

    final businessRef = _businesses.doc(businessId);
    final claimRef = _claims.doc(claimId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(claimRef, {
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.set(businessRef, {
        'ownerId': userId,
        'ownerEmail': ownerEmail,
        'verifiedBusiness': true,
      }, SetOptions(merge: true));
    });
  }

  Future<List<Map<String, dynamic>>> getReviews() async {
    try {
      AppLogger.i('🔍 getReviews() - Fetching ALL reviews from Firestore');
      final snapshot = await _reviews.get();
      final reviews = snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = data['id'] ?? doc.id;
            if (data['timestamp'] is Timestamp) {
              data['timestamp'] =
                  (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
            }
            return data;
          })
          .where((r) => r['hidden'] != true)
          .toList();

      AppLogger.i(
        '✅ getReviews() SUCCESS: ${snapshot.docs.length} docs, ${reviews.length} visible reviews',
      );
      if (reviews.isNotEmpty) {
        AppLogger.d(
          '📄 Sample review: ${reviews.first['userName'] ?? 'anon'} - ${reviews.first['businessName'] ?? 'no biz'}',
        );
      }
      return reviews;
    } catch (e, stackTrace) {
      AppLogger.e('❌ getReviews() ERROR: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<void> saveReviews(List<Map<String, dynamic>> reviews) async {
    if (reviews.isEmpty) return;
    WriteBatch batch = _firestore.batch();
    int count = 0;
    for (final review in reviews) {
      final id =
          (review['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
              .toString();
      review['id'] = id;
      batch.set(_reviews.doc(id), review, SetOptions(merge: true));
      count++;
      if (count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) {
      await batch.commit();
    }
  }

  Future<void> deleteReview(String reviewId) async {
    await _reviews.doc(reviewId).delete();
  }

  Future<void> saveService(
    String businessId,
    Map<String, dynamic> service,
  ) async {
    final id =
        (service['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
            .toString();
    service['id'] = id;
    await _businesses
        .doc(businessId)
        .collection('services')
        .doc(id)
        .set(service, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getServices(String businessId) async {
    final snapshot = await _businesses
        .doc(businessId)
        .collection('services')
        .get();
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = data['id'] ?? doc.id;
      return data;
    }).toList();
  }

  Future<Map<String, List<Map<String, dynamic>>>> getAllServices() async {
    final businesses = await getBusinesses();
    final Map<String, List<Map<String, dynamic>>> result = {};
    for (final business in businesses) {
      final id = business['id']?.toString();
      if (id == null || id.isEmpty) continue;
      result[id] = await getServices(id);
    }
    return result;
  }

  Future<void> deleteService(String businessId, String serviceId) async {
    await _businesses
        .doc(businessId)
        .collection('services')
        .doc(serviceId)
        .delete();
  }

  Future<List<Map<String, dynamic>>> getReviewsByBusiness(
    String businessId, {
    Object? startAfter,
    int limit = 10,
  }) async {
    try {
      AppLogger.i(
        '🔍 getReviewsByBusiness(bizId: $businessId, limit: $limit, startAfter: $startAfter)',
      );

      // First try the efficient query with composite index
      try {
        Query<Map<String, dynamic>> query = _reviews
            .where('businessId', isEqualTo: businessId)
            .orderBy('timestamp', descending: true)
            .limit(limit);

        if (startAfter != null) {
          query = query.startAfter([startAfter]);
        }

        AppLogger.d(
          '📡 Executing composite query: where(businessId == $businessId) orderBy(timestamp desc)',
        );
        final snapshot = await query.get();

        final reviews = snapshot.docs
            .map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = data['id'] ?? doc.id;
              if (data['timestamp'] is Timestamp) {
                data['timestamp'] =
                    (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
              }
              return data;
            })
            .where((r) => r['hidden'] != true)
            .toList();

        AppLogger.i(
          '✅ getReviewsByBusiness SUCCESS (composite): ${snapshot.docs.length} docs fetched, ${reviews.length} visible for biz $businessId',
        );
        if (reviews.isNotEmpty) {
          AppLogger.d(
            '📄 Sample: ${reviews.first['userName'] ?? 'anon'} rating=${reviews.first['rating']}',
          );
        }
        return reviews;
      } catch (e) {
        AppLogger.w(
          '⚠️ Composite query failed (likely missing index), falling back to fetch-all: $e',
        );

        // Fallback: fetch all reviews and filter/sort in memory
        final allSnapshot = await _reviews.get();
        final List<Map<String, dynamic>> allReviews = allSnapshot.docs
            .map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = data['id'] ?? doc.id;
              if (data['timestamp'] is Timestamp) {
                data['timestamp'] =
                    (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
              }
              return data;
            })
            .where((r) => r['businessId'] == businessId && r['hidden'] != true)
            .toList();

        // Sort by timestamp descending
        allReviews.sort(
          (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
        );

        // Apply pagination
        final startIndex = startAfter != null
            ? allReviews.indexWhere((r) => r['timestamp'] == startAfter) + 1
            : 0;
        final endIndex = startIndex + limit;
        final List<Map<String, dynamic>> paginatedReviews =
            startIndex < allReviews.length
            ? allReviews.sublist(
                startIndex,
                endIndex.clamp(0, allReviews.length),
              )
            : <Map<String, dynamic>>[];

        AppLogger.i(
          '✅ getReviewsByBusiness SUCCESS (fallback): ${allReviews.length} total, ${paginatedReviews.length} paginated for biz $businessId',
        );
        return paginatedReviews;
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '❌ getReviewsByBusiness(bizId: $businessId) ERROR: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
