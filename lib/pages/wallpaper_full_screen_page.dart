import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:quote_application/main.dart';


class WallpaperFullScreenPage extends StatelessWidget {
  
  final String imageUrl;

  const WallpaperFullScreenPage({super.key, required this.imageUrl});

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      if (sdkInt >= 33) {
        final photosPermission = await Permission.photos.request();
        return photosPermission.isGranted;
      } else {
        final storagePermission = await Permission.storage.request();
        return storagePermission.isGranted;
      }
    }
    return true;
  }

  Future<void> _saveImage(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final permissionGranted = await _requestPermission();
      if (!context.mounted) return;

      if (!permissionGranted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("Permission denied!")),
        );
        return;
      }

      final response = await http.get(Uri.parse(imageUrl));
      if (!context.mounted) return;

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;

        final result = await ImageGallerySaver.saveImage(
          bytes,
          name: 'wallpaper_${DateTime.now().millisecondsSinceEpoch}',
          quality: 100,
        );

        if (!context.mounted) return;

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(result['isSuccess'] == true
                ? "Saved to Gallery!"
                : "Failed to save image."),
          ),
        );
                  // ✅ Log analytics only if save succeeded
          if (result['isSuccess'] == true) {
            analytics.logEvent(
              name: 'wallpaper_saved',
              parameters: {
                'image_url': imageUrl,
              },
            );
          }
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("Failed to load image.")),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  size: 100,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _saveImage(context),
              icon: const Icon(Icons.download),
              label: const Text("Save to Gallery"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
