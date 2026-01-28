import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class RandomQuoteDetailPage extends StatefulWidget {
  final String quote;
  final String category;
  final String backgroundImage;

  const RandomQuoteDetailPage({
    super.key,
    required this.quote,
    required this.category,
    required this.backgroundImage,
  });

  @override
  State<RandomQuoteDetailPage> createState() => _RandomQuoteDetailPageState();
}

class _RandomQuoteDetailPageState extends State<RandomQuoteDetailPage> {
  final GlobalKey repaintKey = GlobalKey();

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  Future<Uint8List?> _capturePng() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Capture error: $e");
      return null;
    }
  }

  Future<void> _saveImage() async {
    final permissionGranted = await _requestPermission();
    if (!permissionGranted) return;

    final imageBytes = await _capturePng();
    if (imageBytes == null) return;

    final result = await ImageGallerySaver.saveImage(
      imageBytes,
      name: 'random_quote_${DateTime.now().millisecondsSinceEpoch}',
      quality: 100,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['isSuccess'] == true ? "Saved!" : "Failed to save")),
    );
  }

  Future<void> _shareImage() async {
    final imageBytes = await _capturePng();
    if (imageBytes == null) return;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/random_quote_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = await File(path).writeAsBytes(imageBytes);

    await Share.shareXFiles([XFile(file.path)], text: "${widget.category}\n\n${widget.quote}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            key: repaintKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(widget.backgroundImage, fit: BoxFit.cover),
                Container(color: Colors.black.withOpacity(0.7)), // Darker overlay
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.quote,
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black87,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              spacing: 40,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: "${widget.category}\n\n${widget.quote}"),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Copied!")),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: _saveImage,
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _shareImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
