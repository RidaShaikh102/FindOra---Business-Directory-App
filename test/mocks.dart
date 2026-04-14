// test/mocks.dart

class MockAuthService {
  Future<String?> getCurrentUserEmail() async => '';
}

class MockLocalStorageService {
  Future<List<String>> getSavedBusinesses() async => [];

  Future<void> saveSavedBusiness(String businessId) async {}

  Future<void> removeSavedBusiness(String businessId) async {}

  Future<Map<String, List<Map<String, dynamic>>>> getAllServices() async =>
      <String, List<Map<String, dynamic>>>{};

  Future<void> deleteBusiness(String id) async {}

  Future<void> deleteReview(String reviewId) async {}

  Future<void> deleteService(String businessId, String serviceId) async {}

  Future<List<Map<String, dynamic>>> getBusinesses() async => [];

  Future<List<Map<String, dynamic>>> getReviews() async => [];

  Future<List<Map<String, dynamic>>> getReviewsByBusiness(
    String businessId, {
    Object? startAfter,
    int limit = 10,
  }) async => [];

  Future<List<Map<String, dynamic>>> getServices(String businessId) async => [];

  Future<List<Map<String, dynamic>>> getVisibleBusinesses({
    String? role,
    String? email,
  }) async => [];

  Future<void> saveBusiness(Map<String, dynamic> business) async {}

  Future<void> saveBusinesses(List<Map<String, dynamic>> businesses) async {}

  Future<void> saveReview(Map<String, dynamic> review) async {}

  Future<void> saveReviews(List<Map<String, dynamic>> reviews) async {}

  Future<void> saveService(
    String businessId,
    Map<String, dynamic> service,
  ) async {}

  Future<void> updateBusiness(
    String id,
    Map<String, dynamic> updatedBusiness,
  ) async {}
}
