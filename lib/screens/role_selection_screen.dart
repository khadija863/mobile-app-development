import 'package:flutter/material.dart';
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
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole;

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

              const SizedBox(height: 45),

              _roleCard(
                title: 'Donor',
                description: 'Donate extra food to people in need',
                icon: Icons.volunteer_activism,
                role: 'Donor',
              ),

              const SizedBox(height: 18),

              _roleCard(
                title: 'Receiver / Volunteer',
                description: 'Receive food or help with food collection',
                icon: Icons.people_alt_outlined,
                role: 'Receiver / Volunteer',
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: selectedRole == null
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(
                                userName: widget.userName,
                                userEmail: widget.userEmail,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
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

  Widget _roleCard({
    required String title,
    required String description,
    required IconData icon,
    required String role,
  }) {
    bool isSelected = selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
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