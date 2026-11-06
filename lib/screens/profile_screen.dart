import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userName;
  final String userEmail;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(
                Icons.person,
                size: 60,
                color: Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              userEmail,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            _profileItem(
              Icons.volunteer_activism,
              'My Donations',
              () {},
            ),

            _profileItem(
              Icons.favorite_outline,
              'My Requests',
              () {},
            ),

            _profileItem(
              Icons.edit_outlined,
              'Edit Profile',
              () {},
            ),

            _profileItem(
              Icons.settings_outlined,
              'Settings',
              () {},
            ),

            _profileItem(
              Icons.logout,
              'Logout',
              () {
                logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileItem(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8F5E9),
        child: Icon(
          icon,
          color: const Color(0xFF2E7D32),
        ),
      ),

      title: Text(title),

      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
      ),

      onTap: onTap,
    );
  }
}