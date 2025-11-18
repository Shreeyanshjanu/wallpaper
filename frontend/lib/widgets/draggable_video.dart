import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video_item.dart';

class DraggableVideo extends StatefulWidget {
  final VideoItem videoItem;
  final Size canvasSize;
  final Function(double x, double y) onPositionChanged;
  final Function(double width, double height) onSizeChanged;
  final VoidCallback onRemove;

  const DraggableVideo({
    Key? key,
    required this.videoItem,
    required this.canvasSize,
    required this.onPositionChanged,
    required this.onSizeChanged,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<DraggableVideo> createState() => _DraggableVideoState();
}

class _DraggableVideoState extends State<DraggableVideo> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  Offset _position = Offset.zero;
  Size _size = const Size(300, 300);
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _updateFromVideoItem();
  }

  void _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoItem.videoUrl),
    );
    
    await _controller.initialize();
    _controller.setLooping(true);
    _controller.play();
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _updateFromVideoItem() {
    _position = Offset(
      widget.videoItem.x * widget.canvasSize.width,
      widget.videoItem.y * widget.canvasSize.height,
    );
    _size = Size(
      widget.videoItem.width * widget.canvasSize.width,
      widget.videoItem.height * widget.canvasSize.height,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        // Use ONLY onScaleUpdate (handles both pan and pinch/zoom)
        onScaleStart: (details) {
          _baseScale = 1.0;
        },
        onScaleUpdate: (details) {
          setState(() {
            // Handle dragging (position change)
            _position += details.focalPointDelta;
            
            // Handle resizing (scale change)
            if (details.scale != 1.0) {
              final newWidth = (_size.width * details.scale / _baseScale)
                  .clamp(100.0, widget.canvasSize.width);
              final newHeight = (_size.height * details.scale / _baseScale)
                  .clamp(100.0, widget.canvasSize.height);
              
              _size = Size(newWidth, newHeight);
              _baseScale = details.scale;
            }
            
            // Notify parent with normalized coordinates
            widget.onPositionChanged(
              _position.dx / widget.canvasSize.width,
              _position.dy / widget.canvasSize.height,
            );
            
            widget.onSizeChanged(
              _size.width / widget.canvasSize.width,
              _size.height / widget.canvasSize.height,
            );
          });
        },
        child: Container(
          width: _size.width,
          height: _size.height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Video player
              if (_isInitialized)
                SizedBox(
                  width: _size.width,
                  height: _size.height,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                )
              else
                Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              
              // Remove button
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: widget.onRemove,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
