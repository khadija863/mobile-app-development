
import 'package:flutter/material.dart';

import '../models/collection_model.dart';
import '../models/donation_model.dart';
import '../services/collection_service.dart';
import '../services/donation_service.dart';

class MyCollectionsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MyCollectionsScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<MyCollectionsScreen> createState() =>
      _MyCollectionsScreenState();
}

class _MyCollectionsScreenState extends State<MyCollectionsScreen> {
  final CollectionService _collectionService = CollectionService();
  final DonationService _donationService = DonationService();

  late final Stream<List<CollectionModel>> _collectionsStream;

  final Map<String, Future<DonationModel?>> _donationCache = {};
  final Set<String> _processingIds = {};

  String selectedStatus = 'All';

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color backgroundColor = Color(0xFFF5F8F5);

  final List<String> statuses = [
    'All',
    'Assigned',
    'Picked Up',
    'Delivered',
  ];

  @override
  void initState() {
    super.initState();
    _collectionsStream = _collectionService.watchMyCollections();
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.orange;
      case 'picked_up':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'picked_up':
        return 'Picked Up';
      case 'assigned':
        return 'Assigned';
      case 'delivered':
        return 'Delivered';
      default:
        return status;
    }
  }

  // =====================================================
  // CONFIRM PICKUP / DELIVERY ACTION
  // =====================================================

  Future<void> _confirmAction({
    required CollectionModel collection,
    required bool isDelivery,
  }) async {
    if (_processingIds.contains(collection.id)) return;

    final String action =
        isDelivery ? 'Deliver Food' : 'Mark as Picked Up';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$action?'),
          content: Text(
            isDelivery
                ? 'Confirm that the food has been successfully delivered to the receiver.'
                : 'Confirm that you have collected the food from the donor.',
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
              child: Text(action),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _processingIds.add(collection.id);
    });

    try {
      if (isDelivery) {
        await _collectionService.markDelivered(collection.id);
      } else {
        await _collectionService.markPickedUp(collection.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDelivery
                ? 'Food delivered successfully!'
                : 'Food marked as picked up!',
          ),
          backgroundColor: primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(collection.id);
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
            color: primaryGreen,
            size: 18,
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
            padding: EdgeInsets.symmetric(vertical: 10),
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

        final donation = snapshot.data;

        if (snapshot.hasError || donation == null) {
          return const Text(
            'Donation details are unavailable.',
            style: TextStyle(
              color: Colors.red,
              fontSize: 13,
            ),
          );
        }

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
              label: 'Pickup',
              value: donation.pickupAddress,
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
    final String status = collection.status.toLowerCase();

    final bool isProcessing =
        _processingIds.contains(collection.id);

    final bool canPickup = status == 'assigned';
    final bool canDeliver = status == 'picked_up';

    final Color statusColor = _statusColor(status);

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
                  'My Delivery Task',
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
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(status).toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 14),

          const Text(
            'Donation Information',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _buildDonationDetails(collection),

          const SizedBox(height: 8),

          const Text(
            'Delivery Information',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _detailRow(
            icon: Icons.tag,
            label: 'Collection ID',
            value: collection.id,
          ),

          _detailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Created',
            value: _formatDate(collection.createdAt),
          ),

          if (collection.pickupTime != null)
            _detailRow(
              icon: Icons.inventory_outlined,
              label: 'Picked Up',
              value: _formatDate(collection.pickupTime),
            ),

          if (collection.deliveryTime != null)
            _detailRow(
              icon: Icons.check_circle_outline,
              label: 'Delivered',
              value: _formatDate(collection.deliveryTime),
            ),

          if (canPickup || canDeliver) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 47,
              child: ElevatedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () => _confirmAction(
                          collection: collection,
                          isDelivery: canDeliver,
                        ),
                icon: isProcessing
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        canPickup
                            ? Icons.inventory_2_outlined
                            : Icons.check_circle_outline,
                      ),
                label: Text(
                  isProcessing
                      ? 'Please wait...'
                      : canPickup
                          ? 'Mark as Picked Up'
                          : 'Mark as Delivered',
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
          ] else if (status == 'delivered') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: primaryGreen,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Delivery completed successfully.',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _buildEmptyState() {
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
            Icons.inbox_outlined,
            size: 60,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 15),
          const Text(
            'No Collections Found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You do not have any ${selectedStatus == 'All' ? '' : selectedStatus.toLowerCase()} delivery tasks yet.',
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
        title: const Text('My Collections'),
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
                child: Text(
                  'Unable to load your collections.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final allCollections = snapshot.data ?? [];

          final filteredCollections = selectedStatus == 'All'
              ? allCollections
              : allCollections.where((collection) {
                  return collection.status.toLowerCase() ==
                      selectedStatus.toLowerCase().replaceAll(' ', '_');
                }).toList();

          if (allCollections.isEmpty ||
              filteredCollections.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Track Your Deliveries',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 20),
                _buildEmptyState(),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'My Delivery Tasks',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Manage your claimed food delivery tasks.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: statuses.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final status = statuses[index];
                    final selected = selectedStatus == status;

                    return ChoiceChip(
                      label: Text(status),
                      selected: selected,
                      selectedColor: primaryGreen,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onSelected: (value) {
                        if (value) {
                          setState(() {
                            selectedStatus = status;
                          });
                        }
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              Text(
                '${filteredCollections.length} task(s) found',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 13),

              ...filteredCollections.map(_buildTaskCard),
            ],
          );
        },
      ),
    );
  }
}
