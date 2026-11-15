
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'login_screen.dart';
import 'role_selection_screen.dart';
import 'home_screen.dart';

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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;
  bool googleSignInInitialized = false;

  String? nameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? generalError;

  static const String _googleServerClientId =
      '1023348048522-2s3gc0lnepksd30oacfv1lkd2h8k6ed3.apps.googleusercontent.com';

  // =====================================================
  // VALIDATION
  // =====================================================

  bool _validateForm() {
    bool isValid = true;

    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text;
    final String confirmPassword =
        confirmPasswordController.text;

    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
      confirmPasswordError = null;
      generalError = null;

      if (name.isEmpty) {
        nameError = 'Please enter your full name';
        isValid = false;
      }

      if (email.isEmpty) {
        emailError = 'Please enter your email';
        isValid = false;
      } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
          .hasMatch(email)) {
        emailError = 'Please enter a valid email';
        isValid = false;
      }

      if (password.isEmpty) {
        passwordError = 'Please enter a password';
        isValid = false;
      } else if (password.length < 6) {
        passwordError = 'Password must be at least 6 characters';
        isValid = false;
      }

      if (confirmPassword.isEmpty) {
        confirmPasswordError =
            'Please confirm your password';
        isValid = false;
      } else if (password != confirmPassword) {
        confirmPasswordError = 'Passwords do not match';
        isValid = false;
      }
    });

    return isValid;
  }

  // =====================================================
  // CREATE ACCOUNT WITH EMAIL AND PASSWORD
  // =====================================================

  Future<void> createAccount() async {
    FocusScope.of(context).unfocus();

    if (!_validateForm()) return;

    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text;

    setState(() {
      isLoading = true;
      generalError = null;
    });

    try {
      // Step 1: Create Firebase Authentication account.
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('User account could not be created');
      }

      // Step 2: Save display name in Firebase Authentication.
      await user.updateDisplayName(name);

      // Step 3: Create user profile in Firestore.
      await _db.collection('users').doc(user.uid).set({
  'name': name,
  'email': email,
  'user_type': 'pending',
  'status': 'active',
  'phone': '',
  'photo_url': '',
  'notification_preferences': {
    'push_enabled': true,
    'updates_enabled': true,
  },
  'created_at': FieldValue.serverTimestamp(),
});

      debugPrint('SIGNUP SUCCESS');
      debugPrint('USER UID: ${user.uid}');
      debugPrint('FIRESTORE PROFILE CREATED');

      // Step 4: Sign out after registration.
      await _auth.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
        ),
      );

      // Step 5: Navigate to Login screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            name: name,
            email: email,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('AUTH ERROR: ${e.code}');
      debugPrint('ERROR MESSAGE: ${e.message}');

      if (!mounted) return;

      setState(() {
        if (e.code == 'email-already-in-use') {
          emailError =
              'An account already exists with this email';
        } else if (e.code == 'invalid-email') {
          emailError = 'Invalid email address';
        } else if (e.code == 'weak-password') {
          passwordError = 'Password is too weak';
        } else if (e.code == 'operation-not-allowed') {
          generalError =
              'Email/Password sign-in is not enabled';
        } else if (e.code == 'network-request-failed') {
          generalError =
              'Please check your internet connection';
        } else {
          generalError =
              'Account creation failed. Please try again.';
        }
      });
    } on FirebaseException catch (e) {
      debugPrint('FIRESTORE ERROR: ${e.code}');
      debugPrint('ERROR MESSAGE: ${e.message}');

      // Profile creation failed. Sign out so the user
      // can safely retry login and profile creation.
      await _signOutSafely();

      if (!mounted) return;

      setState(() {
        generalError =
            'Account may be created, but profile could not be saved. '
            'Please try logging in again.';
      });
    } catch (e) {
      debugPrint('SIGNUP ERROR: $e');

      await _signOutSafely();

      if (!mounted) return;

      setState(() {
        generalError =
            'Something went wrong. Please try again.';
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
  // GOOGLE SIGN UP
  // =====================================================

  Future<void> signUpWithGoogle() async {
    FocusScope.of(context).unfocus();

    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
      confirmPasswordError = null;
      generalError = null;
      isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // Initialize Google Sign-In.
      if (!googleSignInInitialized) {
        await googleSignIn.initialize(
          serverClientId: _googleServerClientId,
        );

        googleSignInInitialized = true;
      }

      // Clear previous Google account selection.
      await googleSignIn.signOut();

      // Show Google account selection.
      final GoogleSignInAccount googleUser =
          await googleSignIn.authenticate();

      // Get Google authentication.
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // Create Firebase credential.
      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase.
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Google account could not be created');
      }

      debugPrint('GOOGLE SIGNUP SUCCESS');
      debugPrint('USER UID: ${user.uid}');
      debugPrint('USER EMAIL: ${user.email}');

      // Check or create Firestore profile.
      await _handleGoogleUser(user);
    } on FirebaseAuthException catch (e) {
      debugPrint('GOOGLE AUTH ERROR: ${e.code}');
      debugPrint('ERROR MESSAGE: ${e.message}');

      if (!mounted) return;

      setState(() {
        if (e.code == 'account-exists-with-different-credential') {
          generalError =
              'An account already exists with this email using another sign-in method.';
        } else if (e.code == 'network-request-failed') {
          generalError =
              'Please check your internet connection';
        } else {
          generalError =
              'Google sign up failed. Please try again.';
        }
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
            'Could not sign up with Google. Please try again.';
      });
    } catch (e) {
      debugPrint('GOOGLE SIGNUP ERROR: $e');

      if (!mounted) return;

      setState(() {
        generalError =
            'Could not sign up with Google. Please try again.';
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
  // GOOGLE USER FIRESTORE PROFILE AND NAVIGATION
  // =====================================================

  Future<void> _handleGoogleUser(User user) async {
    try {
      final DocumentReference<Map<String, dynamic>> userDoc =
          _db.collection('users').doc(user.uid);

      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await userDoc.get();

      // Create profile for a new Google user.
      if (!snapshot.exists) {
  await userDoc.set({
    'name': user.displayName ?? 'User',
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

      final Map<String, dynamic>? userData = snapshot.data();

      if (userData == null) {
        throw Exception('User profile data is empty');
      }

      final String role =
          userData['user_type'] as String? ?? 'pending';

      final String status =
          userData['status'] as String? ?? 'active';

      final String userName =
          userData['name'] as String? ??
              user.displayName ??
              'User';

      final String userEmail =
          userData['email'] as String? ??
              user.email ??
              '';

      debugPrint('GOOGLE USER ROLE: $role');
      debugPrint('GOOGLE USER STATUS: $status');

      // Block inactive accounts.
      if (status != 'active') {
        await _signOutSafely();

        if (!mounted) return;

        setState(() {
          generalError =
              'Your account is blocked or inactive. Please contact Admin.';
        });

        return;
      }

      // New user: Go to Role Selection.
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
        await _signOutSafely();

        if (!mounted) return;

        setState(() {
          generalError =
              'Invalid account role. Please contact Admin.';
        });
      }
    } catch (e) {
      debugPrint('GOOGLE PROFILE ERROR: $e');

      await _signOutSafely();

      rethrow;
    }
  }

  // =====================================================
  // SAFE SIGN OUT
  // =====================================================

  Future<void> _signOutSafely() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('SIGN OUT ERROR: $e');
    }
  }

  // =====================================================
  // TEXT FIELD
  // =====================================================

  Widget _field(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
    String? errorText,
    ValueChanged<String>? onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF2E7D32),
        ),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  isVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: const Color(0xFF2E7D32),
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
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

              // FULL NAME
              _field(
                'Full Name',
                Icons.person_outline,
                nameController,
                errorText: nameError,
                onChanged: (value) {
                  if (nameError != null) {
                    setState(() {
                      nameError = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 15),

              // EMAIL
              _field(
                'Email',
                Icons.email_outlined,
                emailController,
                errorText: emailError,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  if (emailError != null) {
                    setState(() {
                      emailError = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 15),

              // PASSWORD
              _field(
                'Password',
                Icons.lock_outline,
                passwordController,
                isPassword: true,
                isVisible: showPassword,
                errorText: passwordError,
                onToggleVisibility: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
                onChanged: (value) {
                  setState(() {
                    passwordError = null;

                    if (confirmPasswordController.text.isNotEmpty) {
                      confirmPasswordError =
                          value == confirmPasswordController.text
                              ? null
                              : 'Passwords do not match';
                    }
                  });
                },
              ),

              const SizedBox(height: 15),

              // CONFIRM PASSWORD
              _field(
                'Confirm Password',
                Icons.lock_reset_outlined,
                confirmPasswordController,
                isPassword: true,
                isVisible: showConfirmPassword,
                errorText: confirmPasswordError,
                onToggleVisibility: () {
                  setState(() {
                    showConfirmPassword = !showConfirmPassword;
                  });
                },
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                      confirmPasswordError =
                          'Please confirm your password';
                    } else if (value != passwordController.text) {
                      confirmPasswordError =
                          'Passwords do not match';
                    } else {
                      confirmPasswordError = null;
                    }
                  });
                },
              ),

              const SizedBox(height: 25),

              // GENERAL ERROR
              if (generalError != null) ...[
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
                const SizedBox(height: 15),
              ],

              // CREATE ACCOUNT BUTTON
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

              // GOOGLE SIGN UP BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: isLoading ? null : signUpWithGoogle,
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

              // LOGIN LINK
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already registered? ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
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

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }
}
