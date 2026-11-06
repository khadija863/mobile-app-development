import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool showPassword = false;
  bool isLoading = false;

  String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Please enter your email';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  // =====================================================
  // CREATE ACCOUNT WITH FIREBASE
  // =====================================================

  Future<void> createAccount() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (name.isEmpty) {
      _showError('Please enter your full name');
      return;
    }

    String? emailError = validateEmail(email);

    if (emailError != null) {
      _showError(emailError);
      return;
    }

    if (password.isEmpty) {
      _showError('Please enter a password');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (confirmPassword.isEmpty) {
      _showError('Please confirm your password');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Create Firebase account
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user's name in Firebase Authentication
      await userCredential.user?.updateDisplayName(name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
          ),
        );

        // Go to Login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              name: name,
              email: email,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Account creation failed';

      if (e.code == 'email-already-in-use') {
        message = 'An account already exists with this email';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/Password sign-in is not enabled';
      }

      _showError(message);
    } catch (e) {
      _showError('Something went wrong. Please try again');
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Create Account',
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
              const SizedBox(height: 15),

              const CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(
                  Icons.person_add_outlined,
                  size: 45,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Join FoodLink',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Create an account to get started',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 35),

              _field(
                'Full Name',
                Icons.person_outline,
                nameController,
                false,
              ),

              const SizedBox(height: 15),

              _field(
                'Email',
                Icons.email_outlined,
                emailController,
                false,
              ),

              const SizedBox(height: 15),

              // Password
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  hintText: 'Password',

                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF2E7D32),
                  ),

                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                    icon: Icon(
                      showPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Confirm Password
              _field(
                'Confirm Password',
                Icons.lock_reset_outlined,
                confirmPasswordController,
                true,
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton(
                  onPressed: isLoading ? null : createAccount,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already registered? ',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const LoginScreen(),
                        ),
                      );
                    },

                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String hint,
    IconData icon,
    TextEditingController controller,
    bool password,
  ) {
    return TextField(
      controller: controller,
      obscureText: password,

      keyboardType: hint == 'Email'
          ? TextInputType.emailAddress
          : TextInputType.text,

      decoration: InputDecoration(
        hintText: hint,

        prefixIcon: Icon(
          icon,
          color: const Color(0xFF2E7D32),
        ),

        filled: true,
        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }
}