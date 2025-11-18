import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final String cloudName = 'dyr7jlczr';
  final String uploadPreset =
      'wallpaper_videos'; // Replace with your actual preset name

  /// Upload video file to Cloudinary
  Future<String> uploadVideo(Uint8List fileBytes, String fileName) async {
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload');

      var request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      print('Uploading video to Cloudinary...');
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        final publicUrl = jsonResponse['secure_url'];
        print('Upload successful: $publicUrl');
        return publicUrl;
      } else {
        var jsonResponse = jsonDecode(responseBody);
        throw Exception('Upload failed: ${jsonResponse['error']['message']}');
      }
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }
}
