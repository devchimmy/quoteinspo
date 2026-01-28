import 'package:flutter/material.dart';
import 'package:quote_application/pages/wallpaper_full_screen_page.dart';

class WallpaperGridPage extends StatelessWidget {
  final String category;
  final List<String> images;
  final bool selectMode; // true if picking for ImageQuoteEditor

  const WallpaperGridPage({
    super.key,
    required this.category,
    required this.images,
    this.selectMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: images.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (context, index) {
          final imageUrl = images[index];
          return GestureDetector(
            onTap: () {
              if (selectMode) {
                // ImageQuoteEditor mode → return the selected wallpaper
                Navigator.pop(context, imageUrl);
              } else {
                // Normal mode → open full-screen preview
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WallpaperFullScreenPage(imageUrl: imageUrl),
                  ),
                );
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey[300]),
              ),
            ),
          );
        },
      ),
    );
  }
}
