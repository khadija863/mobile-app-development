import 'package:flutter/material.dart';

import '../models/request_model.dart';
import '../models/donation_model.dart';
import '../services/request_service.dart';
import '../services/donation_service.dart';

class MyRequestsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MyRequestsScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<MyRequestsScreen> createState() =>
      _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final RequestService _requestService = RequestService();
  final DonationService _donationService = DonationService();

  late final Stream<List<RequestModel>> _requestsStream;

  final Map<String, Future<DonationModel?>> _donationCache = {};
  final Set<String> _cancellingIds = {};

  String selectedStatus = 'All';

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color backgroundColor = Color(0xFFF5F8F5);

  final List<String> statuses = [
    'All',
    'Pending',
    'Accepted',
    'Rejected',
    'Cancelled',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _requestsStream = _requestService.watchMyRequests();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';

    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    return '$day/$month/$year';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.black54;
    }
  }

  Future<DonationModel?> _getDonationDetails(String donationId) {
    return _donationCache.putIfAbsent(
      donationId,
      () => _donationService.getDonationById(donationId),
    );
  }

  Future<void> _cancelRequest(RequestModel request) async {
    if (_cancellingIds.contains(request.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Request?'),
          content: const Text(
            'Are you sure you want to cancel this food request?',
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

    setState(() {
      _cancellingIds.add(request.id);
    });

    try {
      await _requestService.cancelMyRequest(request.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request cancelled successfully.'),
          backgroundColor: primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not cancel request: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cancellingIds.remove(request.id);
        });
      }
    }
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
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

  Widget _buildDonationDetails(RequestModel request) {
    return FutureBuilder<DonationModel?>(
      future: _getDonationDetails(request.donationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  height: 15,
                  width: 15,
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
          return Column(
            children: [
              _buildInfoRow(
                Icons.fastfood_outlined,
                'Food',
                'Donation details unavailable',
              ),
              _buildInfoRow(
                Icons.person_outline,
                'Donor',
                'Not available',
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildInfoRow(
              Icons.fastfood_outlined,
              'Food',
              donation.title,
            ),
            _buildInfoRow(
              Icons.person_outline,
              'Donor',
              donation.donorName,
            ),
            _buildInfoRow(
              Icons.inventory_2_outlined,
              'Quantity',
              donation.quantity,
            ),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Pickup',
              donation.pickupAddress,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    final statusColor = _statusColor(request.status);

    final bool canCancel =
        request.status.toLowerCase() == 'pending';

    final bool isCancelling =
        _cancellingIds.contains(request.id);

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
          // REQUEST HEADER
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_outlined,
                  color: primaryGreen,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Food Request',
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
                  request.status.toUpperCase(),
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

          // DONATION DETAILS
          const Text(
            'Donation Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _buildDonationDetails(request),

          const SizedBox(height: 5),

          // REQUEST INFORMATION
          const Text(
            'Request Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _buildInfoRow(
            Icons.tag,
            'Request ID',
            request.id,
          ),

          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Request Date',
            _formatDate(request.requestTime),
          ),

          if (request.message.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            const Text(
              'Your Message',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 7),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                request.message,
                style: const TextStyle(
                  color: Colors.black54,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ),
          ],

          // CANCEL REQUEST
          if (canCancel) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton.icon(
                onPressed: isCancelling
                    ? null
                    : () => _cancelRequest(request),
                icon: isCancelling
                    ? const SizedBox(
                        height: 17,
                        width: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.cancel_outlined,
                        size: 18,
                      ),
                label: Text(
                  isCancelling
                      ? 'Cancelling...'
                      : 'Cancel Request',
                ),
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
            Icons.inbox_outlined,
            size: 65,
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
              foregroundColor: primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

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
        title: const Text('My Requests'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Food Requests',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Track the status of your food requests.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Request Status',
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
                    selectedColor: primaryGreen,
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
              'Your Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            StreamBuilder<List<RequestModel>>(
              stream: _requestsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(35),
                      child: CircularProgressIndicator(
                        color: primaryGreen,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildEmptyState(
                    title: 'Something Went Wrong',
                    message:
                        'Could not load your requests. Please check your connection and try again.',
                  );
                }

                final allRequests = snapshot.data ?? [];

                final filteredRequests = selectedStatus == 'All'
                    ? allRequests
                    : allRequests.where((request) {
                        return request.status.toLowerCase() ==
                            selectedStatus.toLowerCase();
                      }).toList();

                if (filteredRequests.isEmpty) {
                  return _buildEmptyState(
                    title: 'No Requests Found',
                    message: allRequests.isEmpty
                        ? 'You have not requested any food yet. Your requests will appear here.'
                        : 'There are no requests with "$selectedStatus" status.',
                  );
                }

                return Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filteredRequests.length} request(s) found',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...filteredRequests.map(_buildRequestCard),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}