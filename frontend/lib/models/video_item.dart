class MediaItem {
  final String id;
  final String mediaUrl;
  final String mediaType; // 'video' or 'image'
  final double x;
  final double y;
  final double width;
  final double height;
  final int startTime;
  final int duration;

  MediaItem({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.startTime,
    required this.duration,
  });

  MediaItem copyWith({
    String? mediaUrl,
    String? mediaType,
    double? x,
    double? y,
    double? width,
    double? height,
    int? startTime,
    int? duration,
  }) {
    return MediaItem(
      id: id,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'start_time': startTime,
      'duration': duration,
    };
  }
}
