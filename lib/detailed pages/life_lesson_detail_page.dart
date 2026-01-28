import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class LifeLessonDetailPage extends StatefulWidget {
  final String lesson;
  final String category;
  final String backgroundImage;

  const LifeLessonDetailPage({
    super.key,
    required this.lesson,
    required this.category,
    required this.backgroundImage,
  });

  @override
  State<LifeLessonDetailPage> createState() => _LifeLessonDetailPageState();
}

class _LifeLessonDetailPageState extends State<LifeLessonDetailPage> {
  final GlobalKey _captureKey = GlobalKey();

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  Future<Uint8List?> _captureImageBytes() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      RenderRepaintBoundary boundary =
          _captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Image capture error: $e");
      return null;
    }
  }

  Future<void> _saveImage() async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      Fluttertoast.showToast(msg: "Permission denied");
      return;
    }

    final imageBytes = await _captureImageBytes();
    if (imageBytes == null) {
      Fluttertoast.showToast(msg: "Could not capture image");
      return;
    }

    final result = await ImageGallerySaver.saveImage(
      imageBytes,
      name: "life_lesson_${DateTime.now().millisecondsSinceEpoch}",
      quality: 100,
    );

    if (result['isSuccess'] == true || result['filePath'] != null) {
      Fluttertoast.showToast(msg: "Lesson image saved!");
    } else {
      Fluttertoast.showToast(msg: "Failed to save image");
    }
  }

  Future<void> _shareImage() async {
    final imageBytes = await _captureImageBytes();
    if (imageBytes == null) {
      Fluttertoast.showToast(msg: "Could not capture image");
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/lesson_${DateTime.now().millisecondsSinceEpoch}.webp';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);

    Share.shareXFiles([XFile(file.path)], text: "Check out this life lesson!");
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: widget.lesson));
    Fluttertoast.showToast(msg: "Lesson copied!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// 🎯 RepaintBoundary wraps the full screen quote + background (excluding buttons)
          RepaintBoundary(
            key: _captureKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(widget.backgroundImage, fit: BoxFit.cover),
                Container(color: Colors.black.withOpacity(0.6)),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                    child: Column(
                      children: [
                        const Spacer(),
                        Text(
                          widget.category.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.lesson,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            color: Colors.white,
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black87,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// Buttons overlay (excluded from captured image)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: _copyText,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
