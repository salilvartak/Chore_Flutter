import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Added back
import 'splash_screen.dart';

// --- Added back your background message handler ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    
    // --- Added back the listener registration ---
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
        scaffoldBackgroundColor: const Color(0xFF0F172A), 
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981), 
          secondary: Color(0xFF6366F1), 
          surface: Color(0xFF1E293B), 
          onPrimary: Color(0xFFF8FAFC),
          onSurface: Color(0xFFF8FAFC),
        ),
        appBarTheme: const AppBarThemeData(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Color(0xFFF8FAFC), fontSize: 22, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981), 
            foregroundColor: const Color(0xFFF8FAFC),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B), 
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            side: const BorderSide(color: Color(0xFF334155), width: 1), 
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
          modalBackgroundColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)), 
          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6366F1))), 
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1E293B),
          indicatorColor: const Color(0xFF6366F1).withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold);
            }
            return const TextStyle(color: Color(0xFF94A3B8));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF6366F1));
            }
            return const IconThemeData(color: Color(0xFF94A3B8));
          }),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFF8FAFC)),
          bodyMedium: TextStyle(color: Color(0xFFF8FAFC)),
          titleMedium: TextStyle(color: Color(0xFFF8FAFC)),
          titleSmall: TextStyle(color: Color(0xFF94A3B8)),
        ),
      ),
      home: const SplashScreen(), 
    );
  }
}