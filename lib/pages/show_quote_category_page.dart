import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:quote_application/main.dart';
import 'package:share_plus/share_plus.dart';
import '../services/favorite_quotes_service.dart';

class QuoteCategoryPage extends StatefulWidget {
  final String categoryTitle;
  final String jsonFileName;

  const QuoteCategoryPage({
    super.key,
    required this.categoryTitle,
    required this.jsonFileName,
  });

  @override
  QuoteCategoryPageState createState() => QuoteCategoryPageState();
}

class QuoteCategoryPageState extends State<QuoteCategoryPage> {
  List<String> quotes = [];
  List<String> backgroundImages = [];
  final Map<int, GlobalKey> _quoteKeys = {};
  final favoriteService = FavoriteQuotesService();

  @override
  void initState() {
    super.initState();
    loadQuotes();
    loadBackgroundImages();
  }

  Future<void> loadQuotes() async {
    final String jsonString =
        await rootBundle.loadString('assets/json/${widget.jsonFileName}');
    final List<dynamic> jsonResponse = json.decode(jsonString);
    if (!mounted) return;
    setState(() {
      quotes = jsonResponse.map((e) => e['quote'].toString()).toList();
    });
  }

  Future<void> loadBackgroundImages() async {
    final String imageJson =
        await rootBundle.loadString('assets/json/quote_backgrounds.json');
    final Map<String, dynamic> jsonResponse = json.decode(imageJson);
    if (!mounted) return;
    if (jsonResponse.containsKey(widget.categoryTitle)) {
      setState(() {
        backgroundImages = List<String>.from(jsonResponse[widget.categoryTitle]);
      });
    }
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard!")),
    );
    
  // ✅ Log analytics
  analytics.logEvent(
    name: 'quote_copied',
    parameters: {
      'quote_text': text,
      'category': widget.categoryTitle,
    },
  );
  }

  Future<void> saveOrShareQuoteImage(int index, {bool share = false}) async {
    try {
      final key = _quoteKeys[index];
      if (key == null) return;

      await Future.delayed(const Duration(milliseconds: 300));
      await WidgetsBinding.instance.endOfFrame;

      final context = key.currentContext;
      if (context == null) throw Exception("Render context not found");

      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Boundary not found");

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Could not convert image to bytes");

      final pngBytes = byteData.buffer.asUint8List();

      if (share) {
        final tempDir = await Directory.systemTemp.createTemp();
        final filePath = '${tempDir.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles([XFile(file.path)],);
        
      } else {
        final permissionGranted = await _requestPermission();
        if (permissionGranted) {
          await ImageGallerySaver.saveImage(
            Uint8List.fromList(pngBytes),
            quality: 100,
            name: 'quote_${DateTime.now().millisecondsSinceEpoch}',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Saved to Gallery!")),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Permission denied!")),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

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

  void toggleFavorite(Map<String, String> quoteMap) {
    setState(() {
      if (favoriteService.isFavorite(quoteMap)) {
        favoriteService.removeFavorite(quoteMap);
      } else {
        favoriteService.addFavorite(quoteMap);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (quotes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.categoryTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryTitle)),
      body: PageView.builder(
        itemCount: quotes.length,
        itemBuilder: (context, index) {
          final quote = quotes[index];
          final backgroundImage =
              index < backgroundImages.length ? backgroundImages[index] : '';
          final key = _quoteKeys[index] ?? GlobalKey();
          _quoteKeys[index] = key;

          final Map<String, String> quoteMap = {
            'id': '${widget.categoryTitle}_$index',
            'quote': quote,
            'backgroundImage': backgroundImage,
            'category': widget.categoryTitle,
          };

          final isFav = favoriteService.isFavorite(quoteMap);

          return Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                key: key,
                child: _QuoteCard(
                  quote: quote,
                  backgroundImage: backgroundImage,
                ),
              ),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      onPressed: () => copyToClipboard(quote),
                    ),
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white,
                      ),
                      onPressed: () {
                        toggleFavorite(quoteMap);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isFav
                                ? "Removed from favorites!"
                                : "Added to favorites!"),
                          ),
                        );
                        
                      // ✅ Log analytics
                      analytics.logEvent(
                        name: isFav ? 'quote_unfavorited' : 'quote_favorited',
                        parameters: {
                          'quote_text': quote,
                          'category': widget.categoryTitle,
                        },
                      );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.save, color: Colors.white),
                                        onPressed:  () async {
                      await saveOrShareQuoteImage(index, share: false);
                      // Log event after attempting to save
                      analytics.logEvent(
                        name: 'quote_saved',
                        parameters: {
                          'quote_text': quotes[index],
                          'category': widget.categoryTitle,
                        },
                      );
                      }

                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () async {
                        await saveOrShareQuoteImage(index, share: true);
                        // Log event after attempting to share
                        analytics.logEvent(
                          name: 'quote_shared',
                          parameters: {
                            'quote_text': quotes[index],
                            'category': widget.categoryTitle,
                          },
                        );
                      },
                      
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final String quote;
  final String backgroundImage;

  const _QuoteCard({
    required this.quote,
    required this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (backgroundImage.isNotEmpty)
          Image.network(
            backgroundImage,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (_, __, ___) => Container(color: Colors.grey),
          ),
        Container(color: Colors.black.withOpacity(0.8)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(60.0),
            child: Text(
              quote,
              style: const TextStyle(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
         /// WATERMARK (bottom-right corner)
        Positioned(
          bottom: 12,
          right: 12,
          child: Opacity(
            opacity: 0.3,
            child: Text(
              'Powered by Quote Inspo App',
              style: const TextStyle(
                fontFamily: 'Roboto', //custom font
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
