
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'signup_screen.dart';
import 'role_selection_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

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

  final TextEditingController passwordController =
      TextEditingController();

  bool showPassword = false;
  bool isLoading = false;
  bool googleSignInInitialized = false;

  String? emailError;
  String? passwordError;
  String? generalError;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _googleServerClientId =
      '1023348048522-2s3gc0lnepksd30oacfv1lkd2h8k6ed3.apps.googleusercontent.com';

  @override
  void initState() {
    super.initState();

    emailController = TextEditingController(
      text: widget.email ?? '',
    );
  }

  // =====================================================
  // EMAIL VALIDATION
  // =====================================================

  bool _validateEmail() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        emailError = 'Please enter your email';
      });
      return false;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(email)) {
      setState(() {
        emailError = 'Please enter a valid email';
      });
      return false;
    }

    setState(() {
      emailError = null;
    });

    return true;
  }

  // =====================================================
  // PASSWORD VALIDATION
  // =====================================================

  bool _validatePassword() {
    if (passwordController.text.isEmpty) {
      setState(() {
        passwordError = 'Please enter your password';
      });
      return false;
    }

    setState(() {
      passwordError = null;
    });

    return true;
  }

  // =====================================================
  // EMAIL / PASSWORD LOGIN
  // =====================================================

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    setState(() {
      generalError = null;
    });

    final validEmail = _validateEmail();
    final validPassword = _validatePassword();

    if (!validEmail || !validPassword) return;

    setState(() {
      isLoading = true;
    });

    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('User not found');
      }

      await _handleUserNavigation(user);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        setState(() {
          passwordError = 'Invalid email or password';
        });
      } else if (e.code == 'invalid-email') {
        setState(() {
          emailError = 'Invalid email address';
        });
      } else if (e.code == 'user-disabled') {
        setState(() {
          generalError = 'This account has been disabled';
        });
      } else if (e.code == 'too-many-requests') {
        setState(() {
          generalError =
              'Too many attempts. Please try again later';
        });
      } else {
        setState(() {
          generalError = 'Login failed. Please try again';
        });
      }
    } on FirebaseException catch (e) {
      debugPrint('FIRESTORE ERROR: ${e.code}');
      debugPrint('ERROR MESSAGE: ${e.message}');

      if (!mounted) return;

      setState(() {
        generalError =
            'Could not load your profile. Please try again.';
      });
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');

      if (!mounted) return;

      setState(() {
        generalError = 'Something went wrong. Please try again';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =====================================================
  // GOOGLE SIGN IN
  // =====================================================

  Future<void> signInWithGoogle() async {
    FocusScope.of(context).unfocus();

    setState(() {
      emailError = null;
      passwordError = null;
      generalError = null;
      isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      if (!googleSignInInitialized) {
        await googleSignIn.initialize(
          serverClientId: _googleServerClientId,
        );

        googleSignInInitialized = true;
      }

      await googleSignIn.signOut();

      final GoogleSignInAccount googleUser =
          await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Google login failed');
      }

      await _handleUserNavigation(user);
    } on FirebaseAuthException catch (e) {
      debugPrint('GOOGLE AUTH ERROR: ${e.code}');
      debugPrint('ERROR MESSAGE: ${e.message}');

      if (!mounted) return;

      setState(() {
        generalError =
            'Google sign in failed. Please try again.';
      });
    } on GoogleSignInException catch (e) {
      debugPrint('GOOGLE SIGN IN ERROR: ${e.code}');
      debugPrint('ERROR MESSAGE: ${e.description}');

      if (!mounted) return;

      if (e.code == GoogleSignInExceptionCode.canceled) {
        return;
      }

      setState(() {
        generalError =
            'Could not sign in with Google. Please try again.';
      });
    } catch (e) {
      debugPrint('GOOGLE LOGIN ERROR: $e');

      if (!mounted) return;

      setState(() {
        generalError =
            'Could not sign in with Google. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =====================================================
  // FIRESTORE PROFILE CHECK AND NAVIGATION
  // =====================================================

  Future<void> _handleUserNavigation(User user) async {
    final userDoc = _db.collection('users').doc(user.uid);

    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await userDoc.get();

      // Create profile if it does not exist.
      if (!snapshot.exists) {
  await userDoc.set({
    'name': user.displayName ?? widget.name ?? 'User',
    'email': user.email ?? '',
    'user_type': 'pending',
    'status': 'active',
    'phone': '',
    'photo_url': user.photoURL ?? '',
    'notification_preferences': {
      'push_enabled': true,
      'updates_enabled': true,
    },
    'created_at': FieldValue.serverTimestamp(),
  });

  snapshot = await userDoc.get();
}

      if (!mounted) return;

      final userData = snapshot.data();

      if (userData == null) {
        throw Exception('User profile data is empty');
      }

      final String role = userData['user_type'] is String
    ? userData['user_type'] as String
    : 'pending';

final String status = userData['status'] is String
    ? userData['status'] as String
    : 'active';

      final String userName =
          userData['name'] as String? ??
              user.displayName ??
              'User';

      final String userEmail =
          userData['email'] as String? ??
              user.email ??
              '';

      debugPrint('USER ROLE: $role');
      debugPrint('USER STATUS: $status');

      // Block inactive accounts.
      if (status != 'active') {
        await _auth.signOut();

        if (!mounted) return;

        setState(() {
          generalError =
              'Your account is blocked or inactive. Please contact Admin.';
        });

        return;
      }

      // New user: Select a role.
      if (role == 'pending') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RoleSelectionScreen(
              userName: userName,
              userEmail: userEmail,
            ),
          ),
        );
      }

      // Existing user: Go to Home.
      else if ([
        'donor',
        'receiver',
        'volunteer',
      ].contains(role)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userName: userName,
              userEmail: userEmail,
            ),
          ),
        );
      }

      // Invalid role.
      else {
        await _auth.signOut();

        if (!mounted) return;

        setState(() {
          generalError =
              'Invalid account role. Please contact Admin.';
        });
      }
    } catch (e) {
      // Do not keep a partially authenticated session
      // when the profile cannot be verified.
      await _auth.signOut();

      rethrow;
    }
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

              // EMAIL FIELD
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  if (emailError != null) {
                    setState(() {
                      emailError = null;
                    });
                  }
                },
                decoration: _inputDecoration(
                  hint: 'Email',
                  icon: Icons.email_outlined,
                  error: emailError,
                ),
              ),

              const SizedBox(height: 15),

              // PASSWORD FIELD
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  if (!isLoading) login();
                },
                onChanged: (value) {
                  if (passwordError != null) {
                    setState(() {
                      passwordError = null;
                    });
                  }
                },
                decoration: _inputDecoration(
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  error: passwordError,
                ).copyWith(
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
                ),
              ),

              // FORGOT PASSWORD
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
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

              // GENERAL ERROR
              if (generalError != null) ...[
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          generalError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // LOGIN BUTTON
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

              const SizedBox(height: 22),

              // OR DIVIDER
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: Colors.grey),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // GOOGLE SIGN IN BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: isLoading ? null : signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: const BorderSide(
                      color: Color(0xFFE0E0E0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'G',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // SIGN UP
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
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
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // INPUT DECORATION
  // =====================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? error,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: error,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF2E7D32),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 17,
        horizontal: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFE0E0E0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF2E7D32),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
