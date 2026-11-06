import 'package:flutter/material.dart';
import 'profile_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: index == 3
          ? ProfileScreen(
              userName: widget.userName,
              userEmail: widget.userEmail,
            )
          : _homeContent(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
        },
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
            icon: Icon(Icons.search),
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

  Widget _homeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${widget.userName} 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Welcome to FoodLink',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                CircleAvatar(
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No new notifications',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Have extra food?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Donate your extra food to someone in need.',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.volunteer_activism,
                    size: 65,
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    Icons.restaurant_menu,
                    'Donate Food',
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: _actionCard(
                    Icons.search,
                    'Find Food',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Food',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                TextButton(
                  onPressed: () {},
                  child: const Text('See All'),
                ),
              ],
            ),

            const SizedBox(height: 10),

            _foodCard(
              'Chicken Biryani',
              'Bogura',
              '10 Portions',
              'Today',
              Icons.rice_bowl,
            ),

            _foodCard(
              'Vegetable Meal',
              'Bogura',
              '5 Portions',
              'Tomorrow',
              Icons.lunch_dining,
            ),

            _foodCard(
              'Homemade Khichuri',
              'Bogura',
              '8 Portions',
              'Tomorrow',
              Icons.restaurant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(
    IconData icon,
    String title,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 38,
            color: const Color(0xFF2E7D32),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _foodCard(
    String name,
    String location,
    String quantity,
    String expiry,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2E7D32),
              size: 35,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                Text(
                  '📍 $location',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                Text(
                  quantity,
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),

          Text(
            expiry,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}