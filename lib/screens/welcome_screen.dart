import 'package:flutter/material.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              const Spacer(),

              const Text(
                'Welcome to FoodLink',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Share Food, Spread Love',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 35),

              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.volunteer_activism,
                  size: 110,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                'Connect food with people in need.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF555555),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}