import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialMessage});
  final String? initialMessage;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<NotificationData> _notifications = [];

  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
    _initializeLocalNotifications();
  }

  // Initialize Firebase Messaging handlers
  void _initializeFirebaseMessaging() {
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _showNotification(message);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _showNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Initialize local notifications
  void _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Show local notification based on Firebase message
  void _showNotification(RemoteMessage message) {
    setState(() {
      _notifications.add(NotificationData(message: message, isRead: false));
    });

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      String action = jsonEncode(message.data);

      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default Channel',
            priority: Priority.high,
            importance: Importance.max,
            setAsGroupSummary: true,
            styleInformation: DefaultStyleInformation(true, true),
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            channelShowBadge: true,
            autoCancel: true,
            icon: '@drawable/ic_notifications_icon',
          ),
        ),
        payload: action,
      );
    }
  }

  // Handle notification tap
  Future<void> _onSelectNotification(int index) async {
    setState(() {
      _notifications[index].isRead = true;
    });
    debugPrint('Notification tapped: ${_notifications[index].message.notification?.title}');
  }

  // Clear all notifications
  void _clearNotifications() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Clear Notifications'),
          content: const Text('Are you sure you want to clear all notifications?'),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                setState(() {
                  _notifications.clear();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            color: Colors.white,
            onSelected: (String value) {
              if (value == 'clear') {
                _clearNotifications();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'clear',
                  child: Text('Clear Notifications'),
                ),
              ];
            },
          ),
        ],
      ),
      body: _notifications.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                NotificationData data = _notifications[index];
                return NotificationTile(
                  message: data.message,
                  isRead: data.isRead,
                  onTap: () => _onSelectNotification(index),
                );
              },
            )
          : Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pinkAccent.withOpacity(0.6), Colors.lightBlueAccent.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: AnimatedScale(
                        scale: 1.2,
                        duration: Duration(milliseconds: 200),
                        child: Icon(
                          Icons.notifications,
                          size: 45,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Woo!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No Notification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You don\'t have any notifications',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: CupertinoColors.systemGrey2,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final RemoteMessage message;
  final bool isRead;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.message,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String formattedTime = DateFormat('hh:mm a').format(message.sentTime ?? DateTime.now());
    int avatarIndex = message.hashCode % 3;
    String avatarUrl = 'https://raw.githubusercontent.com/hasan-alif/static_images/refs/heads/master/avatar/avatar_${(avatarIndex + 1).toString().padLeft(2, '0')}.png';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      tileColor: isRead ? CupertinoColors.white : CupertinoColors.systemGrey6,
      leading: Container(
        height: 45,
        width: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: CupertinoColors.systemGrey5),
          image: DecorationImage(image: NetworkImage(avatarUrl)),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              message.notification?.title ?? 'No title',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Text(
            formattedTime,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.notification?.body ?? 'No body',
            style: TextStyle(
              fontSize: 14,
              color: isRead ? Colors.black54 : Colors.black,
            ),
          ),
        ],
      ),
      shape: const Border(bottom: BorderSide(color: CupertinoColors.systemGrey5)),
      onTap: onTap,
    );
  }
}

// Background message handler for Firebase messaging
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background message: ${message.messageId}");
}

class NotificationData {
  final RemoteMessage message;
  bool isRead;
  final DateTime receivedTime;

  NotificationData({required this.message, this.isRead = false}) : receivedTime = message.sentTime ?? DateTime.now();
}
