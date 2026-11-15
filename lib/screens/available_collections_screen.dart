
import 'package:flutter/material.dart';

import '../models/collection_model.dart';
import '../models/donation_model.dart';
import '../services/collection_service.dart';
import '../services/donation_service.dart';

class AvailableCollectionsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AvailableCollectionsScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<AvailableCollectionsScreen> createState() =>
      _AvailableCollectionsScreenState();
}

class _AvailableCollectionsScreenState
    extends State<AvailableCollectionsScreen> {
  final CollectionService _collectionService = CollectionService();
  final DonationService _donationService = DonationService();

  late final Stream<List<CollectionModel>> _collectionsStream;

  final Map<String, Future<DonationModel?>> _donationCache = {};
  final Set<String> _claimingIds = {};

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color backgroundColor = Color(0xFFF5F8F5);

  @override
  void initState() {
    super.initState();
    _collectionsStream =
        _collectionService.watchAvailableCollections();
  }

  Future<DonationModel?> _getDonation(String donationId) {
    return _donationCache.putIfAbsent(
      donationId,
      () => _donationService.getDonationById(donationId),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  // =====================================================
  // CLAIM DELIVERY TASK
  // =====================================================

  Future<void> _claimTask(CollectionModel collection) async {
    if (_claimingIds.contains(collection.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Claim Delivery Task?'),
          content: const Text(
            'Do you want to take responsibility for delivering this food?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Claim Task'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _claimingIds.add(collection.id);
    });

    try {
      await _collectionService.claimCollection(collection.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Delivery task claimed successfully!',
          ),
          backgroundColor: primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not claim task: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _claimingIds.remove(collection.id);
        });
      }
    }
  }

  // =====================================================
  // DETAIL ROW
  // =====================================================

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: primaryGreen,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 105,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DONATION DETAILS
  // =====================================================

  Widget _buildDonationDetails(CollectionModel collection) {
    return FutureBuilder<DonationModel?>(
      future: _getDonation(collection.donationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryGreen,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Loading donation details...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Text(
            'Donation details are currently unavailable.',
            style: TextStyle(
              color: Colors.red,
              fontSize: 13,
            ),
          );
        }

        final donation = snapshot.data!;

        return Column(
          children: [
            _detailRow(
              icon: Icons.fastfood_outlined,
              label: 'Food',
              value: donation.title,
            ),
            _detailRow(
              icon: Icons.inventory_2_outlined,
              label: 'Quantity',
              value: donation.quantity,
            ),
            _detailRow(
              icon: Icons.person_outline,
              label: 'Donor',
              value: donation.donorName,
            ),
            _detailRow(
              icon: Icons.location_on_outlined,
              label: 'Pickup Address',
              value: donation.pickupAddress,
            ),
            _detailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Expiry Date',
              value: _formatDate(donation.expiryTime),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // TASK CARD
  // =====================================================

  Widget _buildTaskCard(CollectionModel collection) {
    final bool isClaiming =
        _claimingIds.contains(collection.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  color: primaryGreen,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Delivery Task',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Available',
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 15),

          const Text(
            'Donation Information',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 13),

          _buildDonationDetails(collection),

          const SizedBox(height: 5),

          _detailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Created Date',
            value: _formatDate(collection.createdAt),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 47,
            child: ElevatedButton.icon(
              onPressed: isClaiming
                  ? null
                  : () => _claimTask(collection),
              icon: isClaiming
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.assignment_turned_in_outlined,
                    ),
              label: Text(
                isClaiming ? 'Claiming...' : 'Claim Delivery Task',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.green.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // EMPTY / ERROR MESSAGE
  // =====================================================

  Widget _buildMessage({
    required IconData icon,
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
            icon,
            size: 60,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: widget.onBack,
        ),
        title: const Text('Available Tasks'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<CollectionModel>>(
        stream: _collectionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryGreen,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildMessage(
                  icon: Icons.error_outline,
                  title: 'Unable to Load Tasks',
                  message:
                      'Please check your connection or try again later.',
                ),
              ),
            );
          }

          final collections = snapshot.data ?? [];

          if (collections.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildMessage(
                  icon: Icons.inbox_outlined,
                  title: 'No Available Tasks',
                  message:
                      'There are no unclaimed delivery tasks right now. Please check again later.',
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'Available Delivery Tasks',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Choose a task and help deliver food to someone in need.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${collections.length} task(s) available',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 13),
              ...collections.map(_buildTaskCard),
            ],
          );
        },
      ),
    );
  }
}
