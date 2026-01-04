import 'package:dio/dio.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../../config/cloudinary_config.dart';

class CloudinaryService {
  static const String _baseUrl = 'https://api.cloudinary.com/v1_1';
  final Dio _dio = Dio();

  /// Upload image to Cloudinary with signed request
  Future<String> uploadUserAvatar(File imageFile) async {
    try {
      final fileName =
          'user_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('[Cloudinary] Starting signed upload: $fileName');
      print('[Cloudinary] Cloud Name: ${CloudinaryConfig.cloudName}');

      // Generate timestamp
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

      // Parameters to sign
      final params = <String, dynamic>{
        'timestamp': timestamp,
        'folder': 'images/userAvatar',
      };

      // Create signature string (parameters alphabetically sorted)
      final sortedKeys = params.keys.toList()..sort();
      final signatureString =
          sortedKeys.map((key) => '$key=${params[key]}').join('&');

      // Create signature
      final signature = sha1
          .convert(
            ('$signatureString${CloudinaryConfig.apiSecret}').codeUnits,
          )
          .toString();

      print('[Cloudinary] Signature: $signature');

      // Create form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        'api_key': CloudinaryConfig.apiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
        'folder': 'images/userAvatar',
        'resource_type': 'auto',
      });

      final url = '${_baseUrl}/${CloudinaryConfig.cloudName}/image/upload';
      print('[Cloudinary] Upload URL: $url');

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      print('[Cloudinary] Response status: ${response.statusCode}');
      print('[Cloudinary] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final imageUrl = response.data['secure_url'] as String;
        print('[Cloudinary] Upload success: $imageUrl');
        return imageUrl;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('[Cloudinary] DioException: ${e.message}');
      print('[Cloudinary] Status Code: ${e.response?.statusCode}');
      print('[Cloudinary] Response: ${e.response?.data}');

      final errorMessage = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          e.message ??
          'Unknown error';
      throw Exception('Cloudinary upload error: $errorMessage');
    } catch (e) {
      print('[Cloudinary] Exception: $e');
      throw Exception('Error uploading image: $e');
    }
  }

  /// Upload product image to Cloudinary
  Future<String> uploadProductImage(File imageFile) async {
    try {
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('[Cloudinary] Starting product image upload: $fileName');

      // Generate timestamp
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

      // Parameters to sign
      final params = <String, dynamic>{
        'timestamp': timestamp,
        'folder': 'images/product',
      };

      // Create signature string (parameters alphabetically sorted)
      final sortedKeys = params.keys.toList()..sort();
      final signatureString =
          sortedKeys.map((key) => '$key=${params[key]}').join('&');

      // Create signature
      final signature = sha1
          .convert(
            ('$signatureString${CloudinaryConfig.apiSecret}').codeUnits,
          )
          .toString();

      // Create form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        'api_key': CloudinaryConfig.apiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
        'folder': 'images/product',
        'resource_type': 'auto',
      });

      final url = '${_baseUrl}/${CloudinaryConfig.cloudName}/image/upload';
      print('[Cloudinary] Product upload URL: $url');

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      print('[Cloudinary] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final imageUrl = response.data['secure_url'] as String;
        print('[Cloudinary] Product upload success: $imageUrl');
        return imageUrl;
      } else {
        throw Exception(
            'Failed to upload product image: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('[Cloudinary] DioException: ${e.message}');
      print('[Cloudinary] Status Code: ${e.response?.statusCode}');

      final errorMessage = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          e.message ??
          'Unknown error';
      throw Exception('Cloudinary upload error: $errorMessage');
    } catch (e) {
      print('[Cloudinary] Exception: $e');
      throw Exception('Error uploading product image: $e');
    }
  }

  /// Upload message image to Cloudinary
  Future<String> uploadMessageImage(File imageFile) async {
    try {
      final fileName = 'message_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('[Cloudinary] Starting message image upload: $fileName');

      // Generate timestamp
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

      // Parameters to sign
      final params = <String, dynamic>{
        'timestamp': timestamp,
        'folder': 'images/message',
      };

      // Create signature string (parameters alphabetically sorted)
      final sortedKeys = params.keys.toList()..sort();
      final signatureString =
          sortedKeys.map((key) => '$key=${params[key]}').join('&');

      // Create signature
      final signature = sha1
          .convert(
            ('$signatureString${CloudinaryConfig.apiSecret}').codeUnits,
          )
          .toString();

      print('[Cloudinary] Message image signature: $signature');

      // Create form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        'api_key': CloudinaryConfig.apiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
        'folder': 'images/message',
        'resource_type': 'auto',
      });

      final url = '${_baseUrl}/${CloudinaryConfig.cloudName}/image/upload';
      print('[Cloudinary] Message upload URL: $url');

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      print(
          '[Cloudinary] Message upload response status: ${response.statusCode}');
      print('[Cloudinary] Message upload response data: ${response.data}');

      if (response.statusCode == 200) {
        final imageUrl = response.data['secure_url'] as String;
        print('[Cloudinary] Message image upload success: $imageUrl');
        return imageUrl;
      } else {
        throw Exception(
            'Failed to upload message image: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('[Cloudinary] DioException: ${e.message}');
      print('[Cloudinary] Status Code: ${e.response?.statusCode}');

      final errorMessage = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          e.message ??
          'Unknown error';
      throw Exception('Cloudinary upload error: $errorMessage');
    } catch (e) {
      print('[Cloudinary] Exception: $e');
      throw Exception('Error uploading message image: $e');
    }
  }

  /// Delete image from Cloudinary
  Future<void> deleteUserAvatar(String publicId) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

      // Create signature for delete request
      final signatureString = 'public_id=$publicId&timestamp=$timestamp';
      final signature = sha1
          .convert(
            ('$signatureString${CloudinaryConfig.apiSecret}').codeUnits,
          )
          .toString();

      final formData = FormData.fromMap({
        'public_id': publicId,
        'api_key': CloudinaryConfig.apiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
      });

      await _dio.post(
        '${_baseUrl}/${CloudinaryConfig.cloudName}/image/destroy',
        data: formData,
      );
    } catch (e) {
      print('Error deleting image from Cloudinary: $e');
    }
  }

  /// Upload search image to Cloudinary (images/search folder)
  Future<String> uploadSearchImage(File imageFile) async {
    try {
      final fileName = 'search_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('[Cloudinary] Starting search image upload: $fileName');

      // Generate timestamp
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

      // Parameters to sign
      final params = <String, dynamic>{
        'timestamp': timestamp,
        'folder': 'images/search',
      };

      // Create signature string (parameters alphabetically sorted)
      final sortedKeys = params.keys.toList()..sort();
      final signatureString =
          sortedKeys.map((key) => '$key=${params[key]}').join('&');

      // Create signature
      final signature = sha1
          .convert(
            ('$signatureString${CloudinaryConfig.apiSecret}').codeUnits,
          )
          .toString();

      // Create form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        'api_key': CloudinaryConfig.apiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
        'folder': 'images/search',
        'resource_type': 'auto',
      });

      final url = '${_baseUrl}/${CloudinaryConfig.cloudName}/image/upload';
      print('[Cloudinary] Search upload URL: $url');

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );

      print('[Cloudinary] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final imageUrl = response.data['secure_url'] as String;
        print('[Cloudinary] Search image upload success: $imageUrl');
        return imageUrl;
      } else {
        throw Exception(
            'Failed to upload search image: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('[Cloudinary] DioException: ${e.message}');
      print('[Cloudinary] Status Code: ${e.response?.statusCode}');

      final errorMessage = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          e.message ??
          'Unknown error';
      throw Exception('Cloudinary upload error: $errorMessage');
    } catch (e) {
      print('[Cloudinary] Exception: $e');
      throw Exception('Error uploading search image: $e');
    }
  }
}
