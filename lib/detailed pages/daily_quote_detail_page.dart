import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

class DailyQuoteDetailPage extends StatefulWidget {
  final String date;
  final String quote;
  final String backgroundImage;

  const DailyQuoteDetailPage({
    super.key,
    required this.date,
    required this.quote,
    required this.backgroundImage,
  });

  @override
  State<DailyQuoteDetailPage> createState() => _DailyQuoteDetailPageState();
}

class _DailyQuoteDetailPageState extends State<DailyQuoteDetailPage> {
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
      name: "daily_quote_${DateTime.now().millisecondsSinceEpoch}",
      quality: 100,
    );

    if (result['isSuccess'] == true || result['filePath'] != null) {
      Fluttertoast.showToast(msg: "Quote image saved!");
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
        '${tempDir.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);

    Share.shareXFiles([XFile(file.path)], text: "Check out this quote!");
  }

  void _copyQuote() {
    Clipboard.setData(ClipboardData(text: widget.quote));
    Fluttertoast.showToast(msg: "Quote copied!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// 🔒 This area is captured for image saving/sharing
          RepaintBoundary(
            key: _captureKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(widget.backgroundImage, fit: BoxFit.cover),
                Container(color: Colors.black.withOpacity(0.7)),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.quote,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                              height: 1.6,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black87,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40), // space between quote & buttons
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// ✅ UI elements (outside image capture)
          SafeArea(
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

                /// 🎯 Buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: _copyQuote,
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
          ),
        ],
      ),
    );
  }
}
