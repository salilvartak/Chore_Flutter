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

  @override
  void initState() {
    super.initState();
    // Optional: Check if user is already signed in when the screen loads
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _checkFamilyAndRedirect(user);
    }
  }

  /// Checks Firestore to see if the user belongs to a family
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
          // CASE 1: User has a family -> Go to Home
          String familyId = data['familyId'];
          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => HomeScreen(familyId: familyId))
            );
          }
        } else {
          // CASE 2: User exists but has no family -> Go to Create/Join
          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => CreateJoinScreen())
            );
          }
        }
      } else {
        // CASE 3: User document doesn't exist yet (New User) -> Go to Create/Join
        if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => CreateJoinScreen())
          );
        }
      }
    } catch (e) {
      print("Error checking user data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    // 1. Perform Google Sign In
    User? user = await _authService.signInWithGoogle();
    
    if (user != null) {
      // 2. Check Logic
      await _checkFamilyAndRedirect(user);
    } else {
      // Sign in cancelled or failed
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Section
              Icon(Icons.family_restroom, size: 100, color: Colors.blue),
              SizedBox(height: 20),
              
              Text(
                'FamChores',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
              ),
              Text(
                'Sync tasks, happy home.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 60),

              // Loading Indicator OR Sign-In Button
              _isLoading
                  ? Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Checking your account...", style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        icon: Icon(Icons.login, color: Colors.blue), 
                        label: Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.w600
                          ),
                        ),
                        onPressed: _handleGoogleSignIn,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}