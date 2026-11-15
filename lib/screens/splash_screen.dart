
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'welcome_screen.dart';
import 'role_selection_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _errorMessage;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Keep the splash screen visible briefly.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final User? user = _auth.currentUser;

      // No existing Firebase session.
      if (user == null) {
        _navigateTo(const WelcomeScreen());
        return;
      }

      // Refresh the user and authentication token.
      await user.reload();

      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        _navigateTo(const WelcomeScreen());
        return;
      }

      // Read the latest custom claims.
      final IdTokenResult tokenResult =
          await currentUser.getIdTokenResult(true);

      final bool isAdmin =
          tokenResult.claims?['admin'] == true;

      // Read the user's Firestore profile.
      final DocumentSnapshot<Map<String, dynamic>> profileSnapshot =
          await _db.collection('users').doc(currentUser.uid).get(
                const GetOptions(source: Source.server),
              );

      if (!profileSnapshot.exists || profileSnapshot.data() == null) {
        await _auth.signOut();

        if (!mounted) return;

        _navigateTo(const WelcomeScreen());
        return;
      }

      final Map<String, dynamic> profile = profileSnapshot.data()!;

      final String status =
          (profile['status'] ?? '').toString().toLowerCase();

      final String role =
          (profile['user_type'] ?? 'pending')
              .toString()
              .toLowerCase();

      final String name =
          (profile['name'] ?? currentUser.displayName ?? 'User')
              .toString();

      final String email =
          (profile['email'] ?? currentUser.email ?? '')
              .toString();

      // Blocked accounts cannot enter the application.
      if (status != 'active') {
        await _auth.signOut();

        if (!mounted) return;

        _showBlockedMessage();
        return;
      }

      // Admin access is determined only by Firebase Custom Claims.
      if (isAdmin) {
        _navigateTo(
          HomeScreen(
            userName: name,
            userEmail: email,
          ),
        );
        return;
      }

      // Normal users cannot select the Admin role.
      if (role == 'pending') {
        _navigateTo(
          RoleSelectionScreen(
            userName: name,
            userEmail: email,
          ),
        );
        return;
      }

      // Only supported user roles can enter the dashboard.
      const List<String> allowedRoles = [
        'donor',
        'receiver',
        'volunteer',
      ];

      if (allowedRoles.contains(role)) {
        _navigateTo(
          HomeScreen(
            userName: name,
            userEmail: email,
          ),
        );
        return;
      }

      // Invalid role: fail closed.
      await _auth.signOut();

      if (!mounted) return;

      _navigateTo(const WelcomeScreen());
    } on FirebaseException catch (e) {
      debugPrint('SPLASH FIREBASE ERROR: ${e.code}');
      debugPrint('SPLASH ERROR MESSAGE: ${e.message}');

      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _errorMessage =
            'Unable to verify your account. Please check your internet connection.';
      });
    } catch (e, stackTrace) {
      debugPrint('SPLASH ERROR: $e');
      debugPrint('SPLASH STACK TRACE: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _errorMessage =
            'Something went wrong while checking your account.';
      });
    }
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  Future<void> _retrySessionCheck() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    await _checkSession();
  }

  void _showBlockedMessage() {
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your account is blocked. Please contact the administrator.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      body: Center(
        child: _isChecking
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism,
                      size: 65,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'FoodLink',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share Food, Spread Love',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const CircularProgressIndicator(
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Checking your account...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 55,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Unable to Continue',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage ?? 'Please try again.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton.icon(
                      onPressed: _retrySessionCheck,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
