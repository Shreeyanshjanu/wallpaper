import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../models/video_item.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late String baseUrl;

  void initialize() {
    baseUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';
  }

  /// Send video files directly to backend (multipart form data)
  Future<Map<String, dynamic>> composeVideosWithFiles({
    required List<VideoItem> videos,
    required Map<String, Uint8List> videoBytes,
    int canvasWidth = 1920,
    int canvasHeight = 1080,
    int outputDuration = 120,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/compose-upload');
      
      var request = http.MultipartRequest('POST', url);
      
      // Add video files
      for (var i = 0; i < videos.length; i++) {
        final video = videos[i];
        final bytes = videoBytes[video.id];
        
        if (bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'videos',
              bytes,
              filename: '${video.id}.mp4',
            ),
          );
        }
      }
      
      // Add metadata as JSON
      final metadata = {
        'video_positions': videos.map((v) => {
          'id': v.id,
          'x': v.x,
          'y': v.y,
          'width': v.width,
          'height': v.height,
          'start_time': v.startTime,
          'duration': v.duration,
        }).toList(),
        'canvas_width': canvasWidth,
        'canvas_height': canvasHeight,
        'output_duration': outputDuration,
      };
      
      request.fields['metadata'] = jsonEncode(metadata);

      print('Sending ${videos.length} videos to backend...');
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('Failed to compose videos: $responseBody');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  /// Health check
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
