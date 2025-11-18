// screens/canvas_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/video_provider.dart';
import '../widgets/draggable_video.dart';

class CanvasScreen extends StatelessWidget {
  const CanvasScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canvasSize = Size(
      MediaQuery.of(context).size.width - 300,
      MediaQuery.of(context).size.height,
    );

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Row(
        children: [
          // Canvas area
          Expanded(
            child: Container(
              color: Colors.white,
              child: Consumer<VideoProvider>(
                builder: (context, provider, child) {
                  return Stack(
                    children: [
                      // Canvas background
                      Container(
                        width: canvasSize.width,
                        height: canvasSize.height,
                        color: Colors.white,
                      ),
                      
                      // Video widgets
                      ...provider.videos.map((video) {
                        return DraggableVideo(
                          key: ValueKey(video.id),
                          videoItem: video,
                          canvasSize: canvasSize,
                          onPositionChanged: (x, y) {
                            provider.updateVideo(video.id, x: x, y: y);
                          },
                          onSizeChanged: (width, height) {
                            provider.updateVideo(
                              video.id,
                              width: width,
                              height: height,
                            );
                          },
                          onRemove: () => provider.removeVideo(video.id),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
          ),
          
          // Control panel
          Container(
            width: 300,
            color: Colors.grey[850],
            child: Consumer<VideoProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Title
                    const Text(
                      'Wallpaper Composer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Video count
                    Text(
                      '${provider.videoCount} / 10 videos',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Add video button
                    ElevatedButton.icon(
                      onPressed: provider.canAddMore && !provider.isLoading
                          ? provider.addVideo
                          : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Compose button
                    ElevatedButton.icon(
                      onPressed: provider.videos.isNotEmpty && !provider.isLoading
                          ? provider.composeVideo
                          : null,
                      icon: const Icon(Icons.video_library),
                      label: const Text('Compose Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Clear all button
                    TextButton.icon(
                      onPressed: provider.videos.isNotEmpty
                          ? provider.clearAll
                          : null,
                      icon: const Icon(Icons.delete),
                      label: const Text('Clear All'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Loading indicator
                    if (provider.isLoading)
                      const CircularProgressIndicator(),
                    
                    // Error message
                    if (provider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    // Download link
                    if (provider.downloadUrl != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Video Ready!',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final url = Uri.parse(provider.downloadUrl!);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Download'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const Spacer(),
                    
                    // Instructions
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Instructions:\n'
                        '1. Add up to 10 videos\n'
                        '2. Drag to reposition\n'
                        '3. Pinch to resize\n'
                        '4. Compose when ready\n'
                        '5. Download & use with Lively',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
