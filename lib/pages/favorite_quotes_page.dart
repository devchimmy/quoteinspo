import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:quote_application/services/favorite_quotes_service.dart';
import 'package:share_plus/share_plus.dart';

class FavoriteQuotesPage extends StatefulWidget {
  const FavoriteQuotesPage({super.key});

  @override
  State<FavoriteQuotesPage> createState() => _FavoriteQuotesPageState();
}

class _FavoriteQuotesPageState extends State<FavoriteQuotesPage> {
  // -------------------------
  // SAVE IMAGE TO GALLERY
  // -------------------------
  Future<void> _saveToGallery(GlobalKey key, String quoteText, String category) async {
    try {
      RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      var status = await Permission.storage.request();
      if (status.isGranted) {
        await ImageGallerySaver.saveImage(
          pngBytes,
          quality: 100,
          name: "favorited_quote_${DateTime.now().millisecondsSinceEpoch}",
        );

        // Log analytics
        FirebaseAnalytics.instance.logEvent(
          name: 'quote_saved',
          parameters: {
            'quote_text': quoteText,
            'category': category,
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to gallery')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e')),
        );
      }
    }
  }

  // -------------------------
  // SHARE QUOTE AS IMAGE
  // -------------------------
  Future<void> _shareQuoteImage(
      GlobalKey key, String quoteText, String category) async {
    try {
      // Capture widget as image
      RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.5);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save temp file
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/shared_quote_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = await File(filePath).writeAsBytes(pngBytes);

      // Share the image
      await Share.shareXFiles(
        [XFile(file.path)],
        
      );

      // Log analytics
      FirebaseAnalytics.instance.logEvent(
        name: 'quote_shared',
        parameters: {
          'quote_text': quoteText,
          'category': category,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to share: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteService = Provider.of<FavoriteQuotesService>(context);

    return FutureBuilder(
      future: favoriteService.init(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final favorites = favoriteService.favorites;

        return Scaffold(
          appBar: AppBar(title: const Text('Favorited Quotes')),
          body: favorites.isEmpty
              ? const Center(child: Text("No favorited quotes yet."))
              : ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final quoteData = favorites[index];
                    final GlobalKey repaintKey = GlobalKey();

                    final bool isQuote = quoteData.containsKey('quote') &&
                        quoteData.containsKey('backgroundImage');
                    final bool isLesson = quoteData.containsKey('title') &&
                        quoteData.containsKey('lesson') &&
                        quoteData.containsKey('image');

                    String quoteText = '';
                    String backgroundUrl = '';
                    String category = quoteData['category'] ?? 'Uncategorized';

                    if (isQuote) {
                      quoteText = quoteData['quote'] ?? '';
                      backgroundUrl = quoteData['backgroundImage'] ?? '';
                    } else if (isLesson) {
                      quoteText =
                          "${quoteData['title'] ?? ''}\n\n${quoteData['lesson'] ?? ''}";
                      backgroundUrl = quoteData['image'] ?? '';
                    } else {
                      quoteText = 'No data available';
                      backgroundUrl = '';
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                // IMAGE + QUOTE PREVIEW (CAPTURED)
                                RepaintBoundary(
                                  key: repaintKey,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 350,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: backgroundUrl.isNotEmpty
                                              ? Image.network(
                                                  backgroundUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(color: Colors.grey),
                                                )
                                              : Container(color: Colors.grey),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            color: Colors.black.withOpacity(0.5),
                                          ),
                                        ),
                                        Center(
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.symmetric(horizontal: 16.0),
                                            child: Text(
                                              quoteText,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // BUTTON ROW
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      // COPY
                                      IconButton(
                                        icon: const Icon(Icons.copy),
                                        onPressed: () {
                                          Clipboard.setData(
                                              ClipboardData(text: quoteText));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content:
                                                      Text('Copied to clipboard')));

                                          FirebaseAnalytics.instance.logEvent(
                                            name: 'quote_copied',
                                            parameters: {
                                              'quote_text': quoteText,
                                              'category': category,
                                            },
                                          );
                                        },
                                      ),

                                      // SHARE WITH BACKGROUND IMAGE
                                      IconButton(
                                        icon: const Icon(Icons.share),
                                        onPressed: () =>
                                            _shareQuoteImage(repaintKey, quoteText, category),
                                      ),

                                      // SAVE TO GALLERY
                                      IconButton(
                                        icon: const Icon(Icons.save_alt),
                                        onPressed: () =>
                                            _saveToGallery(repaintKey, quoteText, category),
                                      ),

                                      // UNFAVORITE
                                      IconButton(
                                        icon: const Icon(Icons.favorite, color: Colors.red),
                                        tooltip: 'Unfavorite',
                                        onPressed: () async {
                                          await favoriteService.removeFavorite(quoteData);
                                          setState(() {});
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Removed from favorites'),
                                            ),
                                          );

                                          FirebaseAnalytics.instance.logEvent(
                                            name: 'quote_unfavorited',
                                            parameters: {
                                              'quote_text': quoteText,
                                              'category': category,
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
