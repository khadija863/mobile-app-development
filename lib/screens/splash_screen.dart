import 'dart:async';
import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF4),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // FoodLink Logo
              Container(
                height: 130,
                width: 130,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volunteer_activism,
                  size: 65,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'FoodLink',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Share Food • Spread Love',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7A817A),
                ),
              ),

              const Spacer(),

              const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Loading...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B756B),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}