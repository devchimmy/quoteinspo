import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:quote_application/main.dart';

class NotificationTapHandler {
  static void handleNotificationTap(String payload) {
    debugPrint('🔍 Handling notification payload: $payload');

    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final String type = data['type'];
            // ✅ Log analytics event for notification open
      analytics.logEvent(
        name: 'notification_opened',
        parameters: {
          'type': type, // 'random', 'daily', 'lifelesson'
          'quote_id': data['id'] ?? data['date'] ?? '',
          'category': data['category'] ?? 'Unknown',
        },
      );


      switch (type) {
        case 'random':
          if (data.containsKey('quote') &&
              data['category'] != null &&
              data['backgroundImage'] != null) {
            navigatorKey.currentState?.pushNamed(
              '/randomQuoteDetail',
              arguments: {
                'quote': data['quote'],
                'category': data['category'],
                'backgroundImage': data['backgroundImage'] ?? data['image'],

              },
            );
          } else {
            debugPrint('❌ Missing required fields for random quote.');
          }
          break;

        case 'daily':
          if (data.containsKey('quote') &&
    (data.containsKey('date') || data.containsKey('id')) &&
    (data.containsKey('backgroundImage') || data.containsKey('image')))
 {
            navigatorKey.currentState?.pushNamed(
              '/dailyQuoteDetail',
              arguments: {
    'quote': data['quote'],
    'date': data['date'] ?? data['id'] ?? '2025-01-01',
    'backgroundImage': data['backgroundImage'] ?? data['image'] ?? 'images/dailyquotesbg.png',
  },
);
          } else {
            debugPrint('❌ Missing required fields for daily quote.');
          }
          break;

        case 'lifelesson':
          if (data.containsKey('lesson') &&
    data.containsKey('category') &&
    data['backgroundImage'] != null)
 {
            navigatorKey.currentState?.pushNamed(
              '/lifeLessonDetail',
             arguments: {
    'lesson': data['lesson'],
    'category': data['category'] ?? 'Life',
    'backgroundImage': data['backgroundImage'] ?? data['image'] ?? 'images/lifelessonsbg.png',
  },
);
          } else {
            debugPrint('❌ Missing required fields for life lesson.');
          }
          break;

        default:
          debugPrint('⚠️ Unknown notification type: $type');
      }
    } catch (e) {
      debugPrint('❌ Error parsing notification payload: $e');
    }
  }
}
