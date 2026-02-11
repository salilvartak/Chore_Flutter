import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FamChores',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFEAECC5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2CC0E4),
          primary: const Color(0xFF2CC0E4),
          surface: const Color(0xFFEAECC5),
        ),
        appBarTheme: const AppBarThemeData(
          backgroundColor: Color(0xFFEAECC5),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Color(0xFF2C3E50)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2CC0E4),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.9), // Slightly more opaque for better readability
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        // Global BottomSheet Style
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
          modalBackgroundColor: Colors.transparent,
        ),
      ),
      home: LoginScreen(),
    );
  }
}