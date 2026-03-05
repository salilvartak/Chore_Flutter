import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'create_join_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // We removed initState() and the initial check here 
  // because SplashScreen.dart now handles the auth check before this screen loads.

  Future<void> _checkFamilyAndRedirect(User user) async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('familyId') && data['familyId'] != null) {
          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => HomeScreen(familyId: data['familyId']))
            );
          }
          return;
        }
      }
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CreateJoinScreen()));
      }
    } catch (e) {
      debugPrint("Check user error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    User? user = await _authService.signInWithGoogle();
    if (user != null) {
      await _checkFamilyAndRedirect(user);
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: const Color(0xFF0F172A), // Base layer background
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // IMAGE ASSET FOR LOGO
                Container(
                  height: 128,
                  width: 128,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15), // Indigo subtle bg
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias, // Ensures image clips to the circle shape
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset(
                      'assets/logo.png', // Ensure this matches your pubspec.yaml and folder structure
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported, size: 60, color: Color(0xFF6366F1));
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                const Text(
                  'FamChores',
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFFF8FAFC), letterSpacing: -1.5),
                ),
                const Text(
                  'Sync tasks, happy home.',
                  style: TextStyle(fontSize: 18, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF10B981))
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: const Color(0xFFF8FAFC),
                          side: const BorderSide(color: Color(0xFF334155)),
                        ),
                        icon: const Icon(Icons.login, color: Color(0xFF10B981)), // Emerald icon
                        label: const Text('Sign in with Google'),
                        onPressed: _handleGoogleSignIn,
                      ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}