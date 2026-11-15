
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/user_service.dart';
import 'home_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const RoleSelectionScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final UserService _userService = UserService();

  String? selectedRole;

  bool isLoading = false;
  String? errorMessage;

  // =====================================================
  // SAVE USER ROLE IN FIRESTORE
  // =====================================================

  Future<void> saveUserRole() async {
    if (selectedRole == null || isLoading) return;

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        errorMessage = 'Please login again to select your role.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Save role using UserService.
      // Only pending users can select a role.
      await _userService.selectRole(selectedRole!);

      debugPrint('ROLE SELECTION SUCCESS');
      debugPrint('USER UID: ${user.uid}');
      debugPrint('SELECTED ROLE: $selectedRole');

      if (!mounted) return;

      // Navigate to Home Screen.
      Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(
    builder: (context) => HomeScreen(
  userName: widget.userName,
  userEmail: widget.userEmail,
),
  ),
  (route) => false,
);
    } on FirebaseException catch (e) {
      debugPrint('FIRESTORE ROLE ERROR: ${e.code}');
      debugPrint('ERROR MESSAGE: ${e.message}');

      if (!mounted) return;

      setState(() {
        errorMessage =
            'Could not save your role. Please try again.';
      });
    } catch (e) {
      debugPrint('ROLE SELECTION ERROR: $e');

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
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
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              const SizedBox(height: 45),

              const Text(
                'Select Your Role',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Choose how you want to use FoodLink',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 35),

              // DONOR
              _roleCard(
                title: 'Donor',
                description: 'Donate extra food to people in need',
                icon: Icons.volunteer_activism,
                role: 'donor',
              ),

              const SizedBox(height: 18),

              // RECEIVER
              _roleCard(
                title: 'Receiver',
                description: 'Request and receive available food',
                icon: Icons.restaurant_outlined,
                role: 'receiver',
              ),

              const SizedBox(height: 18),

              // VOLUNTEER
              _roleCard(
                title: 'Volunteer',
                description: 'Help collect and deliver donated food',
                icon: Icons.people_alt_outlined,
                role: 'volunteer',
              ),

              const Spacer(),

              // ERROR MESSAGE
              if (errorMessage != null) ...[
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
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
              ],

              // CONTINUE BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: selectedRole == null || isLoading
                      ? null
                      : saveUserRole,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
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
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
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

  // =====================================================
  // ROLE CARD
  // =====================================================

  Widget _roleCard({
    required String title,
    required String description,
    required IconData icon,
    required String role,
  }) {
    final bool isSelected = selectedRole == role;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              setState(() {
                selectedRole = role;
                errorMessage = null;
              });
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2E7D32)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: const Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected
                  ? const Color(0xFF2E7D32)
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
