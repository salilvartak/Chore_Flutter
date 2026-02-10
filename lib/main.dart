import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  // If you haven't generated firebase_options.dart via CLI, 
  // ensure google-services.json is in android/app/
  await Firebase.initializeApp();

  // 3. Run the App
  runApp(const MyApp());
}

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
      // We start at the LoginScreen. 
      // The LoginScreen will handle the check to see if the user 
      // is already signed in and redirect them if necessary.
      home: LoginScreen(),
    );
  }
}