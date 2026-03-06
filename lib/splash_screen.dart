import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'create_join_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  late AnimationController _loaderController;
  late Animation<double> _loaderAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _loaderAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _loaderController, curve: Curves.easeInOut),
    );

    _logoController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Run the 2.5s timer and the database check AT THE SAME TIME
    var results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 2500)),
      _determineNextScreen(), // This now just returns a Widget, it doesn't navigate yet!
    ]);

    // 2. NOW that both the timer is done AND the screen is built, we safely navigate
    if (mounted) {
      Widget nextScreen = results[1] as Widget; // Get the widget returned from the auth check

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => nextScreen,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  // --- NEW: This just figures out where to go, but doesn't do the moving ---
  Future<Widget> _determineNextScreen() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          if (data.containsKey('familyId') && data['familyId'] != null) {
            return HomeScreen(familyId: data['familyId']);
          } else {
            return CreateJoinScreen();
          }
        } else {
          return CreateJoinScreen();
        }
      }
    } catch (e) {
      debugPrint("Splash Screen Safety Catch: $e");
    }
    
    // Default fallback if anything fails or no user is logged in
    return LoginScreen(); 
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: CustomPaint(
                        painter: SvgLogoPainter(),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Container(
              width: 120,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), 
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedBuilder(
                animation: _loaderAnimation,
                builder: (context, child) {
                  return FractionalTranslation(
                    translation: Offset(_loaderAnimation.value, 0.0),
                    child: Container(
                      width: 48, 
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981), 
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SvgLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    final scale = size.width / 1500.0;
    canvas.scale(scale, scale);

    final path1 = Path()
      ..moveTo(980.519531, 947.242188)
      ..lineTo(1416.035156, 947.242188)
      ..lineTo(1416.035156, 1425)
      ..lineTo(980.519531, 1425)
      ..close();

    final path2 = Path()
      ..moveTo(515.984375, 606.550781)
      ..lineTo(515.984375, 85.941406)
      ..lineTo(80.46875, 85.941406)
      ..lineTo(80.46875, 1060.148438)
      ..cubicTo(165.871094, 861.539062, 321.019531, 700.003906, 515.984375, 606.550781)
      ..close();

    final path3 = Path()
      ..moveTo(515.984375, 1403.269531)
      ..lineTo(80.46875, 1414.058594)
      ..cubicTo(80.46875, 975.203125, 425.113281, 613.542969, 863.359375, 592.417969)
      ..lineTo(984.015625, 586.644531)
      ..lineTo(984.015625, 75)
      ..lineTo(1419.53125, 75)
      ..lineTo(1419.53125, 869.742188)
      ..lineTo(1060.453125, 869.742188)
      ..cubicTo(763.980469, 869.742188, 522.0625, 1106.796875, 515.984375, 1403.269531)
      ..close();

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}