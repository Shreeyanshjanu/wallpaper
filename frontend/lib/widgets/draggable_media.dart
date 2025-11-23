import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wallpaper_composer/models/video_item.dart';

class DraggableMedia extends StatefulWidget {
  final MediaItem mediaItem;
  final Size canvasSize;
  final Function(double x, double y) onPositionChanged;
  final Function(double width, double height) onSizeChanged;
  final VoidCallback onRemove;

  const DraggableMedia({
    Key? key,
    required this.mediaItem,
    required this.canvasSize,
    required this.onPositionChanged,
    required this.onSizeChanged,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<DraggableMedia> createState() => _DraggableMediaState();
}

class _DraggableMediaState extends State<DraggableMedia> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  late Offset _position;
  late Size _size;
  bool _isSelected = false;

  @override
  void initState() {
    super.initState();
    _position = Offset(
      widget.mediaItem.x * widget.canvasSize.width,
      widget.mediaItem.y * widget.canvasSize.height,
    );
    _size = Size(
      widget.mediaItem.width * widget.canvasSize.width,
      widget.mediaItem.height * widget.canvasSize.height,
    );
    
    if (widget.mediaItem.mediaType == 'video') {
      _initializeVideo();
    } else {
      setState(() => _isInitialized = true);
    }
  }

  void _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.mediaItem.mediaUrl),
      );
      
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.play();
      
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx - 20,
      top: _position.dy - 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => _isSelected = !_isSelected);
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _position += details.delta;
                      widget.onPositionChanged(
                        _position.dx / widget.canvasSize.width,
                        _position.dy / widget.canvasSize.height,
                      );
                    });
                  },
                  child: Container(
                    width: _size.width,
                    height: _size.height,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isSelected ? Colors.red : Colors.grey.shade400,
                        width: _isSelected ? 6 : 3,
                      ),
                      color: Colors.black,
                    ),
                    child: _buildMediaContent(),
                  ),
                ),

                // Type indicator
                if (_isSelected)
                  Positioned(
                    top: -40,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.mediaItem.mediaType.toUpperCase()} ${_size.width.toInt()}x${_size.height.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Remove button
                Positioned(
                  top: -15,
                  right: -15,
                  child: GestureDetector(
                    onTap: widget.onRemove,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),

                // Resize handle
                if (_isSelected)
                  Positioned(
                    bottom: -20,
                    right: -20,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _size = Size(
                            (_size.width + details.delta.dx).clamp(150.0, 1200.0),
                            (_size.height + details.delta.dy).clamp(150.0, 1200.0),
                          );
                          
                          widget.onSizeChanged(
                            _size.width / widget.canvasSize.width,
                            _size.height / widget.canvasSize.height,
                          );
                        });
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.yellow, width: 4),
                        ),
                        child: const Icon(
                          Icons.open_in_full,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Sliders (when selected)
            if (_isSelected)
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: _size.width,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow, width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Width: ${_size.width.toInt()}px',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _size.width,
                      min: 150,
                      max: 1200,
                      onChanged: (value) {
                        setState(() {
                          _size = Size(value, _size.height);
                          widget.onSizeChanged(
                            _size.width / widget.canvasSize.width,
                            _size.height / widget.canvasSize.height,
                          );
                        });
                      },
                    ),
                    Text(
                      'Height: ${_size.height.toInt()}px',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _size.height,
                      min: 150,
                      max: 1200,
                      onChanged: (value) {
                        setState(() {
                          _size = Size(_size.width, value);
                          widget.onSizeChanged(
                            _size.width / widget.canvasSize.width,
                            _size.height / widget.canvasSize.height,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.mediaItem.mediaType == 'video' && _controller != null) {
      return VideoPlayer(_controller!);
    } else {
      // Display image
      return Image.network(
        widget.mediaItem.mediaUrl,
        fit: BoxFit.cover,
      );
    }
  }
}
