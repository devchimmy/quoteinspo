import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quote_application/main.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DailyQuotePage extends StatefulWidget {
  const DailyQuotePage({super.key, this.quoteId});
  final String? quoteId;

  @override
  State<DailyQuotePage> createState() => _DailyQuotePageState();
}

class _DailyQuotePageState extends State<DailyQuotePage> {
  final ScreenshotController screenshotController = ScreenshotController();
  PageController? pageController;

  List<Map<String, String>> quotesWithBackgrounds = [];
  Map<String, int> dateToIndex = {};
  int currentPage = 0;
  bool _isLoading = true;
  bool _readyToShow = false;

  @override
  void initState() {
    super.initState();
    loadQuotes();
  }

  Future<void> loadQuotes() async {
    try {
      final quotesJson = await rootBundle.loadString('assets/json/daily_quotes.json');
      final backgroundsJson = await rootBundle.loadString('assets/json/dailyquotes_backgrounds.json');

      final List<dynamic> quotesList = json.decode(quotesJson);
      final List<dynamic> bgList = json.decode(backgroundsJson)['dailyquotes_backgrounds'];

      List<Map<String, String>> combined = [];

      for (int i = 0; i < quotesList.length; i++) {
        final quote = Map<String, dynamic>.from(quotesList[i]);
        final bg = bgList[i % bgList.length];
        final date = quote['date']?.toString() ?? '';

        final quoteMap = {
          'quote': quote['quote']?.toString() ?? '',
          'date': date,
          'background': bg.toString(),
        };

        combined.add(quoteMap);
        dateToIndex[date] = i;
      }

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final targetIndex = dateToIndex[todayStr] ?? 0;

      setState(() {
        quotesWithBackgrounds = combined;
        currentPage = targetIndex;
        _isLoading = false;
        _readyToShow = true;
        pageController = PageController(initialPage: targetIndex);
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading quotes: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> saveToGallery() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      Fluttertoast.showToast(msg: "Storage permission denied");
      return;
    }

    final image = await screenshotController.capture();
    if (image != null) {
      await ImageGallerySaver.saveImage(Uint8List.fromList(image));
      Fluttertoast.showToast(msg: "Saved to Gallery");
       // ✅ Log analytics event
    analytics.logEvent(
      name: 'daily_quote_saved',
      parameters: {
        'quote_index': currentPage,
        'quote_text': quotesWithBackgrounds[currentPage]['quote'],
      },
    ).then((_) {});
    }
  }

  Future<void> shareQuoteImage() async {
    final image = await screenshotController.capture();
    if (image != null) {
      final directory = await getTemporaryDirectory();
      final imagePath = File('${directory.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png');
      await imagePath.writeAsBytes(image);
      await Share.shareXFiles([XFile(imagePath.path)],);
      
    // ✅ Log analytics event
    analytics.logEvent(
      name: 'daily_quote_shared',
      parameters: {
        'quote_index': currentPage,
        'quote_text': quotesWithBackgrounds[currentPage]['quote'],
      },
    ).then((_) {});
    }
  }

  Widget buildDateLabel(String dateStr) {
    final DateTime parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
    final String day = DateFormat('EEEE').format(parsedDate);
    final String fullDate = DateFormat('MMMM d, yyyy').format(parsedDate);
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1))],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            fullDate,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black87, blurRadius: 5, offset: Offset(1, 2))],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildQuoteCard(Map<String, String> quoteData) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          quoteData['background'] ?? '',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Text("Failed to load background", style: TextStyle(color: Colors.white)),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black, Colors.transparent],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: buildDateLabel(quoteData['date'] ?? ''),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: Text(
              quoteData['quote'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.5,
                shadows: [Shadow(color: Colors.black87, blurRadius: 2, offset: Offset(1, 1))],
              ),
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

  Widget buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: "Share",
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: shareQuoteImage,
            iconSize: 30,
          ),
          const SizedBox(width: 100),
          IconButton(
            tooltip: "Save",
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: saveToGallery,
            iconSize: 30,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        setState(() => _readyToShow = false);
        await Future.delayed(const Duration(milliseconds: 80));
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("Daily Quotes"),
          backgroundColor: Colors.black54,
        ),
        body: _isLoading || !_readyToShow || pageController == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Screenshot(
                    controller: screenshotController,
                    child: PageView.builder(
                      controller: pageController!,
                      itemCount: quotesWithBackgrounds.length,
                      onPageChanged: (index) => setState(() => currentPage = index),
                      itemBuilder: (context, index) {
                        return buildQuoteCard(quotesWithBackgrounds[index]);
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: buildActionButtons(),
                  ),
                ],
              ),
      ),
    );
  }
}
