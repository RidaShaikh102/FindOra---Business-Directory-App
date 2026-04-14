import 'package:dio/dio.dart';

class CloudinaryService {
  // Replace these with your Cloudinary values
  static const String _cloudName = 'drli6vhfp';
  static const String _uploadPreset = 'flutter_upload';

  /// Uploads a local image file and returns the secure URL or null on failure.
  static Future<String?> uploadImage(String filePath) async {
    try {
      final dio = Dio();
      final url = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'upload_preset': _uploadPreset,
      });

      final resp = await dio.post(url, data: formData);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final secureUrl = resp.data['secure_url'] as String?;
        return secureUrl;
      } else {
        // optional: print debug
        print('Cloudinary upload failed: ${resp.statusCode} ${resp.data}');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}
