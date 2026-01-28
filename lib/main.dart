import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:quote_application/detailed%20pages/daily_quote_detail_page.dart';
import 'package:quote_application/pages/launcher_page.dart';
import 'package:quote_application/services/favorite_quotes_service.dart';
import 'package:quote_application/detailed%20pages/life_lesson_detail_page.dart';
import 'package:quote_application/services/notification_tap_handler.dart';
import 'package:quote_application/detailed%20pages/random_quotes_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'daily_notification_scheduler.dart';
import 'navigations component/mainscaffold.dart';
import 'pages/quote_category_grid_page.dart';
import 'theme/theme_provider.dart';

/// 🔑 Global navigator key for deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//Firebase Analytics instance
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
final FirebaseAnalyticsObserver analyticsObserver =
    FirebaseAnalyticsObserver(analytics: analytics);

/// 🔁 Background FCM handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('🔄 Background FCM: ${message.notification?.title} - ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  await NotificationService.initialize();
  await DailyNotificationsScheduler.scheduleAllDailyNotifications();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  // ✅ Get payload if app was launched via a notification
  final NotificationAppLaunchDetails? notificationLaunchDetails =
      await NotificationService.flutterLocalNotificationsPlugin
          .getNotificationAppLaunchDetails();

  final String? initialPayload = (notificationLaunchDetails?.didNotificationLaunchApp ?? false)
      ? notificationLaunchDetails?.notificationResponse?.payload
      : null;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteQuotesService()),
      ],
      child: MyApp(
        onboardingCompleted: onboardingCompleted,
        initialPayload: initialPayload,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool onboardingCompleted;
  final String? initialPayload;

  const MyApp({
    super.key,
    required this.onboardingCompleted,
    this.initialPayload,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();

    // ✅ Handle notification deep link if app launched from background
    if (widget.initialPayload != null) {
      Future.delayed(Duration.zero, () {
        NotificationTapHandler.handleNotificationTap(widget.initialPayload!);
      });
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permission granted');
      await messaging.subscribeToTopic('all');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📲 Foreground FCM: ${message.notification?.title}');
        if (message.notification != null) {
          NotificationService.showLocalNotification(
            title: message.notification!.title ?? 'Quote App',
            body: message.notification!.body ?? '',
            payload: message.data['payload'], // ✅ working now
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🟢 Notification tapped while app in background');
        if (message.data['payload'] != null) {
          NotificationTapHandler.handleNotificationTap(message.data['payload']);
        }
      });

      try {
        final token = await messaging.getToken();
        debugPrint('📱 FCM Token: $token');
      } catch (e) {
        debugPrint('⚠️ Failed to get FCM token: $e');
      }
    } else {
      debugPrint('❌ Notification permission denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
           navigatorObservers: [analyticsObserver], //observer
          home: const LauncherPage(),
          initialRoute: '/',
          routes: {
            '/getstarted': (context) => QuoteCategoryGridPage(),
            '/home': (context) => const MainScaffold(),

            // ✅ RANDOM QUOTE DETAIL
            '/randomQuoteDetail': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              debugPrint("🟢 Opened RandomQuoteDetail with: $args");
              if (args is Map<String, dynamic> &&
                  args.containsKey('quote') &&
                  args.containsKey('category') &&
                  args.containsKey('backgroundImage')) {
                return RandomQuoteDetailPage(
                  quote: args['quote'],
                  category: args['category'],
                  backgroundImage: args['backgroundImage'],
                );
              } else {
                return _errorPage('❌ Missing or invalid arguments for randomQuoteDetail');
              }
            },

            // ✅ DAILY QUOTE DETAIL
            '/dailyQuoteDetail': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              debugPrint("🟢 Opened DailyQuoteDetail with: $args");
              if (args is Map<String, dynamic> &&
                  args.containsKey('date') &&
                  args.containsKey('quote') &&
                  args.containsKey('backgroundImage')) {
                return DailyQuoteDetailPage(
                  date: args['date'],
                  quote: args['quote'],
                  backgroundImage: args['backgroundImage'],
                );
              } else {
                return _errorPage('❌ Missing or invalid arguments for dailyQuoteDetail');
              }
            },

            // ✅ LIFE LESSON DETAIL
            '/lifeLessonDetail': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              debugPrint("🟢 Opened LifeLessonDetail with: $args");
              if (args is Map<String, dynamic> &&
                  args.containsKey('lesson') &&
                  args.containsKey('category') &&
                  args.containsKey('backgroundImage')) {
                return LifeLessonDetailPage(
                  lesson: args['lesson'],
                  category: args['category'],
                  backgroundImage: args['backgroundImage'],
                );
              } else {
                return _errorPage('❌ Invalid or missing arguments for lifeLessonDetail');
              }
            },
          },
        );
      },
    );
  }

  // Generic error screen
  Widget _errorPage(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text(message)),
    );
  }
}
