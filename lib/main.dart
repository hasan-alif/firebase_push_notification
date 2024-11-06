import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'home.dart';

AndroidNotificationChannel? channel;
FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
late FirebaseMessaging messaging;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler for Firebase Messaging
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling background message: ${message.messageId}");
}

// Handler for background notification tap (when app is in the background or terminated)
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Notification tapped: ${notificationResponse.id}, Action: ${notificationResponse.actionId}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    print('Notification action input: ${notificationResponse.input}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  messaging = FirebaseMessaging.instance;

  // Request permission to show notifications on iOS
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    carPlay: false,
    provisional: false,
    criticalAlert: false,
    announcement: false,
  );

  // Get and print the FCM token
  final fcmToken = await messaging.getToken();
  print("FCM Token: $fcmToken");

  // Subscribe to a topic to receive group notifications
  await messaging.subscribeToTopic('flutter_notification');

  // Handle background messages with a dedicated background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local notifications only for non-web platforms
  if (!kIsWeb) {
    await _initializeLocalNotifications();
  }

  // Start the app
  runApp(const MyApp());
}

Future<void> _initializeLocalNotifications() async {
  // Create an Android Notification Channel for high-priority notifications
  channel = const AndroidNotificationChannel(
    'flutter_notification', // Channel ID
    'Flutter Notifications', // Channel name
    importance: Importance.high,
    enableLights: true,
    enableVibration: true,
    showBadge: true,
    playSound: true,
  );

  // Initialize the Flutter Local Notifications Plugin
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Configure Android and iOS initialization settings
  const androidInitialization = AndroidInitializationSettings('@drawable/ic_notifications_icon');
  const iOSInitialization = DarwinInitializationSettings();
  var initSettings = const InitializationSettings(android: androidInitialization, iOS: iOSInitialization);

  // Initialize the local notifications plugin and set notification tap handlers
  await flutterLocalNotificationsPlugin!.initialize(
    initSettings,
    onDidReceiveNotificationResponse: notificationTapBackground,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // Configure notification presentation options for when the app is in the foreground
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Notification',
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorKey: navigatorKey,
      home: const HomePage(),
    );
  }
}


