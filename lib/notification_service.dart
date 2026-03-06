import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // 1. Initialize Local Notifications Plugin
  Future<void> initLocalNotifications() async {
    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );
    
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("Local Notification Tapped in Foreground!");
      },
    );
  }

  // 2. Request Permission
  Future<void> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  // 3. Get Token & Save to Firestore
  Future<void> saveToken() async {
    String? token = await _messaging.getToken();
    User? user = FirebaseAuth.instance.currentUser;

    if (token != null && user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token, 
      }, SetOptions(merge: true));
      
      // --- PRINT TOKEN FOR FIREBASE TESTING ---
      debugPrint("========= FCM TOKEN =========");
      debugPrint(token);
      debugPrint("=============================");
    }
  }

  // 4. Listen for Messages (Foreground)
  void initForegroundListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null) {
        _showLocalNotification(message.notification!);
      }
    });
  }

  // 5. Function to actually build and show the pop-up
  Future<void> _showLocalNotification(RemoteNotification notification) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'famchores_channel', 
      'Chore Notifications', 
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
    );
  }

  // 6. Handle clicks on background/terminated notifications
  Future<void> setupInteractMessage(BuildContext context) async {
    // Scenario A: App is completely closed (Terminated)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(context, initialMessage);
    }

    // Scenario B: App is minimized in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(context, message);
    });
  }

  void _handleMessage(BuildContext context, RemoteMessage message) {
    debugPrint("Notification Clicked! Title: ${message.notification?.title}");
    
    // Show a green snackbar at the bottom of the screen to prove the tap worked!
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("You opened: ${message.notification?.title}"),
        backgroundColor: const Color(0xFF10B981), // Emerald Green
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}