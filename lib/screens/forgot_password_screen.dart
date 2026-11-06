import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {

  final emailController = TextEditingController();

  bool showPassword = false;

  void resetPassword() async {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(email)) {
      _showError('Please enter a valid email');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset link sent to your email',
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              email: email,
            ),
          ),
        );
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showError('No account found with this email');
      } else {
        _showError('Something went wrong. Please try again.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [
              const SizedBox(height: 30),

              const CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(
                  Icons.lock_reset_outlined,
                  size: 50,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Reset Your Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Enter your email to receive a password reset link.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 35),

              // Email
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                obscureText: false,
                decoration: InputDecoration(
                  hintText: 'Email',

                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF2E7D32),
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton(
                  onPressed: resetPassword,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  child: const Text(
                    'Send Reset Link',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}