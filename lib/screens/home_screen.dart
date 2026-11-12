
import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'add_food_donation_screen.dart';
import 'browse_food_screen.dart';
import 'my_donations_screen.dart';
import 'my_requests_screen.dart';
import 'notifications_screen.dart';
import 'edit_profile_screen.dart';
import 'admin_dashboard_screen.dart';
import 'manage_users_screen.dart';
import 'manage_donations_requests_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color backgroundColor = Color(0xFFF5F8F5);

  // Navigate to another screen
  void openScreen(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  // Change bottom navigation tab
  void changeTab(int value) {
    setState(() {
      index = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _homeContent(),
      const AddFoodDonationScreen(),
      const BrowseFoodScreen(),
      ProfileScreen(
        userName: widget.userName,
        userEmail: widget.userEmail,
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,

      // Preserve the state of each bottom navigation page.
      body: IndexedStack(
        index: index,
        children: pages,
      ),

      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: index,
        onDestinationSelected: changeTab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE1F2E3),
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism),
            label: 'Donate',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Find Food',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // HOME CONTENT
  Widget _homeContent() {
    final String displayName =
        widget.userName.trim().isEmpty
            ? 'there'
            : widget.userName.trim();

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double screenWidth = constraints.maxWidth;

          final double horizontalPadding =
              screenWidth < 360 ? 15 : 20;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // HEADER
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $displayName 👋',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263328),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Welcome to FoodLink',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: primaryGreen,
                          size: 26,
                        ),
                        tooltip: 'Notifications',
                        onPressed: () {
                          openScreen(
                            const NotificationsScreen(),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // DONATION BANNER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2E7D32),
                        Color(0xFF43A047),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.20),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Have extra food?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              'Share your extra food with someone in need.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 15),

                            ElevatedButton(
                              onPressed: () {
                                changeTab(1);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryGreen,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Donate Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      const Icon(
                        Icons.volunteer_activism,
                        color: Colors.white,
                        size: 52,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // QUICK ACTIONS TITLE
                _sectionTitle('Quick Actions'),

                const SizedBox(height: 15),

                // QUICK ACTION GRID
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  childAspectRatio:
                      screenWidth < 360 ? 1.35 : 1.45,

                  children: [
                    _actionCard(
                      icon: Icons.restaurant_menu,
                      title: 'Donate Food',
                      subtitle: 'Share extra food',
                      onTap: () {
                        changeTab(1);
                      },
                    ),

                    _actionCard(
                      icon: Icons.search,
                      title: 'Find Food',
                      subtitle: 'Browse available food',
                      onTap: () {
                        changeTab(2);
                      },
                    ),

                    _actionCard(
                      icon: Icons.volunteer_activism,
                      title: 'My Donations',
                      subtitle: 'View your donations',
                      onTap: () {
                        openScreen(
                          const MyDonationsScreen(),
                        );
                      },
                    ),

                    _actionCard(
                      icon: Icons.assignment_outlined,
                      title: 'My Requests',
                      subtitle: 'Track your requests',
                      onTap: () {
                        openScreen(
                          const MyRequestsScreen(),
                        );
                      },
                    ),

                    _actionCard(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Check updates',
                      onTap: () {
                        openScreen(
                          const NotificationsScreen(),
                        );
                      },
                    ),

                    _actionCard(
                      icon: Icons.edit_outlined,
                      title: 'Edit Profile',
                      subtitle: 'Update your profile',
                      onTap: () {
                        openScreen(
                          const EditProfileScreen(),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // AVAILABLE FOOD
                _sectionTitle('Available Food'),

                const SizedBox(height: 15),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.035),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(17),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.restaurant_outlined,
                          size: 42,
                          color: primaryGreen,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'No Food Donations Yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 9),

                      Text(
                        'Food donations will appear here when available.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextButton.icon(
                        onPressed: () {
                          changeTab(2);
                        },
                        icon: const Icon(
                          Icons.search,
                          size: 18,
                        ),
                        label: const Text('Browse Food'),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ADMIN PANEL PREVIEW
                Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: primaryGreen,
                      size: 25,
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: _sectionTitle('Admin Panel'),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'UI Preview',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                Text(
                  'Frontend preview only. Real admin access must be verified using backend role permissions.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),

                _adminAction(
                  icon: Icons.dashboard_outlined,
                  title: 'Admin Dashboard',
                  subtitle: 'View platform overview',
                  onTap: () {
                    openScreen(
                      const AdminDashboardScreen(),
                    );
                  },
                ),

                _adminAction(
                  icon: Icons.people_outline,
                  title: 'Manage Users',
                  subtitle: 'View and manage users',
                  onTap: () {
                    openScreen(
                      const ManageUsersScreen(),
                    );
                  },
                ),

                _adminAction(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Manage Donations & Requests',
                  subtitle: 'Review platform activities',
                  onTap: () {
                    openScreen(
                      const ManageDonationsRequestsScreen(),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // FOOTER
                Center(
                  child: Text(
                    'FoodLink • Share Food, Spread Kindness',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  // SECTION TITLE
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF263328),
      ),
    );
  }

  // QUICK ACTION CARD
  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),

        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  size: 27,
                  color: primaryGreen,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263328),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ADMIN ACTION CARD
  Widget _adminAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),

        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),

          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),

            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: primaryGreen,
                    size: 25,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263328),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
