
import 'package:flutter/material.dart';

import '../models/donation_model.dart';
import '../services/donation_service.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() =>
      _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  final DonationService _donationService = DonationService();

  String selectedStatus = 'All';

  final List<String> statuses = [
    'All',
    'Pending Approval',
    'Available',
    'Reserved',
    'Collected',
    'Rejected',
    'Cancelled',
    'Expired',
  ];

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending_approval':
        return Colors.orange;
      case 'available':
        return Colors.green;
      case 'reserved':
        return Colors.deepOrange;
      case 'collected':
        return Colors.blue;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.black54;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending_approval':
        return 'PENDING APPROVAL';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _filterStatus(String filter) {
    if (filter == 'Pending Approval') {
      return 'pending_approval';
    }

    return filter.toLowerCase();
  }

  String _statusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending_approval':
        return 'Your donation has been submitted. '
            'Please wait for admin approval.';
      case 'available':
        return 'Your donation is approved and visible to receivers.';
      case 'reserved':
        return 'A receiver has requested your donation and you have accepted.';
      case 'collected':
        return 'Your donated food has been successfully delivered.';
      case 'rejected':
        return 'Your donation was not approved by the admin.';
      case 'cancelled':
        return 'You cancelled this donation.';
      case 'expired':
        return 'This donation has expired.';
      default:
        return '';
    }
  }

  Future<void> _cancelDonation(DonationModel donation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Donation?'),
          content: Text(
            'Are you sure you want to cancel "${donation.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await _donationService.cancelDonation(donation.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation cancelled successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not cancel donation: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDonationCard(DonationModel donation) {
    final status = donation.status.toLowerCase();
    final statusColor = _statusColor(status);

    final canCancel =
        status == 'available' || status == 'pending_approval';

    final statusMessage = _statusMessage(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  donation.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            donation.description,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          _buildInfoRow(
            Icons.category_outlined,
            'Category',
            donation.foodType,
          ),
          _buildInfoRow(
            Icons.inventory_2_outlined,
            'Quantity',
            donation.quantity,
          ),
          _buildInfoRow(
            Icons.location_on_outlined,
            'Pickup Address',
            donation.pickupAddress,
          ),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Expiry Date',
            _formatDate(donation.expiryTime),
          ),

          if (statusMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    status == 'pending_approval'
                        ? Icons.hourglass_top
                        : status == 'rejected'
                            ? Icons.info_outline
                            : Icons.check_circle_outline,
                    color: statusColor,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      statusMessage,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (canCancel) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _cancelDonation(donation),
                icon: const Icon(
                  Icons.cancel_outlined,
                  size: 18,
                ),
                label: const Text('Cancel Donation'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.green,
          ),
          const SizedBox(width: 9),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
  }) {
    return Container(
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
            Icons.volunteer_activism_outlined,
            size: 65,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        title: const Text('My Donations'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Your Donations',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track your donated food and manage requests.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
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
                  final isSelected = selectedStatus == status;

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
                      if (selected) {
                        setState(() {
                          selectedStatus = status;
                        });
                      }
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Your Donation History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            StreamBuilder<List<DonationModel>>(
              stream: _donationService.getMyDonations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(35),
                      child: CircularProgressIndicator(
                        color: Colors.green,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildEmptyState(
                    title: 'Something Went Wrong',
                    message:
                        'Could not load your donations. '
                        'Please check your connection and permissions.\n'
                        '${snapshot.error}',
                  );
                }

                final allDonations = snapshot.data ?? [];

                final filteredDonations = selectedStatus == 'All'
                    ? allDonations
                    : allDonations.where((donation) {
                        return donation.status.toLowerCase() ==
                            _filterStatus(selectedStatus);
                      }).toList();

                if (filteredDonations.isEmpty) {
                  return _buildEmptyState(
                    title: 'No Donations Found',
                    message: allDonations.isEmpty
                        ? 'You have not made any food donations yet. '
                            'Your donation history will appear here.'
                        : 'There are no donations with '
                            '"$selectedStatus" status.',
                  );
                }

                return Column(
                  children: filteredDonations
                      .map(_buildDonationCard)
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
