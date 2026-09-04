import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_page.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    Timer(const Duration(seconds: 4), () {
      _checkLoginAndNavigate();
    });
  }

  Future<void> _checkLoginAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn =
        prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            isLoggedIn ? const HomePage() : const RegisterPage(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [

          // Background Image
          Image.asset(
            "assets/images/splash_bg.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Light Overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withAlpha(40),
            ),
          ),

          // Logo + Brand Text
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Logo
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/images/app.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Brand Name
                  const Text(
                    "Sumathi's Styles",
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff0F766E),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Tagline row with divider dashes
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 24,
                        child: Divider(color: Color(0xffC89A2B), thickness: 1),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Fashion Designer",
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                          color: Color(0xffC89A2B),
                        ),
                      ),
                      SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Divider(color: Color(0xffC89A2B), thickness: 1),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Sub-tagline
                  const Text(
                    "Crafted with Elegance",
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Color(0xff0F766E),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator pinned near bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xffC89A2B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}