import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quote_application/services/notification_tap_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

/// 🔔 Background handler for notification taps
@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  debugPrint('🔁 Background notification tapped: ${response.payload}');
  if (response.payload != null) {
    NotificationTapHandler.handleNotificationTap(response.payload!);
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin =>
      _notificationsPlugin;

  /// ✅ Initialize the notification system
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    // 🕓 Use flutter_native_timezone to detect user timezone dynamically
    try {
      final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      final location = tz.getLocation(timeZoneName);
      tz.setLocalLocation(location);
      debugPrint('🌍 NotificationService timezone set to: $timeZoneName');
    } catch (e) {
      // fallback to UTC if detection fails
      tz.setLocalLocation(tz.getLocation('UTC'));
      debugPrint('⚠️ Could not detect local timezone, defaulting to UTC: $e');
    }

    debugPrint('🔧 NotificationService.initialize() called');

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('📲 Foreground/background notification tapped: ${response.payload}');
        if (response.payload != null) {
          NotificationTapHandler.handleNotificationTap(response.payload!);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackgroundHandler,
    );

    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }

    await _createNotificationChannels();
    debugPrint('✅ NotificationService initialized completely');
  }

  static Future<void> _createNotificationChannels() async {
    final android =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    final channels = [
      AndroidNotificationChannel(
        'daily_channel_id',
        'Daily Notifications',
        description: 'Quote of the day notifications',
        importance: Importance.max,
      ),
      AndroidNotificationChannel(
        'custom_channel_id',
        'Custom Notifications',
        description: 'Scheduled notifications with images',
        importance: Importance.max,
      ),
      AndroidNotificationChannel(
        'instant_channel_id',
        'Instant Notifications',
        description: 'Triggered immediately',
        importance: Importance.max,
      ),
      AndroidNotificationChannel(
        'fcm_channel_id',
        'FCM Notifications',
        description: 'Push notifications from Firebase',
        importance: Importance.max,
      ),
      AndroidNotificationChannel(
        'manual_channel_id',
        'Manual Scheduling',
        description: 'Manual time notifications',
        importance: Importance.max,
      ),
    ];

    for (var channel in channels) {
      await android.createNotificationChannel(channel);
    }
  }

  /// ✅ Schedule daily quote
  static Future<void> scheduleDailyQuote({
    required String title,
    required String body,
    int hour = 8,
    int minute = 0,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    // Schedule for today or tomorrow
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Format scheduled date for payload
    final scheduledDateString =
        "${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}";

    await _notificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel_id',
          'Daily Notifications',
          channelDescription: 'Quote of the day notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'type=daily_quote&date=$scheduledDateString',
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('✅ Daily quote scheduled for $scheduledDateString at $hour:$minute');
  }

  /// 🔔 Custom notification with image
  static Future<void> scheduleCustomNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload,
    required String imageUrl,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final String? filePath = await _getImageFilePath(imageUrl);

    final androidDetails = AndroidNotificationDetails(
      'custom_channel_id',
      'Custom Notifications',
      channelDescription: 'Scheduled notifications with images',
      styleInformation: filePath != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(filePath),
              contentTitle: title,
              summaryText: body,
            )
          : null,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 🔔 Life lesson notification
  static Future<void> scheduleLifeLessonNotification({
    required int id,
    required String title,
    required String body,
    required int lessonId,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'custom_channel_id',
          'Custom Notifications',
          channelDescription: 'Scheduled notifications with images',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'type=life_lesson&lessonId=$lessonId',
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<String?> _getImageFilePath(String assetPath) async {
    try {
      final ByteData byteData = await rootBundle.load(assetPath);
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/${assetPath.split('/').last}');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file.path;
    } catch (e) {
      debugPrint('⚠️ Error loading image asset: $e');
      return null;
    }
  }

  /// 🔹 Cancel single notification
  static Future<void> cancelScheduledNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// 🔹 Cancel all notifications
  static Future<void> cancelAllScheduledNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// 🔹 Show immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_channel_id',
      'Instant Notifications',
      channelDescription: 'Triggered immediately',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }

  /// 🔹 Show local notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'fcm_channel_id',
      'FCM Notifications',
      channelDescription: 'Push notifications from Firebase',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// 🔹 Schedule manual notification at specific DateTime
  static Future<void> scheduleNotificationAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'manual_channel_id',
          'Manual Scheduling',
          channelDescription: 'Manual time notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
