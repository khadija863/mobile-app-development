
import 'package:flutter/material.dart';

class ManageDonationsRequestsScreen extends StatefulWidget {
  const ManageDonationsRequestsScreen({super.key});

  @override
  State<ManageDonationsRequestsScreen> createState() =>
      _ManageDonationsRequestsScreenState();
}

class _ManageDonationsRequestsScreenState
    extends State<ManageDonationsRequestsScreen> {
  String selectedTab = 'Donations';
  String selectedStatus = 'All';

  final List<String> statuses = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        title: const Text('Manage Donations & Requests'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Management',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review and manage donations and food requests.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 25),

            // Donations and Requests tabs
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: buildTabButton('Donations'),
                  ),
                  Expanded(
                    child: buildTabButton('Requests'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              'Filter by Status',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: statuses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final status = statuses[index];
                  final isSelected =
                      selectedStatus == status;

                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    selectedColor: Colors.green,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.black87,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        selectedStatus = status;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            Text(
              selectedTab == 'Donations'
                  ? 'All Donations'
                  : 'All Requests',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            // Empty state
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 35,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    selectedTab == 'Donations'
                        ? Icons.volunteer_activism_outlined
                        : Icons.assignment_outlined,
                    size: 65,
                    color: Colors.green.shade300,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    selectedTab == 'Donations'
                        ? 'No Donations Available'
                        : 'No Requests Available',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedTab == 'Donations'
                        ? 'Donation records will appear here after connecting the backend.'
                        : 'Food request records will appear here after connecting the backend.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedStatus = 'All';
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Filter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTabButton(String tab) {
    final isSelected = selectedTab == tab;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = tab;
          selectedStatus = 'All';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            tab,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
