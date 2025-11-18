import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/video_item.dart';
import '../services/api_service.dart';
import 'dart:html' as html;

class VideoProvider with ChangeNotifier {
  final List<VideoItem> _videos = [];
  final ApiService _api = ApiService();
  
  // Store video bytes temporarily
  final Map<String, Uint8List> _videoBytes = {};
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _downloadUrl;

  List<VideoItem> get videos => _videos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get downloadUrl => _downloadUrl;
  int get videoCount => _videos.length;
  bool get canAddMore => _videos.length < 10;

  /// Pick video and store in browser memory (no upload)
  Future<void> addVideo() async {
    if (!canAddMore) {
      _errorMessage = 'Maximum 10 videos allowed';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.first.bytes != null) {
        final file = result.files.first;
        final videoId = const Uuid().v4();
        
        // Store bytes in memory
        _videoBytes[videoId] = file.bytes!;
        
        // Create Blob URL for playback (browser memory, not uploaded)
        final blob = html.Blob([file.bytes!], 'video/mp4');
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);

        // Create video item with blob URL
        final videoItem = VideoItem(
          id: videoId,
          videoUrl: blobUrl, // Temporary blob URL
          x: 0.1 + (_videos.length * 0.05),
          y: 0.1 + (_videos.length * 0.05),
          width: 0.3,
          height: 0.3,
          startTime: 0,
          duration: 120,
        );

        _videos.add(videoItem);
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = 'Failed to add video: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateVideo(String id, {double? x, double? y, double? width, double? height}) {
    final index = _videos.indexWhere((v) => v.id == id);
    if (index != -1) {
      _videos[index] = _videos[index].copyWith(x: x, y: y, width: width, height: height);
      notifyListeners();
    }
  }

  void removeVideo(String id) {
    _videos.removeWhere((v) => v.id == id);
    _videoBytes.remove(id);
    notifyListeners();
  }

  void clearAll() {
    _videos.clear();
    _videoBytes.clear();
    _downloadUrl = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Send videos directly to backend (NO Cloudinary upload)
  Future<void> composeVideo() async {
    if (_videos.isEmpty) {
      _errorMessage = 'Add at least one video';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      _downloadUrl = null;
      notifyListeners();

      // Send video bytes and metadata directly to backend
      final response = await _api.composeVideosWithFiles(
        videos: _videos,
        videoBytes: _videoBytes,
      );
      
      _downloadUrl = response['download_url'];
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to compose video: $e';
      _downloadUrl = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
