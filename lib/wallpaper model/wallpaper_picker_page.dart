import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quote_application/wallpaper%20model/wallpaper_model.dart';
import 'package:quote_application/wallpaper%20model/wallpaper_service.dart';

class WallpaperPickerPage extends StatefulWidget {
  final Function(File) onSelected;

  const WallpaperPickerPage({super.key, required this.onSelected});

  @override
  State<WallpaperPickerPage> createState() =>
      _WallpaperPickerPageState();
}

class _WallpaperPickerPageState extends State<WallpaperPickerPage> {
  late Future<List<WallpaperModel>> wallpapersFuture;

  @override
  void initState() {
    super.initState();
    wallpapersFuture = WallpaperService.loadWallpapers();
  }

  Future<File> _downloadImage(String url) async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await Dio().download('$url?w=1080', path);
    return File(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Wallpaper')),
      body: FutureBuilder<List<WallpaperModel>>(
        future: wallpapersFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final wallpapers = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: wallpapers.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (_, index) {
              final wallpaper = wallpapers[index];

              return GestureDetector(
                onTap: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  final file =
                      await _downloadImage(wallpaper.imageUrl);

                  Navigator.pop(context);
                  widget.onSelected(file);
                  Navigator.pop(context);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl:
                        '${wallpaper.imageUrl}?w=400',
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
