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
  late Offset _position;
  late Size _size;
  bool _isSelected = false;

  @override
  void initState() {
    super.initState();
    // Initialize from videoItem
    _position = Offset(
      widget.videoItem.x * widget.canvasSize.width,
      widget.videoItem.y * widget.canvasSize.height,
    );
    _size = Size(
      widget.videoItem.width * widget.canvasSize.width,
      widget.videoItem.height * widget.canvasSize.height,
    );
    
    print('DraggableVideo initialized: pos=$_position, size=$_size');
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
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
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Add extra padding for resize handles and sliders
    return Positioned(
      left: _position.dx - 20, // Extra space for handles
      top: _position.dy - 20,
      child: Container(
        padding: const EdgeInsets.all(20), // Space for handles
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main video container with resize handle
            Stack(
              clipBehavior: Clip.none,
              children: [
                // The video box
                GestureDetector(
                  onTap: () {
                    print('Video tapped!');
                    setState(() {
                      _isSelected = !_isSelected;
                    });
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
                    child: _isInitialized
                        ? VideoPlayer(_controller)
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),

                // SELECTED indicator at top
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
                        'SELECTED ${_size.width.toInt()}x${_size.height.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Remove button (always visible)
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

                // BIG GREEN RESIZE HANDLE (only when selected)
                if (_isSelected)
                  Positioned(
                    bottom: -20,
                    right: -20,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        print('Resizing: ${details.delta}');
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
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
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

            // SLIDERS BELOW THE VIDEO (only when selected)
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
                    const Text(
                      '📏 RESIZE CONTROLS',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Width: ${_size.width.toInt()}px',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _size.width,
                      min: 150,
                      max: 1200,
                      divisions: 105,
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey,
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
                    const SizedBox(height: 10),
                    Text(
                      'Height: ${_size.height.toInt()}px',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _size.height,
                      min: 150,
                      max: 1200,
                      divisions: 105,
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey,
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
}
