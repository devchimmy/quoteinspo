import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quote_application/main.dart';
import 'package:quote_application/services/favorite_quotes_service.dart';
import 'package:quote_application/models/random_quotes.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:screenshot/screenshot.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> randomQuotesList = [];
  bool isLoadingMore = false;
  final Map<int, ScreenshotController> _screenshotControllers = {};

  @override
  void initState() {
    super.initState();
    loadInitialQuotes();
    _pageController.addListener(_handlePageScroll);
  }

  void _handlePageScroll() {
    if (_pageController.page != null &&
        _pageController.page!.toInt() == randomQuotesList.length - 1 &&
        !isLoadingMore) {
      loadMoreQuotes();
    }
  }

  Future<void> loadInitialQuotes() async {
    final quotes = await fetchQuotes(5);
    if (!mounted) return;
    setState(() {
      randomQuotesList = quotes;
    });
  }

  Future<void> loadMoreQuotes() async {
    setState(() => isLoadingMore = true);
    final newQuotes = await fetchQuotes(5);
    if (!mounted) return;
    setState(() {
      randomQuotesList.addAll(newQuotes);
      isLoadingMore = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchQuotes(int count) async {
    List<Map<String, dynamic>> tempList = [];
    for (int i = 0; i < count; i++) {
      final result = await RandomQuote.getRandomQuoteAndImage();
      tempList.add(result);
    }
    return tempList;
  }

  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Quote copied!")));
        // ✅ Log analytics event
  await analytics.logEvent(
    name: 'quote_copied',
    parameters: {
      'quote_text': text,
    },
  );
  }

  Future<void> shareQuoteAsImage(int index) async {
    try {
      final controller = _screenshotControllers[index];
      if (controller == null) return;

      final image = await controller.capture();
      if (image == null) throw Exception("Image capture failed");

      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(image);

      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)],);
       // ✅ Log analytics event
    await analytics.logEvent(
      name: 'quote_shared',
      parameters: {
        'quote_index': index,
      },
    );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to share: $e")));
    }
  }

  Future<void> saveQuoteToGallery(int index) async {
    try {
      final controller = _screenshotControllers[index];
      if (controller == null) return;

      final image = await controller.capture();
      if (image == null) throw Exception("Image capture failed");

      final status = await _requestPermission();
      if (!mounted) return;

      if (status) {
        await ImageGallerySaver.saveImage(
          Uint8List.fromList(image),
          quality: 100,
          name: 'quote_${DateTime.now().millisecondsSinceEpoch}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved to Gallery!")),
        );
         // ✅ Log analytics event
      await analytics.logEvent(
        name: 'quote_saved',
        parameters: {
          'quote_index': index,
        },
      );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permission denied!")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to save: $e")));
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        final photos = await Permission.photos.request();
        return photos.isGranted;
      } else {
        final storage = await Permission.storage.request();
        return storage.isGranted;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Explore")),
      body: randomQuotesList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              itemCount: randomQuotesList.length,
              itemBuilder: (context, index) {
                final quote = randomQuotesList[index];
                final imageUrl = quote['backgroundImage'];
                _screenshotControllers.putIfAbsent(index, () => ScreenshotController());

                final Map<String, String> quoteMap = {
                  'id': (quote['id'] ?? '').toString(),
                  'quote': (quote['quote'] ?? '').toString(),
                  'backgroundImage': (quote['backgroundImage'] ?? '').toString(),
                  'category': (quote['category'] ?? 'Uncategorized').toString(),
                };

                final isFavorite = FavoriteQuotesService().isFavorite(quoteMap);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Capture only this part in screenshot
                    Screenshot(
                      controller: _screenshotControllers[index]!,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.grey),
                            )
                          else
                            Container(color: Colors.grey),
                          Container(color: Colors.black.withOpacity(0.8)),
                          Padding(
                            padding: const EdgeInsets.all(60),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    quote['quote'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "- ${quote['category'] ?? 'Uncategorized'}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
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
                      ),
                    ),
                    // These buttons are outside the Screenshot
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SafeArea(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isFavorite) {
                                      FavoriteQuotesService().removeFavorite(quoteMap);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Removed from favorites!")),
                                      );
                                       // ✅ Log event without breaking setState
                                      analytics.logEvent(
                                        name: 'quote_unfavorited',
                                        parameters: {
                                          'quote_text': quoteMap['quote'],
                                          'category': quoteMap['category'],
                                        },
                                      ).then((_) {});
                                      

                                    } else {
                                      FavoriteQuotesService().addFavorite(quoteMap);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Added to favorites!")),
                                      );
                                      // ✅ Log event without breaking setState
                                    analytics.logEvent(
                                      name: 'quote_favorited',
                                      parameters: {
                                        'quote_text': quoteMap['quote'],
                                        'category': quoteMap['category'],
                                      },
                                    ).then((_) {});
                                    }
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, color: Colors.white),
                                onPressed: () => copyToClipboard(quote['quote'] ?? ''),
                              ),
                              IconButton(
                                icon: const Icon(Icons.download, color: Colors.white),
                                onPressed: () => saveQuoteToGallery(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share, color: Colors.white),
                                onPressed: () => shareQuoteAsImage(index),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (index == randomQuotesList.length - 1 && isLoadingMore)
                      const Positioned(
                        bottom: 80,
                        left: 0,
                        right: 0,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
