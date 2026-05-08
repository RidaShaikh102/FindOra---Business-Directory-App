import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/marketplace_config.dart';
import '../models/order_model.dart';
import '../models/service_model.dart';
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
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  Future<void> saveBusiness(Map<String, dynamic> business) async {
    final payload = _normalizeBusinessPayload(business);
    final id =
        (payload['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
            .toString();
    payload['id'] = id;
    await _businesses.doc(id).set(payload, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getBusinesses() async {
    final snapshot = await _businesses.get();
    return snapshot.docs.map(_mapBusinessDoc).toList();
  }

  Future<Map<String, dynamic>?> getBusinessById(String businessId) async {
    if (businessId.trim().isEmpty) return null;
    final snapshot = await _businesses.doc(businessId).get();
    if (!snapshot.exists) return null;
    final data = Map<String, dynamic>.from(snapshot.data()!);
    data['id'] = data['id'] ?? snapshot.id;
    return data;
  }

  Future<bool> businessNameExists(
    String name, {
    String? excludeBusinessId,
  }) async {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    final normalizedSnapshot = await _businesses
        .where('normalizedName', isEqualTo: normalized)
        .limit(2)
        .get();
    final normalizedMatch = normalizedSnapshot.docs.any(
      (doc) => doc.id != excludeBusinessId,
    );
    if (normalizedMatch) return true;

    final exactSnapshot = await _businesses
        .where('name', isEqualTo: name.trim())
        .limit(2)
        .get();
    return exactSnapshot.docs.any((doc) => doc.id != excludeBusinessId);
  }

  Future<List<Map<String, dynamic>>> getBusinessesByOwner(
    String ownerEmail,
  ) async {
    final normalizedEmail = ownerEmail.trim();
    if (normalizedEmail.isEmpty) return <Map<String, dynamic>>[];

    final snapshot = await _businesses
        .where('ownerEmail', isEqualTo: normalizedEmail)
        .get();
    return snapshot.docs.map(_mapBusinessDoc).toList();
  }

  Future<int> getBusinessCount() async {
    final snapshot = await _businesses.count().get();
    return snapshot.count ?? 0;
  }

  Future<void> saveBusinesses(List<Map<String, dynamic>> businesses) async {
    if (businesses.isEmpty) return;
    WriteBatch batch = _firestore.batch();
    int count = 0;
    for (final business in businesses) {
      final payload = _normalizeBusinessPayload(business);
      final id =
          (payload['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
              .toString();
      payload['id'] = id;
      batch.set(_businesses.doc(id), payload, SetOptions(merge: true));
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
    if (role == 'super_admin') return getBusinesses();

    final batches = await Future.wait(<Future<List<Map<String, dynamic>>>>[
      _getApprovedBusinesses(),
      if (role == 'owner' && email != null && email.trim().isNotEmpty)
        getBusinessesByOwner(email),
    ]);

    final merged = <String, Map<String, dynamic>>{};
    for (final batch in batches) {
      for (final business in batch) {
        final id = business['id']?.toString();
        if (id == null || id.isEmpty) continue;
        merged[id] = business;
      }
    }
    return merged.values.toList();
  }

  Future<void> updateBusiness(
    String id,
    Map<String, dynamic> updatedBusiness,
  ) async {
    final payload = _normalizeBusinessPayload(updatedBusiness);
    payload['id'] = id;
    await _businesses.doc(id).set(payload, SetOptions(merge: true));
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
    review['hidden'] = review['hidden'] as bool? ?? false;
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

  Future<List<Map<String, dynamic>>> getReviews({
    bool includeHidden = false,
  }) async {
    try {
      AppLogger.i('🔍 getReviews() - Fetching reviews from Firestore');
      Query<Map<String, dynamic>> query = _reviews.orderBy(
        'timestamp',
        descending: true,
      );
      if (!includeHidden) {
        query = query.where('hidden', isEqualTo: false);
      }
      final snapshot = await query.get();
      final reviews = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = data['id'] ?? doc.id;
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] =
              (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
        }
        return data;
      }).toList();

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

  Future<List<Map<String, dynamic>>> getReviewsByUserEmail(
    String userEmail, {
    bool includeHidden = false,
  }) async {
    final normalizedEmail = userEmail.trim();
    if (normalizedEmail.isEmpty) return <Map<String, dynamic>>[];

    Query<Map<String, dynamic>> query = _reviews
        .where('userEmail', isEqualTo: normalizedEmail)
        .orderBy('timestamp', descending: true);
    if (!includeHidden) {
      query = query.where('hidden', isEqualTo: false);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(_mapReviewDoc).toList();
  }

  Future<List<Map<String, dynamic>>> getReviewsByOwnerEmail(
    String ownerEmail, {
    bool includeHidden = false,
  }) async {
    final normalizedEmail = ownerEmail.trim();
    if (normalizedEmail.isEmpty) return <Map<String, dynamic>>[];

    Query<Map<String, dynamic>> query = _reviews
        .where('businessOwnerEmail', isEqualTo: normalizedEmail)
        .orderBy('timestamp', descending: true);
    if (!includeHidden) {
      query = query.where('hidden', isEqualTo: false);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(_mapReviewDoc).toList();
  }

  Future<List<Map<String, dynamic>>> getAllReviewsByBusiness(
    String businessId, {
    bool includeHidden = false,
  }) async {
    if (businessId.trim().isEmpty) return <Map<String, dynamic>>[];

    Query<Map<String, dynamic>> query = _reviews
        .where('businessId', isEqualTo: businessId)
        .orderBy('timestamp', descending: true);
    if (!includeHidden) {
      query = query.where('hidden', isEqualTo: false);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(_mapReviewDoc).toList();
  }

  Future<int> getReviewCount({bool includeHidden = false}) async {
    Query<Map<String, dynamic>> query = _reviews;
    if (!includeHidden) {
      query = query.where('hidden', isEqualTo: false);
    }
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getReviewCountForBusiness(String businessId) async {
    if (businessId.trim().isEmpty) return 0;

    final snapshot = await _reviews
        .where('businessId', isEqualTo: businessId)
        .where('hidden', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<double> getAverageRatingForBusiness(String businessId) async {
    if (businessId.trim().isEmpty) return 0;

    final reviews = await getAllReviewsByBusiness(businessId);
    if (reviews.isEmpty) return 0;

    final total = reviews.fold<double>(
      0,
      (sum, review) => sum + ((_asDouble(review['rating']) ?? 0)),
    );
    return total / reviews.length;
  }

  Future<List<Map<String, dynamic>>> getReviewPageByBusiness(
    String businessId, {
    int? startAfter,
    int limit = 10,
  }) async {
    if (businessId.trim().isEmpty) return <Map<String, dynamic>>[];

    Query<Map<String, dynamic>> query = _reviews
        .where('businessId', isEqualTo: businessId)
        .where('hidden', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfter([startAfter]);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(_mapReviewDoc).toList();
  }

  Future<void> saveReviews(List<Map<String, dynamic>> reviews) async {
    if (reviews.isEmpty) return;
    WriteBatch batch = _firestore.batch();
    int count = 0;
    for (final review in reviews) {
      review['hidden'] = review['hidden'] as bool? ?? false;
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
    final payload = _normalizeServicePayload(businessId, service);
    final id =
        (payload['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
            .toString();
    payload['id'] = id;
    await _businesses
        .doc(businessId)
        .collection('services')
        .doc(id)
        .set(payload, SetOptions(merge: true));
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

  Future<List<ServiceModel>> getServiceModels(String businessId) async {
    final services = await getServices(businessId);
    return services
        .map(
          (service) => ServiceModel.fromJson(service, businessId: businessId),
        )
        .toList();
  }

  Future<List<ServiceModel>> getServiceModelsByIds(
    String businessId,
    Iterable<String> serviceIds,
  ) async {
    final ids = serviceIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (ids.isEmpty) return <ServiceModel>[];

    final serviceDocs = <Map<String, dynamic>>[];
    final idList = ids.toList(growable: false);

    for (var index = 0; index < idList.length; index += 30) {
      final chunk = idList.sublist(index, (index + 30).clamp(0, idList.length));
      final snapshot = await _businesses
          .doc(businessId)
          .collection('services')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      serviceDocs.addAll(
        snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = data['id'] ?? doc.id;
          return data;
        }),
      );
    }

    final servicesById = <String, ServiceModel>{
      for (final service in serviceDocs)
        service['id'].toString(): ServiceModel.fromJson(
          service,
          businessId: businessId,
        ),
    };

    return idList
        .map((id) => servicesById[id])
        .whereType<ServiceModel>()
        .toList();
  }

  Future<Map<String, List<Map<String, dynamic>>>> getAllServices() async {
    final Map<String, List<Map<String, dynamic>>> result = {};
    final snapshot = await _firestore.collectionGroup('services').get();
    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = data['id'] ?? doc.id;
      final businessId =
          data['businessId']?.toString() ?? doc.reference.parent.parent?.id;
      if (businessId == null || businessId.isEmpty) continue;
      result.putIfAbsent(businessId, () => <Map<String, dynamic>>[]).add(data);
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

  Future<void> saveOrder(Map<String, dynamic> order) async {
    final payload = Map<String, dynamic>.from(order);
    final id =
        (payload['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
            .toString();
    final now = DateTime.now().millisecondsSinceEpoch;
    final items = ((payload['items'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final history = ((payload['statusHistory'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    payload['id'] = id;
    payload['status'] = payload['status']?.toString().isNotEmpty == true
        ? payload['status']
        : 'pending';
    payload['ownerNote'] = payload['ownerNote']?.toString() ?? '';
    payload['estimatedReadyAt'] = _asInt(payload['estimatedReadyAt']) ?? 0;
    payload['createdAt'] = _asInt(payload['createdAt']) ?? now;
    payload['updatedAt'] = now;
    payload['itemCount'] =
        _asInt(payload['itemCount']) ?? _countOrderItems(items);
    payload['subtotal'] =
        _asDouble(payload['subtotal']) ?? _sumOrderItems(items);
    payload['deliveryFee'] = _asDouble(payload['deliveryFee']) ?? 0;
    final sub = _asDouble(payload['subtotal']) ?? 0;
    final fee = _asDouble(payload['deliveryFee']) ?? 0;
    var total = _asDouble(payload['totalAmount']) ?? 0;
    if (total <= 0) {
      total = sub + fee;
    }
    payload['totalAmount'] = total;
    payload['paymentMethod'] = payload['paymentMethod']?.toString() ?? 'COD';
    payload['deliveryMode'] = payload['deliveryMode']?.toString() ?? 'local';
    payload['userCity'] = payload['userCity']?.toString() ?? '';
    payload['sellerCity'] = payload['sellerCity']?.toString() ?? '';
    payload['sellerId'] = payload['sellerId']?.toString() ?? '';
    payload['userId'] =
        payload['userId']?.toString() ??
        payload['customerId']?.toString() ??
        '';
    final rate = _asDouble(payload['commissionRate']) ?? 0;
    payload['commissionRate'] = rate > 0 ? rate : kDefaultCommissionRate;
    payload['commission'] = _asDouble(payload['commission']) ?? 0;
    payload['sellerEarning'] = _asDouble(payload['sellerEarning']) ?? 0;
    payload['courierCarrier'] = payload['courierCarrier']?.toString() ?? '';
    payload['courierTrackingId'] =
        payload['courierTrackingId']?.toString() ?? '';
    payload['deliveredAt'] = _asInt(payload['deliveredAt']) ?? 0;
    payload['items'] = items;
    payload['statusHistory'] = history.isNotEmpty
        ? history
        : [
            OrderStatusEventModel(
              status: payload['status'].toString(),
              timestamp: payload['createdAt'] as int,
              actor: 'customer',
              message: 'Order placed',
            ).toJson(),
          ];

    await _orders.doc(id).set(payload, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getOrdersForOwner(
    String ownerEmail,
  ) async {
    if (ownerEmail.trim().isEmpty) return <Map<String, dynamic>>[];

    final snapshot = await _orders
        .where('ownerEmail', isEqualTo: ownerEmail)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(_mapOrderDoc).toList();
  }

  Future<List<Map<String, dynamic>>> getOrdersByCustomer(
    String customerEmail,
  ) async {
    if (customerEmail.trim().isEmpty) return <Map<String, dynamic>>[];

    final snapshot = await _orders
        .where('customerEmail', isEqualTo: customerEmail)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(_mapOrderDoc).toList();
  }

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String actor = 'owner',
    String? message,
  }) async {
    final orderRef = _orders.doc(orderId);
    final snapshot = await orderRef.get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.data()!);
    final previousStatus = data['status']?.toString() ?? '';
    final now = DateTime.now().millisecondsSinceEpoch;
    final history = ((data['statusHistory'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    if (previousStatus != status || history.isEmpty) {
      history.add(
        OrderStatusEventModel(
          status: status,
          timestamp: now,
          actor: actor,
          message: message ?? _defaultOrderStatusMessage(status, actor),
        ).toJson(),
      );
    }

    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': now,
      'statusHistory': history,
    };

    await orderRef.set(updates, SetOptions(merge: true));
  }

  /// Manual courier fields until a carrier API is connected.
  Future<void> updateOrderCourierMeta(
    String orderId, {
    required String courierCarrier,
    required String courierTrackingId,
    String actor = 'owner',
  }) async {
    final orderRef = _orders.doc(orderId);
    final snapshot = await orderRef.get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.data()!);
    final now = DateTime.now().millisecondsSinceEpoch;
    final history = ((data['statusHistory'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    history.add(
      OrderStatusEventModel(
        status: data['status']?.toString() ?? 'pending',
        timestamp: now,
        actor: actor,
        message: 'Courier / tracking updated',
      ).toJson(),
    );

    await orderRef.set({
      'courierCarrier': courierCarrier.trim(),
      'courierTrackingId': courierTrackingId.trim(),
      'updatedAt': now,
      'statusHistory': history,
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> watchOrdersForOwner(String ownerEmail) {
    if (ownerEmail.trim().isEmpty) {
      return Stream<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]);
    }
    return _orders
        .where('ownerEmail', isEqualTo: ownerEmail)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map(_mapOrderDoc).toList();
        });
  }

  Stream<List<Map<String, dynamic>>> watchOrdersByCustomer(
    String customerEmail,
  ) {
    if (customerEmail.trim().isEmpty) {
      return Stream<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]);
    }
    return _orders
        .where('customerEmail', isEqualTo: customerEmail)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map(_mapOrderDoc).toList();
        });
  }

  Stream<List<Map<String, dynamic>>> watchAllOrders() {
    return _orders.orderBy('createdAt', descending: true).snapshots().map((
      snap,
    ) {
      return snap.docs.map(_mapOrderDoc).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final snapshot = await _orders.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(_mapOrderDoc).toList();
  }

  Future<void> updateOrderFulfillment(
    String orderId, {
    String? ownerNote,
    int? estimatedReadyAt,
    String actor = 'owner',
  }) async {
    final orderRef = _orders.doc(orderId);
    final snapshot = await orderRef.get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.data()!);
    final now = DateTime.now().millisecondsSinceEpoch;
    final history = ((data['statusHistory'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final nextOwnerNote =
        ownerNote?.trim() ?? data['ownerNote']?.toString() ?? '';
    final nextEta = estimatedReadyAt ?? (_asInt(data['estimatedReadyAt']) ?? 0);
    final currentOwnerNote = data['ownerNote']?.toString() ?? '';
    final currentEta = _asInt(data['estimatedReadyAt']) ?? 0;

    if (nextOwnerNote != currentOwnerNote && nextOwnerNote.isNotEmpty) {
      history.add(
        OrderStatusEventModel(
          status: data['status']?.toString() ?? 'pending',
          timestamp: now,
          actor: actor,
          message: 'Owner added fulfillment note',
        ).toJson(),
      );
    }

    if (nextEta != currentEta && nextEta > 0) {
      history.add(
        OrderStatusEventModel(
          status: data['status']?.toString() ?? 'pending',
          timestamp: now,
          actor: actor,
          message: 'Estimated ready time updated',
        ).toJson(),
      );
    }

    await orderRef.set({
      'ownerNote': nextOwnerNote,
      'estimatedReadyAt': nextEta,
      'updatedAt': now,
      'statusHistory': history,
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getReviewsByBusiness(
    String businessId, {
    int? startAfter,
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

  Future<List<Map<String, dynamic>>> _getApprovedBusinesses() async {
    final results = await Future.wait(<Future<List<Map<String, dynamic>>>>[
      _queryBusinesses(_businesses.where('status', isEqualTo: 'approved')),
      _queryBusinesses(_businesses.where('status', isNull: true)),
    ]);

    final merged = <String, Map<String, dynamic>>{};
    for (final batch in results) {
      for (final business in batch) {
        final id = business['id']?.toString();
        if (id == null || id.isEmpty) continue;
        merged[id] = business;
      }
    }

    return merged.values.toList();
  }

  Future<List<Map<String, dynamic>>> _queryBusinesses(
    Query<Map<String, dynamic>> query,
  ) async {
    final snapshot = await query.get();
    return snapshot.docs.map(_mapBusinessDoc).toList();
  }

  Map<String, dynamic> _normalizeBusinessPayload(
    Map<String, dynamic> business,
  ) {
    final payload = Map<String, dynamic>.from(business);
    final normalizedName =
        payload['name']?.toString().trim().toLowerCase() ?? '';
    if (normalizedName.isNotEmpty) {
      payload['normalizedName'] = normalizedName;
    }
    return payload;
  }

  Map<String, dynamic> _mapBusinessDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = Map<String, dynamic>.from(doc.data());
    data['id'] = data['id'] ?? doc.id;
    return data;
  }

  Map<String, dynamic> _mapReviewDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = Map<String, dynamic>.from(doc.data());
    data['id'] = data['id'] ?? doc.id;
    if (data['timestamp'] is Timestamp) {
      data['timestamp'] =
          (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
    }
    return data;
  }

  Map<String, dynamic> _normalizeServicePayload(
    String businessId,
    Map<String, dynamic> service,
  ) {
    final payload = Map<String, dynamic>.from(service);
    final now = DateTime.now().millisecondsSinceEpoch;
    payload['businessId'] = businessId;
    payload['name'] = payload['name']?.toString().trim() ?? '';
    payload['description'] = payload['description']?.toString().trim() ?? '';
    payload['image'] = payload['image']?.toString() ?? '';
    payload['businessName'] = payload['businessName']?.toString() ?? '';
    payload['ownerEmail'] = payload['ownerEmail']?.toString() ?? '';
    payload['category'] = payload['category']?.toString() ?? '';
    payload['price'] = _asDouble(payload['price']) ?? 0;
    payload['isAvailable'] = payload['isAvailable'] as bool? ?? true;
    payload['createdAt'] = _asInt(payload['createdAt']) ?? now;
    payload['updatedAt'] = now;
    return payload;
  }

  Map<String, dynamic> _mapOrderDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = Map<String, dynamic>.from(doc.data());
    data['id'] = data['id'] ?? doc.id;
    data['createdAt'] = _asInt(data['createdAt']) ?? 0;
    data['updatedAt'] = _asInt(data['updatedAt']) ?? 0;
    data['deliveredAt'] = _asInt(data['deliveredAt']) ?? 0;
    data['itemCount'] = _asInt(data['itemCount']) ?? 0;
    data['subtotal'] = _asDouble(data['subtotal']) ?? 0;
    data['deliveryFee'] = _asDouble(data['deliveryFee']) ?? 0;
    data['totalAmount'] = _asDouble(data['totalAmount']) ?? 0;
    data['commission'] = _asDouble(data['commission']) ?? 0;
    data['sellerEarning'] = _asDouble(data['sellerEarning']) ?? 0;
    data['ownerNote'] = data['ownerNote']?.toString() ?? '';
    data['estimatedReadyAt'] = _asInt(data['estimatedReadyAt']) ?? 0;
    data['items'] = ((data['items'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    data['statusHistory'] = ((data['statusHistory'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return data;
  }

  String _defaultOrderStatusMessage(String status, String actor) {
    switch (status) {
      case 'accepted':
        return actor == 'owner'
            ? 'Seller accepted the order'
            : 'Order accepted';
      case 'confirmed':
        return actor == 'owner'
            ? 'Owner confirmed the order'
            : 'Order confirmed';
      case 'in_progress':
        return actor == 'owner'
            ? 'Owner started preparing the order'
            : 'Order is now in progress';
      case 'out_for_delivery':
        return actor == 'owner'
            ? 'Order is out for delivery'
            : 'Out for delivery';
      case 'delivered':
        return actor == 'owner'
            ? 'Seller marked the order as delivered'
            : 'Order delivered';
      case 'completed':
        return actor == 'owner'
            ? 'Owner marked the order as completed'
            : 'Order completed';
      case 'cancelled':
        return actor == 'customer'
            ? 'Customer cancelled the order'
            : 'Order was cancelled';
      case 'pending':
      default:
        return 'Order is pending review';
    }
  }

  int _countOrderItems(List<Map<String, dynamic>> items) {
    return items.fold<int>(
      0,
      (sum, item) => sum + (_asInt(item['quantity']) ?? 0),
    );
  }

  double _sumOrderItems(List<Map<String, dynamic>> items) {
    return items.fold<double>(0, (sum, item) {
      final line =
          _asDouble(item['lineTotal']) ?? _asDouble(item['totalPrice']) ?? 0;
      if (line > 0) return sum + line;
      return sum +
          ((_asDouble(item['price']) ?? 0) * (_asInt(item['quantity']) ?? 0));
    });
  }

  int? _asInt(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
