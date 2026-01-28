import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:quote_application/services/notification_service.dart';
import 'package:quote_application/models/random_quotes.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class DailyNotificationsScheduler {
  /// Initialize user's timezone and schedule notifications
  static Future<void> scheduleAllDailyNotifications() async {
    try {
      // Get user's local timezone dynamically
      String timeZoneName = 'UTC';
      try {
        timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      } catch (e) {
        timeZoneName = 'UTC';
      }

      final location = tz.getLocation(timeZoneName);
      final now = tz.TZDateTime.now(location);

      // Define fixed times
      final eightAm = _nextInstanceOfTime(now, 8, 10, location);
      final twoPm = _nextInstanceOfTime(now, 14, 30, location);
      final eightPm = _nextInstanceOfTime(now, 20, 30, location);

      // Shuffle detail images
      final dailyDetailImage = 'images/detail_daily_${Random().nextInt(10) + 1}.webp';
      final lifeLessonDetailImage = 'images/detail_lifelesson_${Random().nextInt(10) + 1}.webp';
      final randomDetailImage = 'images/detail_random_${Random().nextInt(10) + 1}.webp';

      // Load daily quote based on scheduled time using correct timezone
      final formattedDate = _formatDate(eightAm);
      final dailyQuote = await _loadDailyQuoteByDate(location: location, specificDate: formattedDate);

      // Load random quote & life lesson normally
      final randomQuote = await RandomQuote.getRandomQuoteAndImage();
      final lifeLesson = await _loadRandomLifeLesson();

      // Schedule Daily Quote
      await NotificationService.scheduleCustomNotification(
        id: 1,
        title: ' Daily Quote',
        body: dailyQuote['quote'],
        hour: eightAm.hour,
        minute: 10,
        payload: jsonEncode({
          'type': 'daily',
          'quote': dailyQuote['quote'],
          'date': formattedDate,
          'backgroundImage': dailyDetailImage,
        }),
        imageUrl: 'images/dailyquotesbg.webp',
      );

      // Schedule Life Lesson
      await NotificationService.scheduleCustomNotification(
        id: 2,
        title: ' Life Lesson',
        body: lifeLesson['lesson'],
        hour: twoPm.hour,
        minute: 30,
        payload: jsonEncode({
          'type': 'lifelesson',
          'lesson': lifeLesson['lesson'],
          'category': lifeLesson['category'],
          'backgroundImage': lifeLessonDetailImage,
        }),
        imageUrl: 'images/lifelessonsbg.webp',
      );

      // Schedule Random Quote
      await NotificationService.scheduleCustomNotification(
        id: 3,
        title: ' Random Quote',
        body: randomQuote['quote'],
        hour: eightPm.hour,
        minute: 30,
        payload: jsonEncode({
          'type': 'random',
          'quote': randomQuote['quote'],
          'category': randomQuote['category'],
          'backgroundImage': randomDetailImage,
        }),
        imageUrl: 'images/randomquotesbg.webp',
      );

    } catch (e) {
      // Error handling can be done silently or logged to a service in production
    }
  }

  /// Compute next instance of specific time in user's timezone
  static tz.TZDateTime _nextInstanceOfTime(
      tz.TZDateTime now, int hour, int minute, tz.Location location) {
    final scheduled = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    return scheduled.isBefore(now) ? scheduled.add(const Duration(days: 1)) : scheduled;
  }

  /// Format date as yyyy-MM-dd
  static String _formatDate(tz.TZDateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  /// Load daily quote from JSON by date (uses user's timezone)
  static Future<Map<String, dynamic>> _loadDailyQuoteByDate({
    String? specificDate,
    required tz.Location location,
  }) async {
    final now = tz.TZDateTime.now(location);
    final formattedDate = specificDate ?? _formatDate(now);

    final String data = await rootBundle.loadString('assets/json/daily_quotes.json');
    final List<dynamic> quotes = json.decode(data);

    final quote = quotes.cast<Map<String, dynamic>>().firstWhere(
      (q) => q['date'] == formattedDate,
      orElse: () {
        final index = now.day % quotes.length;
        final fallback = quotes[index];
        return {
          'quote': fallback['quote'] ?? 'Start your day with inspiration.',
          'date': formattedDate,
          'backgroundImage': fallback['backgroundImage'] ?? '',
        };
      },
    );

    return quote;
  }

  /// Load a random life lesson from multiple JSON files
  static Future<Map<String, dynamic>> _loadRandomLifeLesson() async {
    final paths = [
      'assets/json/motivation_lifelessons.json',
      'assets/json/inspiration_lifelessons.json',
      'assets/json/love_lifelessons.json',
      'assets/json/hustle_lifelessons.json',
      'assets/json/travel_lifelessons.json',
      'assets/json/relationship_lifelessons.json',
      'assets/json/heartbreak_lifelessons.json',
      'assets/json/self_discovery_lifelessons.json',
      'assets/json/confidence_lifelessons.json',
      'assets/json/growth_lifelessons.json',
    ];
    paths.shuffle();
    final path = paths.first;
    final data = await rootBundle.loadString(path);
    final list = json.decode(data);
    return Map<String, dynamic>.from(list[Random().nextInt(list.length)]);
  }
}
