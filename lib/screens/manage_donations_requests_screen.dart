
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

  Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.blue;
      case 'Rejected':
        return Colors.red;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.green.shade700;
    }
  }

  Widget buildTabButton(String tab, IconData icon) {
    final isSelected = selectedTab == tab;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            selectedTab = tab;
            selectedStatus = 'All';
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.green.shade700
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: isSelected
                    ? Colors.white
                    : Colors.grey.shade700,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  tab,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStatusFilter() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: statuses.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = selectedStatus == status;
          final color = getStatusColor(status);

          return ChoiceChip(
            label: Text(status),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: color,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? color
                  : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.grey.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (selected) {
              setState(() {
                selectedStatus = status;
              });
            },
          );
        },
      ),
    );
  }

  Widget buildEmptyState() {
    final isDonation = selectedTab == 'Donations';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDonation
                  ? Icons.volunteer_activism_outlined
                  : Icons.assignment_outlined,
              size: 48,
              color: Colors.green.shade700,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            selectedStatus == 'All'
                ? (isDonation
                    ? 'No Donations Available'
                    : 'No Requests Available')
                : 'No $selectedStatus ${isDonation ? 'Donations' : 'Requests'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Records will appear here after connecting the backend.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 22),

          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                selectedStatus = 'All';
              });
            },
            icon: const Icon(
              Icons.refresh,
              size: 18,
            ),
            label: const Text('Reset Filter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              side: BorderSide(
                color: Colors.green.shade700,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
        title: const Text(
          'Manage Donations & Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 22,
          ),

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

              Text(
                'Review and manage donations and food requests.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 25),

              // Donations and Requests Tabs

              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    buildTabButton(
                      'Donations',
                      Icons.volunteer_activism_outlined,
                    ),
                    const SizedBox(width: 5),
                    buildTabButton(
                      'Requests',
                      Icons.assignment_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Filter Section

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter by Status',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedStatus = 'All';
                      });
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              buildStatusFilter(),

              const SizedBox(height: 30),

              // Records Section

              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedTab == 'Donations'
                          ? 'All Donations'
                          : 'All Requests',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      selectedStatus,
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              buildEmptyState(),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
