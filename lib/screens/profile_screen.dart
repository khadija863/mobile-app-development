
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/notification_preferences_service.dart';

import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'my_donations_screen.dart';
import 'my_requests_screen.dart';
import 'incoming_requests_screen.dart';
import 'my_collections_screen.dart';

// =====================================================
// PROFILE SCREEN
// =====================================================

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback? onBack;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.onBack,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  late final Stream<UserModel?> _profileStream;

  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _profileStream = _userService.watchMyProfile();
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isLoggingOut = false;
      });
    }
  }

  // =====================================================
  // OPEN ANOTHER SCREEN
  // =====================================================

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  // =====================================================
  // PROFILE MENU ITEM
  // =====================================================

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

  // =====================================================
  // BUILD PROFILE
  // =====================================================

  Widget _buildProfile(UserModel? profile) {
    final name = profile?.name.isNotEmpty == true
        ? profile!.name
        : widget.userName;

    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : widget.userEmail;

    final phone = profile?.phone ?? '';
    final userType = profile?.userType ?? 'pending';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFE8F5E9),
            backgroundImage: profile?.photoUrl.isNotEmpty == true
                ? NetworkImage(profile!.photoUrl)
                : null,
            child: profile?.photoUrl.isNotEmpty == true
                ? null
                : const Icon(
                    Icons.person,
                    size: 60,
                    color: Color(0xFF2E7D32),
                  ),
          ),

          const SizedBox(height: 12),

          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            email,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          if (phone.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              phone,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              userType.toUpperCase(),
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // =================================================
          // DONOR MENU
          // =================================================

          if (userType == 'donor') ...[
            _profileItem(
              Icons.volunteer_activism,
              'My Donations',
              () => _openScreen(
                const MyDonationsScreen(),
              ),
            ),

            _profileItem(
              Icons.inbox_outlined,
              'Incoming Requests',
              () => _openScreen(
                const IncomingRequestsScreen(),
              ),
            ),
          ],

          // =================================================
          // RECEIVER MENU
          // =================================================

          if (userType == 'receiver')
            _profileItem(
              Icons.favorite_outline,
              'My Requests',
              () => _openScreen(
                MyRequestsScreen(
                  onBack: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),

          // =================================================
          // VOLUNTEER MENU
          // =================================================

          if (userType == 'volunteer')
            _profileItem(
              Icons.local_shipping_outlined,
              'My Collections',
              () => _openScreen(
                MyCollectionsScreen(
                  onBack: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),

          // =================================================
          // COMMON MENU
          // =================================================

          _profileItem(
            Icons.edit_outlined,
            'Edit Profile',
            () => _openScreen(
              const EditProfileScreen(),
            ),
          ),

          _profileItem(
            Icons.settings_outlined,
            'Settings',
            () => _openScreen(
              const SettingsScreen(),
            ),
          ),

          _profileItem(
            Icons.logout,
            'Logout',
            _isLoggingOut ? () {} : _logout,
          ),

          if (_isLoggingOut) ...[
            const SizedBox(height: 15),
            const CircularProgressIndicator(
              color: Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: const Text('Profile'),
      ),
      body: StreamBuilder<UserModel?>(
        stream: _profileStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load profile.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: _buildProfile(snapshot.data),
          );
        },
      ),
    );
  }
}

// =====================================================
// SETTINGS SCREEN
// =====================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationPreferencesService _preferencesService =
      NotificationPreferencesService();

  bool _pushEnabled = true;
  bool _updatesEnabled = true;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // =====================================================
  // LOAD NOTIFICATION PREFERENCES
  // =====================================================

  Future<void> _loadPreferences() async {
    try {
      final preferences =
          await _preferencesService.getPreferences();

      if (!mounted) return;

      setState(() {
        _pushEnabled =
            preferences['push_enabled'] ?? true;

        _updatesEnabled =
            preferences['updates_enabled'] ?? true;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load preferences: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =====================================================
  // SAVE PREFERENCES
  // =====================================================

  Future<void> _saveUpdatesPreference(bool value) async {
    if (_isSaving) return;

    final oldValue = _updatesEnabled;

    setState(() {
      _updatesEnabled = value;
      _isSaving = true;
    });

    try {
      await _preferencesService.savePreferences(
        pushEnabled: _pushEnabled,
        updatesEnabled: value,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notification preferences saved.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _updatesEnabled = oldValue;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save preferences: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // =====================================================
  // SECTION TITLE
  // =====================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
        top: 20,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF263328),
        ),
      ),
    );
  }

  // =====================================================
  // SETTINGS TILE
  // =====================================================

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F5E9),
          child: Icon(
            icon,
            color: const Color(0xFF2E7D32),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  // =====================================================
  // NOTIFICATION TILE
  // =====================================================

  Widget _notificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        secondary: CircleAvatar(
          backgroundColor: const Color(0xFFE8F5E9),
          child: Icon(
            icon,
            color: const Color(0xFF2E7D32),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        value: value,
        activeThumbColor: const Color(0xFF2E7D32),
        onChanged: _isSaving || _isLoading
            ? null
            : onChanged,
      ),
    );
  }

  // =====================================================
  // OPEN INFO SCREEN
  // =====================================================

  void _openInfoScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  // =====================================================
  // BUILD SETTINGS
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFF5F8F5),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Notifications'),

                  _notificationTile(
                    icon: Icons.volunteer_activism_outlined,
                    title: 'Donation & Request Updates',
                    subtitle:
                        'Receive in-app updates about donations, '
                        'requests and deliveries.',
                    value: _updatesEnabled,
                    onChanged: _saveUpdatesPreference,
                  ),

                  if (_isSaving)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Saving preferences...',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                  _sectionTitle('About & Support'),

                  _settingsTile(
                    icon: Icons.info_outline,
                    title: 'About FoodLink',
                    subtitle: 'Learn more about FoodLink.',
                    onTap: () {
                      _openInfoScreen(
                        const AboutFoodLinkScreen(),
                      );
                    },
                  ),

                  _settingsTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Find help using the application.',
                    onTap: () {
                      _openInfoScreen(
                        const HelpSupportScreen(),
                      );
                    },
                  ),

                  _settingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle:
                        'Learn how your information is handled.',
                    onTap: () {
                      _openInfoScreen(
                        const PrivacyPolicyScreen(),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      'FoodLink • Share Food, Spread Kindness',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// =====================================================
// ABOUT FOODLINK
// =====================================================

class AboutFoodLinkScreen extends StatelessWidget {
  const AboutFoodLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        title: const Text('About FoodLink'),
        backgroundColor: const Color(0xFFF5F8F5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(
                Icons.volunteer_activism,
                size: 50,
                color: Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'FoodLink',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Share Food, Spread Kindness',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            const Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'FoodLink is a food donation and sharing platform '
                  'that connects donors with people who need food. '
                  'It aims to make food sharing easier and encourage '
                  'kindness within communities.\n\n'
                  'Through FoodLink, donors can share available food, '
                  'receivers can request donations, and volunteers '
                  'can help with collection and delivery.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'FoodLink Project',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// HELP & SUPPORT
// =====================================================

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Widget _helpCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F5E9),
          child: Icon(
            icon,
            color: const Color(0xFF2E7D32),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(description),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: const Color(0xFFF5F8F5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Here are some basic guides for using FoodLink.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            _helpCard(
              icon: Icons.volunteer_activism,
              title: 'How to Donate Food?',
              description:
                  'Open Add Food Donation, enter the food details, '
                  'quantity, pickup address and availability date, '
                  'then submit your donation.',
            ),

            _helpCard(
              icon: Icons.search,
              title: 'How to Request Food?',
              description:
                  'Browse available food donations and select '
                  'a suitable donation to send a request.',
            ),

            _helpCard(
              icon: Icons.person_outline,
              title: 'How to Update My Profile?',
              description:
                  'Go to Profile and select Edit Profile to update '
                  'your name or phone number.',
            ),

            _helpCard(
              icon: Icons.notifications_outlined,
              title: 'Notification Settings',
              description:
                  'Open Settings to manage your notification '
                  'preferences.',
            ),

            const SizedBox(height: 10),

            const Text(
              'For further assistance, contact the FoodLink project '
              'team through its official communication channel.',
              style: TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// PRIVACY POLICY
// =====================================================

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget _policySection(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),

          const SizedBox(height: 7),

          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF555555),
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color(0xFFF5F8F5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FoodLink Privacy Policy',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'This page provides a summary of the information '
                  'used by the FoodLink application.',
                  style: TextStyle(
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 22),

                _policySection(
                  '1. Information We Collect',
                  'FoodLink stores account information such as name '
                  'and email address, along with profile information '
                  'provided by users. Donation and request details '
                  'may also be stored to operate the platform.',
                ),

                _policySection(
                  '2. How Information Is Used',
                  'Information is used to manage user accounts, '
                  'display food donations, process requests and '
                  'support coordination between donors, receivers '
                  'and volunteers.',
                ),

                _policySection(
                  '3. Data Storage',
                  'FoodLink uses Firebase services, including '
                  'Firebase Authentication and Cloud Firestore, '
                  'to support account and application data.',
                ),

                _policySection(
                  '4. User Responsibilities',
                  'Users should provide accurate information and '
                  'avoid sharing passwords or other sensitive '
                  'account details with anyone.',
                ),

                _policySection(
                  '5. Notification Preferences',
                  'Users can manage their notification preferences '
                  'from the Settings screen. These preferences are '
                  'stored in their FoodLink account.',
                ),

                _policySection(
                  '6. Policy Updates',
                  'This privacy information may be updated as '
                  'FoodLink develops. Users should review this '
                  'page for changes.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
