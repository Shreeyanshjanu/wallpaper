class VideoItem {
  final String id;
  final String videoUrl;
  double x; // Normalized position (0-1)
  double y; // Normalized position (0-1)
  double width; // Normalized size (0-1)
  double height; // Normalized size (0-1)
  double startTime; // When video starts playing in composition
  double duration; // How long video plays
  String? localFilePath; // For web: Blob URL

  VideoItem({
    required this.id,
    required this.videoUrl,
    this.x = 0.1,
    this.y = 0.1,
    this.width = 0.3,
    this.height = 0.3,
    this.startTime = 0,
    this.duration = 120,
    this.localFilePath,
  });

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'video_url': videoUrl,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'start_time': startTime,
      'duration': duration,
    };
  }

  VideoItem copyWith({
    String? id,
    String? videoUrl,
    double? x,
    double? y,
    double? width,
    double? height,
    double? startTime,
    double? duration,
    String? localFilePath,
  }) {
    return VideoItem(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}
