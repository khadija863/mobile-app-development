import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/user_service.dart';

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
import 'incoming_requests_screen.dart';
import 'available_collections_screen.dart';
import 'my_collections_screen.dart';

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

  final UserService _userService = UserService();

  late Future<bool> _adminCheckFuture;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color backgroundColor = Color(0xFFF5F8F5);

  @override
  void initState() {
    super.initState();
    _adminCheckFuture = _checkAdminAccess();
  }

  // Verify admin using Firebase Custom Claims.
  Future<bool> _checkAdminAccess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return false;

      final tokenResult = await user.getIdTokenResult(true);

      return tokenResult.claims?['admin'] == true;
    } catch (e) {
      debugPrint('Admin verification failed: $e');
      return false;
    }
  }

  void openScreen(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  void changeTab(int value) {
    if (!mounted) return;

    setState(() {
      index = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _userService.watchMyProfile(),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: backgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: primaryGreen,
              ),
            ),
          );
        }

        if (profileSnapshot.hasError ||
            !profileSnapshot.hasData ||
            profileSnapshot.data == null) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 45,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load your profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();

                        if (context.mounted) {
                          Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          );
                        }
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final profile = profileSnapshot.data!;
        final String role = profile.userType.toLowerCase();

        final String displayName = profile.name.trim().isEmpty
            ? widget.userName
            : profile.name.trim();

        return FutureBuilder<bool>(
          future: _adminCheckFuture,
          builder: (context, adminSnapshot) {
            final bool isAdmin = adminSnapshot.data == true;

            return _buildMainScreen(
              role: role,
              displayName: displayName,
              isAdmin: isAdmin,
            );
          },
        );
      },
    );
  }

  // =====================================================
  // ROLE-BASED NAVIGATION
  // =====================================================

  Widget _buildMainScreen({
    required String role,
    required String displayName,
    required bool isAdmin,
  }) {
    final bool isDonor = role == 'donor';
    final bool isReceiver = role == 'receiver';
    final bool isVolunteer = role == 'volunteer';

    final List<Widget> pages;
    final List<NavigationDestination> destinations;

    // ADMIN
    if (isAdmin) {
      pages = [
        _homeContent(
          role: 'admin',
          displayName: displayName,
          isAdmin: true,
        ),

        AdminDashboardScreen(
          onBack: () => changeTab(0),
        ),

        const ManageDonationsRequestsScreen(),

        ProfileScreen(
          userName: displayName,
          userEmail: widget.userEmail,
          onBack: () => changeTab(0),
        ),
      ];

      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.manage_accounts_outlined),
          selectedIcon: Icon(Icons.manage_accounts),
          label: 'Manage',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }

    // DONOR
    else if (isDonor) {
      pages = [
        _homeContent(
          role: role,
          displayName: displayName,
          isAdmin: false,
        ),

        AddFoodDonationScreen(
          onBack: () => changeTab(0),
        ),

        BrowseFoodScreen(
          onBack: () => changeTab(0),
        ),

        ProfileScreen(
          userName: displayName,
          userEmail: widget.userEmail,
          onBack: () => changeTab(0),
        ),
      ];

      destinations = const [
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
      ];
    }

    // RECEIVER
    else if (isReceiver) {
      pages = [
        _homeContent(
          role: role,
          displayName: displayName,
          isAdmin: false,
        ),

        BrowseFoodScreen(
          onBack: () => changeTab(0),
        ),

        MyRequestsScreen(
          onBack: () => changeTab(0),
        ),

        ProfileScreen(
          userName: displayName,
          userEmail: widget.userEmail,
          onBack: () => changeTab(0),
        ),
      ];

      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: 'Find Food',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: 'My Requests',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }

    // VOLUNTEER
    else if (isVolunteer) {
      pages = [
        _homeContent(
          role: role,
          displayName: displayName,
          isAdmin: false,
        ),

        AvailableCollectionsScreen(
          onBack: () => changeTab(0),
        ),

        MyCollectionsScreen(
          onBack: () => changeTab(0),
        ),

        ProfileScreen(
          userName: displayName,
          userEmail: widget.userEmail,
          onBack: () => changeTab(0),
        ),
      ];

      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.delivery_dining_outlined),
          selectedIcon: Icon(Icons.delivery_dining),
          label: 'Available Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: 'My Collections',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }

    // OTHER / PENDING ROLE
    else {
      pages = [
        _homeContent(
          role: role,
          displayName: displayName,
          isAdmin: false,
        ),

        ProfileScreen(
          userName: displayName,
          userEmail: widget.userEmail,
          onBack: () => changeTab(0),
        ),
      ];

      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }

    // Reset index if role changes.
    if (index >= pages.length) {
      index = 0;
    }

    // Android system Back button handling.
    return PopScope<Object?>(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && index != 0) {
          changeTab(0);
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
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
          labelBehavior:
              NavigationDestinationLabelBehavior.alwaysShow,
          destinations: destinations,
        ),
      ),
    );
  }

  // =====================================================
  // HOME CONTENT
  // =====================================================

  Widget _homeContent({
    required String role,
    required String displayName,
    required bool isAdmin,
  }) {
    final bool isDonor = role == 'donor';
    final bool isReceiver = role == 'receiver';
    final bool isVolunteer = role == 'volunteer';

    String bannerTitle;
    String bannerDescription;
    String bannerButton;
    IconData bannerIcon;
    String sectionHeading;

    if (isAdmin) {
      bannerTitle = 'Welcome, Admin!';
      bannerDescription =
          'Monitor FoodLink and manage platform activities.';
      bannerButton = 'Admin Dashboard';
      bannerIcon = Icons.admin_panel_settings;
      sectionHeading = 'Admin Actions';
    } else if (isDonor) {
      bannerTitle = 'Have extra food?';
      bannerDescription =
          'Share your extra food with someone in need.';
      bannerButton = 'Donate Now';
      bannerIcon = Icons.volunteer_activism;
      sectionHeading = 'Quick Actions';
    } else if (isVolunteer) {
      bannerTitle = 'Be a FoodLink Volunteer!';
      bannerDescription =
          'Help deliver food and make a difference in your community.';
      bannerButton = 'Find Delivery Tasks';
      bannerIcon = Icons.delivery_dining;
      sectionHeading = 'Volunteer Actions';
    } else {
      bannerTitle = 'Find Food, Share Hope!';
      bannerDescription =
          'Explore available food donations near you.';
      bannerButton = 'Browse Food';
      bannerIcon = Icons.restaurant;
      sectionHeading = 'Quick Actions';
    }

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
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${displayName.isEmpty ? 'there' : displayName} 👋',
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
                    if (!isAdmin)
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
        openScreen(const NotificationsScreen());
      },
    ),
  ),
                  ],
                ),

                const SizedBox(height: 25),

                // ROLE-BASED BANNER
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
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              bannerTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bannerDescription,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            if (!isAdmin) ...[
                              const SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: () => changeTab(1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primaryGreen,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  bannerButton,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        bannerIcon,
                        color: Colors.white,
                        size: 52,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                _sectionTitle(sectionHeading),

                const SizedBox(height: 15),

                // ROLE-BASED QUICK ACTIONS
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  childAspectRatio:
                      screenWidth < 360 ? 1.15 : 1.20,
                  children: [
                    // DONOR ACTIONS
                    if (isDonor) ...[
                      _actionCard(
                        icon: Icons.restaurant_menu,
                        title: 'Donate Food',
                        subtitle: 'Share extra food',
                        onTap: () => changeTab(1),
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
                        icon: Icons.inbox_outlined,
                        title: 'Incoming Requests',
                        subtitle: 'Manage food requests',
                        onTap: () {
                          openScreen(
                            const IncomingRequestsScreen(),
                          );
                        },
                      ),
                    ]

                    // RECEIVER ACTIONS
                    else if (isReceiver) ...[
                      _actionCard(
                        icon: Icons.search,
                        title: 'Find Food',
                        subtitle: 'Browse available food',
                        onTap: () => changeTab(1),
                      ),
                      _actionCard(
                        icon: Icons.assignment_outlined,
                        title: 'My Requests',
                        subtitle: 'Track your requests',
                        onTap: () => changeTab(2),
                      ),
                    ]

                    // VOLUNTEER ACTIONS
                    else if (isVolunteer) ...[
                      _actionCard(
                        icon: Icons.delivery_dining,
                        title: 'Available Tasks',
                        subtitle: 'Find delivery tasks',
                        onTap: () => changeTab(1),
                      ),
                      _actionCard(
                        icon: Icons.assignment_outlined,
                        title: 'My Collections',
                        subtitle: 'Manage your deliveries',
                        onTap: () => changeTab(2),
                      ),
                    ]

                    // ADMIN ACTIONS
                    else if (isAdmin) ...[
                      _actionCard(
                        icon: Icons.dashboard_outlined,
                        title: 'Dashboard',
                        subtitle: 'Platform overview',
                        onTap: () => changeTab(1),
                      ),
                      _actionCard(
                        icon: Icons.people_outline,
                        title: 'Manage Users',
                        subtitle: 'View platform users',
                        onTap: () {
                          openScreen(
                            const ManageUsersScreen(),
                          );
                        },
                      ),
                      _actionCard(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Manage Donations',
                        subtitle: 'Review donations and requests',
                        onTap: () {
                          openScreen(
                            const ManageDonationsRequestsScreen(),
                          );
                        },
                      ),
                    ]

                    // OTHER
                    else ...[
                      _actionCard(
                        icon: Icons.info_outline,
                        title: 'Complete Profile',
                        subtitle: 'Check your account',
                        onTap: () {
                          openScreen(
                            const EditProfileScreen(),
                          );
                        },
                      ),
                    ],

                    // COMMON ACTIONS
                    if (!isAdmin)
  _actionCard(
    icon: Icons.notifications_outlined,
    title: 'Notifications',
    subtitle: 'Check updates',
    onTap: () {
      openScreen(const NotificationsScreen());
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

                // ROLE-BASED INFORMATION SECTION
                _sectionTitle(
                  isVolunteer
                      ? 'Delivery Tasks'
                      : isAdmin
                          ? 'Platform Management'
                          : 'Available Food',
                ),

                const SizedBox(height: 15),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 25,
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
                        child: Icon(
                          isVolunteer
                              ? Icons.delivery_dining
                              : isAdmin
                                  ? Icons.admin_panel_settings
                                  : Icons.restaurant_outlined,
                          size: 42,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        isVolunteer
                            ? 'Help Deliver Food'
                            : isAdmin
                                ? 'Manage FoodLink'
                                : 'Explore Available Food',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        isVolunteer
                            ? 'Find an unclaimed delivery task and help deliver food to someone in need.'
                            : isAdmin
                                ? 'Review donations, requests and platform activities.'
                                : 'Visit the Find Food section to see currently available donations.',
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
                          if (isAdmin) {
                            changeTab(2);
                          } else {
                            changeTab(1);
                          }
                        },
                        icon: Icon(
                          isVolunteer
                              ? Icons.delivery_dining
                              : isAdmin
                                  ? Icons.manage_accounts
                                  : Icons.search,
                          size: 18,
                        ),
                        label: Text(
                          isVolunteer
                              ? 'Available Tasks'
                              : isAdmin
                                  ? 'Manage Platform'
                                  : 'Browse Food',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ADMIN PLATFORM OVERVIEW
                if (isAdmin) ...[
                  _sectionTitle('Platform Overview'),
                  const SizedBox(height: 8),
                  Text(
                    'A quick look at FoodLink activity.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 15),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 13,
                    childAspectRatio:
                        screenWidth < 360 ? 1.15 : 1.20,
                    children: [
                      _adminOverviewCard(
                        title: 'Total Users',
                        icon: Icons.people_outline,
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots()
                            .map((snapshot) => snapshot.size),
                      ),
                      _adminOverviewCard(
                        title: 'Total Donations',
                        icon: Icons.volunteer_activism_outlined,
                        stream: FirebaseFirestore.instance
                            .collection('donations')
                            .snapshots()
                            .map((snapshot) => snapshot.size),
                      ),
                      _adminOverviewCard(
                        title: 'Pending Requests',
                        icon: Icons.pending_actions_outlined,
                        stream: FirebaseFirestore.instance
                            .collection('requests')
                            .where(
                              'status',
                              isEqualTo: 'pending',
                            )
                            .snapshots()
                            .map((snapshot) => snapshot.size),
                      ),
                      _adminOverviewCard(
                        title: 'Completed Donations',
                        icon: Icons.check_circle_outline,
                        stream: FirebaseFirestore.instance
                            .collection('donations')
                            .where(
                              'status',
                              isEqualTo: 'collected',
                            )
                            .snapshots()
                            .map((snapshot) => snapshot.size),
                      ),
                    ],
                  ),
                ],

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

  // =====================================================
  // SECTION TITLE
  // =====================================================

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

  // =====================================================
  // QUICK ACTION CARD
  // =====================================================

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
            vertical: 10,
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
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 8),
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
              const SizedBox(height: 3),
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

  // =====================================================
  // LIVE ADMIN OVERVIEW CARD
  // =====================================================

  Widget _adminOverviewCard({
    required String title,
    required IconData icon,
    required Stream<int> stream,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryGreen,
              size: 24,
            ),
          ),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) {
              final String value = snapshot.hasError
                  ? '--'
                  : snapshot.hasData
                      ? snapshot.data.toString()
                      : '...';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263328),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}