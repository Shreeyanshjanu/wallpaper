import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:wallpaper_composer/models/video_item.dart';
import '../services/api_service.dart';
import 'dart:html' as html;

class MediaProvider with ChangeNotifier {
  final List<MediaItem> _mediaItems = [];
  final ApiService _api = ApiService();
  
  // Store file bytes temporarily
  final Map<String, Uint8List> _mediaBytes = {};
  final Map<String, String> _mediaTypes = {}; // Track file types
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _downloadUrl;

  List<MediaItem> get mediaItems => _mediaItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get downloadUrl => _downloadUrl;
  int get mediaCount => _mediaItems.length;
  bool get canAddMore => true; // UNLIMITED files now

  /// Pick multiple files (videos AND images)
  Future<void> addMedia() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Allow multiple files of any type (videos and images)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm', // Videos
                           'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'], // Images
        allowMultiple: true, // MULTIPLE selection enabled
      );

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (file.bytes != null) {
            final mediaId = const Uuid().v4();
            final extension = file.extension?.toLowerCase() ?? '';
            
            // Determine if it's video or image
            final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
            final mediaType = isVideo ? 'video' : 'image';
            
            // Store bytes in memory
            _mediaBytes[mediaId] = file.bytes!;
            _mediaTypes[mediaId] = mediaType;
            
            // Create Blob URL for preview
            final mimeType = isVideo ? 'video/$extension' : 'image/$extension';
            final blob = html.Blob([file.bytes!], mimeType);
            final blobUrl = html.Url.createObjectUrlFromBlob(blob);

            // Create media item
            final mediaItem = MediaItem(
              id: mediaId,
              mediaUrl: blobUrl,
              mediaType: mediaType,
              x: 0.1 + (_mediaItems.length * 0.05) % 0.8,
              y: 0.1 + (_mediaItems.length * 0.05) % 0.8,
              width: 0.3,
              height: 0.3,
              startTime: 0,
              duration: isVideo ? 120 : 10, // Images show for 10 seconds
            );

            _mediaItems.add(mediaItem);
          }
        }
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = 'Failed to add media: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateMedia(String id, {double? x, double? y, double? width, double? height}) {
    final index = _mediaItems.indexWhere((m) => m.id == id);
    if (index != -1) {
      _mediaItems[index] = _mediaItems[index].copyWith(
        x: x, 
        y: y, 
        width: width, 
        height: height
      );
      notifyListeners();
    }
  }

  void removeMedia(String id) {
    _mediaItems.removeWhere((m) => m.id == id);
    _mediaBytes.remove(id);
    _mediaTypes.remove(id);
    notifyListeners();
  }

  void clearAll() {
    _mediaItems.clear();
    _mediaBytes.clear();
    _mediaTypes.clear();
    _downloadUrl = null;
    _errorMessage = null;
    notifyListeners();
  }
  
  Future<void> composeVideo() async {
    if (_mediaItems.isEmpty) {
      _errorMessage = 'Add at least one media file';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      _downloadUrl = null;
      notifyListeners();

      final response = await _api.composeMediaWithFiles(
        mediaItems: _mediaItems,
        mediaBytes: _mediaBytes,
        mediaTypes: _mediaTypes,
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
