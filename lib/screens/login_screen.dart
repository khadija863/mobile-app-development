import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'signup_screen.dart';
import 'role_selection_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? name;
  final String? email;

  const LoginScreen({
    super.key,
    this.name,
    this.email,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController emailController;
  final passwordController = TextEditingController();

  bool showPassword = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    emailController = TextEditingController(
      text: widget.email ?? '',
    );
  }

  // =====================================================
  // FIREBASE LOGIN
  // =====================================================

  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    // Email validation
    if (email.isEmpty) {
      _showError('Please enter your email');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showError('Please enter a valid email');
      return;
    }

    // Password validation
    if (password.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RoleSelectionScreen(
              userName: user.displayName ?? widget.name ?? 'User',
              userEmail: user.email ?? email,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      if (e.code == 'invalid-credential') {
        message = 'Invalid email or password';
      } else if (e.code == 'user-not-found') {
        message = 'No account found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later';
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

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Column(
            children: [
              const SizedBox(height: 45),

              const CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(
                  Icons.restaurant,
                  size: 50,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'FoodLink',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const Text(
                'Share Food • Spread Love',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 45),

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
                keyboardType: TextInputType.text,
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

              Align(
                alignment: Alignment.centerRight,

                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ForgotPasswordScreen(),
                      ),
                    );
                  },

                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton(
                  onPressed: isLoading ? null : login,

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
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const SignupScreen(),
                    ),
                  );
                },

                child: const Text(
                  "Don't have an account? Sign Up",
                ),
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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}