import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // 1. Request Permission
  Future<void> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
  }

  // 2. Get Token & Save to Firestore
  Future<void> saveToken() async {
    String? token = await _messaging.getToken();
    User? user = FirebaseAuth.instance.currentUser;

    if (token != null && user != null) {
      // Save the token to the user's document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'fcmToken': token, // We will use this later to send notifications!
      }, SetOptions(merge: true));
      
      print("FCM Token Saved: $token");
    }
  }

  // 3. Listen for Messages (Foreground)
  void initForegroundListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // You could show a local dialog/snackbar here if you want
      }
    });
  }
}