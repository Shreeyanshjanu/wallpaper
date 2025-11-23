import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:wallpaper_composer/models/video_item.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late String baseUrl;

  void initialize() {
    baseUrl = 'http://localhost:8000';
    print('API Service initialized with baseUrl: $baseUrl');
  }

  /// Send media files (videos + images) to backend
  Future<Map<String, dynamic>> composeMediaWithFiles({
    required List<MediaItem> mediaItems,
    required Map<String, Uint8List> mediaBytes,
    required Map<String, String> mediaTypes,
    int canvasWidth = 1920,
    int canvasHeight = 1080,
    int outputDuration = 120,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/compose-upload');
      
      var request = http.MultipartRequest('POST', url);
      
      // Add all media files
      for (var i = 0; i < mediaItems.length; i++) {
        final media = mediaItems[i];
        final bytes = mediaBytes[media.id];
        final mediaType = mediaTypes[media.id];
        
        if (bytes != null) {
          final extension = mediaType == 'video' ? 'mp4' : 'png';
          request.files.add(
            http.MultipartFile.fromBytes(
              'media_files', // Changed from 'videos' to 'media_files'
              bytes,
              filename: '${media.id}.$extension',
            ),
          );
        }
      }
      
      // Add metadata
      final metadata = {
        'media_positions': mediaItems.map((m) => {
          'id': m.id,
          'media_type': m.mediaType,
          'x': m.x,
          'y': m.y,
          'width': m.width,
          'height': m.height,
          'start_time': m.startTime,
          'duration': m.duration,
        }).toList(),
        'canvas_width': canvasWidth,
        'canvas_height': canvasHeight,
        'output_duration': outputDuration,
      };
      
      request.fields['metadata'] = jsonEncode(metadata);

      print('Sending ${mediaItems.length} media files to backend...');
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('Failed to compose: $responseBody');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
