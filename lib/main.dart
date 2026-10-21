import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'pages/login_screen.dart';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'default_channel',
  'Genel Bildirimler',
  description: 'Ersay CRM bildirimleri',
  importance: Importance.high,
);

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint('==============================');
  debugPrint('BACKGROUND BILDIRIM GELDI');
  debugPrint('TITLE: ${message.notification?.title}');
  debugPrint('BODY : ${message.notification?.body}');
  debugPrint('DATA : ${message.data}');
  debugPrint('==============================');
}

Future<void> _setupNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  const initSettings = InitializationSettings(android: androidInit);

  await localNotifications.initialize(settings: initSettings);

  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  final permission = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint('==============================');
  debugPrint('FCM PERMISSION STATUS: ${permission.authorizationStatus}');
  debugPrint('==============================');

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('==============================');
    debugPrint('FOREGROUND BILDIRIM GELDI');
    debugPrint('TITLE: ${message.notification?.title}');
    debugPrint('BODY : ${message.notification?.body}');
    debugPrint('DATA : ${message.data}');
    debugPrint('==============================');

    final notification = message.notification;

    if (notification != null) {
      localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: notification.title ?? 'Yeni Bildirim',
        body: notification.body ?? '',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('==============================');
    debugPrint('BILDIRIME TIKLANDI');
    debugPrint('TITLE: ${message.notification?.title}');
    debugPrint('BODY : ${message.notification?.body}');
    debugPrint('DATA : ${message.data}');
    debugPrint('==============================');
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    debugPrint('==============================');
    debugPrint('KAPALIYKEN BILDIRIMDEN ACILDI');
    debugPrint('TITLE: ${initialMessage.notification?.title}');
    debugPrint('BODY : ${initialMessage.notification?.body}');
    debugPrint('DATA : ${initialMessage.data}');
    debugPrint('==============================');
  }

  final token = await FirebaseMessaging.instance.getToken();

  debugPrint('==============================');
  debugPrint('FCM TOKEN');
  debugPrint(token);
  debugPrint('==============================');

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    debugPrint('==============================');
    debugPrint('FCM TOKEN YENILENDI');
    debugPrint(newToken);
    debugPrint('==============================');

    // Not:
    // Login sonrası FcmService.registerToken() zaten tokenı API'ye gönderiyor.
    // İstersen burada da API'ye yeniden gönderebiliriz.
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  await _setupNotifications();

  runApp(const ErsayCrmApp());
}

class ErsayCrmApp extends StatelessWidget {
  const ErsayCrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('tr')],
      home: const LoginScreen(),
    );
  }
}
