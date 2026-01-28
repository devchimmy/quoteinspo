import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quote_application/main.dart';
import 'package:quote_application/splash_screen/splash_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../services/favorite_quotes_service.dart';

class LifeLessonListPage extends StatefulWidget {
  final String? selectedLessonId;

  const LifeLessonListPage({super.key, this.selectedLessonId});

  @override
  State<LifeLessonListPage> createState() => _LifeLessonListPageState();
}

class _LifeLessonListPageState extends State<LifeLessonListPage> {
  List<Map<String, String>> allLessons = [];
  bool isLoading = true;

  final favoriteService = FavoriteQuotesService();
  final PageController _pageController = PageController();
  int initialPageIndex = 0;

  final List<String> categories = [
    "Motivation", "Inspiration", "Love", "Hustle", "Travel",
    "Relationship", "Heartbreak", "Self-Discovery", "Confidence", "Growth",
  ];

  final Map<String, String> fileMap = {
    "Motivation": "motivation_lifelessons.json",
    "Inspiration": "inspiration_lifelessons.json",
    "Love": "love_lifelessons.json",
    "Hustle": "hustle_lifelessons.json",
    "Travel": "travel_lifelessons.json",
    "Relationship": "relationship_lifelessons.json",
    "Heartbreak": "heartbreak_lifelessons.json",
    "Self-Discovery": "self_discovery_lifelessons.json",
    "Confidence": "confidence_lifelessons.json",
    "Growth": "growth_lifelessons.json",
  };

  @override
  void initState() {
    super.initState();
    loadAllLessons();
  }

  Future<void> loadAllLessons() async {
    List<Map<String, String>> combinedLessons = [];

    try {
      final String bgJson = await rootBundle.loadString('assets/json/life_lesson_backgrounds.json');
      final Map<String, dynamic> bgMap = json.decode(bgJson);
      final List<String> randomBgImages = List<String>.from(bgMap["randombg"] ?? []);

      int uniqueIdCounter = 0;

      for (final category in categories) {
        final filename = fileMap[category];
        if (filename == null) continue;

        final path = 'assets/json/$filename';
        final String jsonString = await rootBundle.loadString(path);
        final List<dynamic> lessonsRaw = json.decode(jsonString);

        for (var item in lessonsRaw) {
          final String bg = (randomBgImages..shuffle()).isNotEmpty ? randomBgImages.first : '';

          combinedLessons.add({
            'id': '${category}_$uniqueIdCounter',
            'title': item['title'].toString(),
            'lesson': item['lesson'].toString(),
            'image': bg,
            'category': category,
          });
          uniqueIdCounter++;
        }
      }

      combinedLessons.shuffle();

      if (widget.selectedLessonId != null) {
        final index = combinedLessons.indexWhere((e) => e['id'] == widget.selectedLessonId);
        if (index != -1) {
          initialPageIndex = index;
        }
      }

      if (!mounted) return;
      setState(() {
        allLessons = combinedLessons;
        isLoading = false;
      });

      if (initialPageIndex != 0) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _pageController.jumpToPage(initialPageIndex);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading: $e")),
      );
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  Future<Uint8List?> _capturePng(GlobalKey key) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      await WidgetsBinding.instance.endOfFrame;
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing image: $e");
      return null;
    }
  }

  Future<void> _saveLessonImage(GlobalKey key) async {
    final permissionGranted = await _requestPermission();
    if (!mounted) return;
    if (!permissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission denied!")),
      );
      return;
    }

    final imageBytes = await _capturePng(key);
    if (!mounted) return;

    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to capture image.")),
      );
      return;
    }

    final result = await ImageGallerySaver.saveImage(
      imageBytes,
      name: 'life_lesson_${DateTime.now().millisecondsSinceEpoch}',
      quality: 100,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['isSuccess'] == true ? "Saved to Gallery!" : "Failed to save image.")),
    );
  }

  Future<void> _shareLesson(GlobalKey key, String title, String lesson) async {
    final imageBytes = await _capturePng(key);
    if (!mounted) return;

    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to capture image for sharing.")),
      );
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/lesson_share_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = await File(filePath).writeAsBytes(imageBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Life Lessons")),
      body: isLoading
          ? const Center(child: SplashScreen(),)
          : PageView.builder(
              controller: _pageController,
              itemCount: allLessons.length,
              itemBuilder: (context, index) {
                final lesson = allLessons[index];
                final GlobalKey repaintKey = GlobalKey();
                final isFavorite = favoriteService.isFavorite(lesson);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      key: repaintKey,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          lesson["image"]!.startsWith('http')
                              ? Image.network(lesson["image"]!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                              : Image.asset(lesson["image"]!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder()),
                          Container(color: Colors.black.withOpacity(0.8)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  lesson["title"]!,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Flexible(
                                  child: Text(
                                    lesson["lesson"]!,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      height: 1.5,
                                    ),
                                    maxLines: 10,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  lesson["category"]!.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
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
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                favoriteService.toggleFavorite(lesson);
                              });
                              // ✅ Log analytics
                            analytics.logEvent(
                              name: isFavorite ? 'lesson_unfavorited' : 'lesson_favorited',
                              parameters: {
                                'title': lesson['title'],
                                'category': lesson['category'],
                              },
                            ).then((_) {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: "${lesson["title"]}\n\n${lesson["lesson"]}"),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Copied to Clipboard")),
                              );
                                // ✅ Log analytics
                            analytics.logEvent(
                              name: 'lesson_copied',
                              parameters: {
                                'title': lesson['title'],
                                'category': lesson['category'],
                              },
                            ).then((_) {});
  
                              
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.download, color: Colors.white),
                            onPressed: () {
                              _saveLessonImage(repaintKey); // ✅ wrapped
                               // ✅ Log analytics
                            analytics.logEvent(
                              name: 'lesson_saved',
                              parameters: {
                                'title': lesson['title'],
                                'category': lesson['category'],
                              },
                            ).then((_) {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () {
                              _shareLesson(repaintKey, lesson["title"]!, lesson["lesson"]!); // ✅ wrapped
                                // ✅ Log analytics
                              analytics.logEvent(
                                name: 'lesson_shared',
                                parameters: {
                                  'title': lesson['title'],
                                  'category': lesson['category'],
                                },
                              ).then((_) {});

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

  Widget _placeholder() {
    return Container(
      color: Colors.grey,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported, size: 80, color: Colors.white),
    );
  }
}
