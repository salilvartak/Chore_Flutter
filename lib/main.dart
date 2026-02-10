import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';

// --- PASTE YOUR CODE HERE ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print("✅ Firebase Initialized Successfully");
  } catch (e) {
    print("❌ Firebase Initialization Failed: $e");
  }

  runApp(const MyApp());
}
// ---------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Chore Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: LoginScreen(),
    );
  }
}