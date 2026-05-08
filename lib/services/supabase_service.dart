import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class SupabaseService {
  static SupabaseClient get client => SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_ANON_KEY']!,
  );

  /// Uploads an image for a business and returns the public URL
  static Future<String?> uploadBusinessImage({
    required XFile imageFile,
    required String businessId,
  }) async {
    try {
      final fileName = _buildUploadFileName(imageFile);
      final storagePath = 'businesses/$businessId/$fileName';
      final bytes = await imageFile.readAsBytes();
      await client.storage
          .from('Findorabucket')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return client.storage.from('Findorabucket').getPublicUrl(storagePath);
    } catch (e) {
      rethrow;
    }
  }

  /// Uploads a service image and returns the public URL
  static Future<String?> uploadServiceImage({
    required XFile imageFile,
    required String businessId,
    required String serviceId,
  }) async {
    try {
      final fileName = _buildUploadFileName(imageFile);
      final storagePath = 'services/$businessId/$serviceId/$fileName';
      final bytes = await imageFile.readAsBytes();
      final response = await client.storage
          .from('Findorabucket')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      if (response.isEmpty) throw Exception('Upload failed');
      return client.storage.from('Findorabucket').getPublicUrl(storagePath);
    } catch (e) {
      rethrow;
    }
  }

  /// Uploads a review image and returns the public URL
  static Future<String?> uploadReviewImage({
    required XFile imageFile,
    required String reviewId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final userId = user.uid;
      final storagePath = 'reviews/$userId/$reviewId.jpg';
      final bytes = await imageFile.readAsBytes();
      final response = await client.storage
          .from('Findorabucket')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      if (response.isEmpty) throw Exception('Upload failed');
      return client.storage.from('Findorabucket').getPublicUrl(storagePath);
    } catch (e) {
      rethrow;
    }
  }

  static String _buildUploadFileName(XFile imageFile) {
    final originalName = imageFile.name.trim();
    final baseName = originalName.isNotEmpty
        ? path.basename(originalName)
        : 'image.jpg';
    return '${DateTime.now().millisecondsSinceEpoch}_$baseName';
  }
}
