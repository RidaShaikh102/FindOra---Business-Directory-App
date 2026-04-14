import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a local image file to Firebase Storage and returns the download URL.
  /// Returns null on failure.
  static Future<String?> uploadImage(
    File imageFile, {
    String? customPath,
  }) async {
    try {
      // Generate a unique filename if not provided
      final fileName =
          customPath ??
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';

      // Create a reference to the file location
      final ref = _storage.ref().child('images/$fileName');

      // Upload the file
      final uploadTask = ref.putFile(imageFile);

      // Wait for the upload to complete
      final snapshot = await uploadTask.whenComplete(() => null);

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Firebase Storage upload error: $e');
      return null;
    }
  }

  /// Deletes an image from Firebase Storage given its download URL.
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract the path from the URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the path after 'images/'
      final imagesIndex = pathSegments.indexOf('images');
      if (imagesIndex == -1 || imagesIndex + 1 >= pathSegments.length) {
        print('Invalid image URL format');
        return false;
      }

      final imagePath = 'images/${pathSegments[imagesIndex + 1]}';

      // Create reference and delete
      final ref = _storage.ref().child(imagePath);
      await ref.delete();

      return true;
    } catch (e) {
      print('Firebase Storage delete error: $e');
      return false;
    }
  }
}
