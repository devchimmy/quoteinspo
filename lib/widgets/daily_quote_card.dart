import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DailyQuoteCard extends StatefulWidget {
  const DailyQuoteCard({super.key});

  @override
  State<DailyQuoteCard> createState() => _DailyQuoteCardState();
}

class _DailyQuoteCardState extends State<DailyQuoteCard> {
  String quote = "Loading...";
  String bgImageUrl = "";

  @override
  void initState() {
    super.initState();
    loadDailyQuoteAndBackground();
  }

  Future<void> loadDailyQuoteAndBackground() async {
    try {
      final quotesJson =
          await rootBundle.loadString('assets/json/daily_quotes.json');
      final backgroundsJson = await rootBundle
          .loadString('assets/json/dailyquotes_backgrounds.json');

      final List<dynamic> quotesList = json.decode(quotesJson);
      final List<dynamic> bgList =
          json.decode(backgroundsJson)['dailyquotes_backgrounds'];

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final quoteEntry = quotesList.firstWhere(
        (q) => q['date'] == today,
        orElse: () => null,
      );

      if (quoteEntry != null) {
        final index = today.hashCode.abs() % bgList.length;
        setState(() {
          quote = quoteEntry['quote'];
          bgImageUrl = bgList[index];
        });
      } else {
        setState(() {
          quote = "No quote found for today.";
        });
      }
    } catch (e) {
      setState(() {
        quote = "Error loading quote.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: AspectRatio(
        aspectRatio: 22 / 12, // Landscape layout
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bgImageUrl.isNotEmpty)
                Image.network(
                  bgImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text("Image failed", style: TextStyle(color: Colors.white)),
                  ),
                ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Title and Quote Column
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 12.0),
                    child: Text(
                      'Daily Quote',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          quote,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.4,
                            decoration: TextDecoration.none,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
