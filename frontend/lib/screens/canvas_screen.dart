import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/media_provider.dart';
import '../widgets/draggable_media.dart';

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
          Expanded(
            child: Container(
              color: Colors.white,
              child: Consumer<MediaProvider>(
                builder: (context, provider, child) {
                  return Stack(
                    children: [
                      Container(
                        width: canvasSize.width,
                        height: canvasSize.height,
                        color: Colors.white,
                      ),
                      
                      ...provider.mediaItems.map((media) {
                        return DraggableMedia(
                          key: ValueKey(media.id),
                          mediaItem: media,
                          canvasSize: canvasSize,
                          onPositionChanged: (x, y) {
                            provider.updateMedia(media.id, x: x, y: y);
                          },
                          onSizeChanged: (width, height) {
                            provider.updateMedia(
                              media.id,
                              width: width,
                              height: height,
                            );
                          },
                          onRemove: () => provider.removeMedia(media.id),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
          ),
          
          Container(
            width: 300,
            color: Colors.grey[850],
            child: Consumer<MediaProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Wallpaper Composer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Media count (UNLIMITED)
                    Text(
                      '${provider.mediaCount} media files',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Add media button
                    ElevatedButton.icon(
                      onPressed: !provider.isLoading ? provider.addMedia : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Media (Videos/Images)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    ElevatedButton.icon(
                      onPressed: provider.mediaItems.isNotEmpty && !provider.isLoading
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
                    
                    TextButton.icon(
                      onPressed: provider.mediaItems.isNotEmpty
                          ? provider.clearAll
                          : null,
                      icon: const Icon(Icons.delete),
                      label: const Text('Clear All'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    if (provider.isLoading)
                      const CircularProgressIndicator(),
                    
                    if (provider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
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
                    
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Instructions:\n'
                        '1. Add unlimited media files\n'
                        '2. Supports videos & images\n'
                        '3. Multiple selection\n'
                        '4. Drag to reposition\n'
                        '5. Compose when ready',
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
