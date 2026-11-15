
import 'package:flutter/material.dart';

import '../models/request_model.dart';
import '../models/donation_model.dart';
import '../services/request_service.dart';
import '../services/donation_service.dart';

class IncomingRequestsScreen extends StatefulWidget {
  const IncomingRequestsScreen({super.key});

  @override
  State<IncomingRequestsScreen> createState() =>
      _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState
    extends State<IncomingRequestsScreen> {
  final RequestService _requestService = RequestService();
  final DonationService _donationService = DonationService();

  late final Stream<List<RequestModel>> _requestsStream;

  final Set<String> _processingIds = {};

  final Map<String, Future<DonationModel?>> _donationFutures = {};

  String selectedFilter = 'All';

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color backgroundColor = Color(0xFFF5F8F5);

  final List<String> filters = [
    'All',
    'Pending',
    'Accepted',
    'Rejected',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _requestsStream = _requestService.watchRequestsForMyDonations();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // FORMAT DATE
  String _formatDate(DateTime? date) {
    if (date == null) return 'Date unavailable';

    final localDate = date.toLocal();

    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }

  // FILTER REQUESTS
  List<RequestModel> _filterRequests(
    List<RequestModel> requests,
  ) {
    if (selectedFilter == 'All') {
      return requests;
    }

    return requests.where((request) {
      return request.status.toLowerCase() ==
          selectedFilter.toLowerCase();
    }).toList();
  }

  // GET DONATION DETAILS
  Future<DonationModel?> _getDonation(String donationId) {
    return _donationFutures.putIfAbsent(
      donationId,
      () => _donationService.getDonationById(donationId),
    );
  }

  // CONFIRM ACTION
  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  // ACCEPT / REJECT REQUEST
  Future<void> _handleRequest({
    required RequestModel request,
    required bool accept,
  }) async {
    if (_processingIds.contains(request.id)) return;

    final confirmed = await _confirmAction(
      title: accept ? 'Accept Request?' : 'Reject Request?',
      message: accept
          ? 'Are you sure you want to accept this food request?'
          : 'Are you sure you want to reject this food request?',
      confirmText: accept ? 'Accept' : 'Reject',
    );

    if (!confirmed || !mounted) return;

    if (_processingIds.contains(request.id)) return;

    setState(() {
      _processingIds.add(request.id);
    });

    try {
      if (accept) {
        await _requestService.acceptRequest(request.id);
      } else {
        await _requestService.rejectRequest(request.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Request accepted successfully.'
                : 'Request rejected successfully.',
          ),
          backgroundColor: primaryGreen,
        ),
      );
    } catch (e) {
      debugPrint('REQUEST ACTION ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(request.id);
        });
      }
    }
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Incoming Requests'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: _requestsStream,
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
            debugPrint(
              'INCOMING REQUESTS ERROR: ${snapshot.error}',
            );

            return _messageCard(
              icon: Icons.error_outline,
              title: 'Something Went Wrong',
              message:
                  'Unable to load incoming requests. Please try again later.',
            );
          }

          final requests = snapshot.data ?? [];
          final filteredRequests = _filterRequests(requests);

          if (requests.isEmpty) {
            return _messageCard(
              icon: Icons.inbox_outlined,
              title: 'No Requests Yet',
              message:
                  'When someone requests your food donation, the request will appear here.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Text(
                  '${requests.length} incoming request(s)',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(
                height: 45,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    final isSelected = selectedFilter == filter;

                    return ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: primaryGreen,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: filteredRequests.isEmpty
                    ? _messageCard(
                        icon: Icons.filter_list_off,
                        title: 'No Matching Requests',
                        message:
                            'There are no ${selectedFilter.toLowerCase()} requests.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredRequests.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _requestCard(
                            filteredRequests[index],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // REQUEST CARD
  Widget _requestCard(RequestModel request) {
    final bool isPending =
        request.status.toLowerCase() == 'pending';

    final bool isProcessing =
        _processingIds.contains(request.id);

    Color statusColor;

    switch (request.status.toLowerCase()) {
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      width: double.infinity,
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
          // REQUESTER INFORMATION
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: primaryGreen,
                  size: 25,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requesterName.isEmpty
                          ? 'FoodLink User'
                          : request.requesterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.requesterRole.isEmpty
                          ? 'User'
                          : request.requesterRole.toUpperCase(),
                      style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
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

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // DONATION DETAILS
          _buildDonationDetails(request.donationId),

          const SizedBox(height: 14),

          _detailRow(
            Icons.calendar_today_outlined,
            'Request Date',
            _formatDate(request.requestTime),
          ),

          // REQUEST MESSAGE
          if (request.message.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Message',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                request.message,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],

          // ACCEPT / REJECT BUTTONS
          if (isPending) ...[
            const SizedBox(height: 17),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () {
                            _handleRequest(
                              request: request,
                              accept: false,
                            );
                          },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () {
                            _handleRequest(
                              request: request,
                              accept: true,
                            );
                          },
                    icon: isProcessing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(
                      isProcessing ? 'Please wait' : 'Accept',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // LOAD AND DISPLAY DONATION DETAILS
  Widget _buildDonationDetails(String donationId) {
    return FutureBuilder<DonationModel?>(
      future: _getDonation(donationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryGreen,
                ),
              ),
            ),
          );
        }

        final donation = snapshot.data;

        if (snapshot.hasError || donation == null) {
          return _detailRow(
            Icons.inventory_2_outlined,
            'Donation ID',
            donationId,
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Requested Food',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),

              const SizedBox(height: 9),

              Text(
                donation.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 7),

              _detailRow(
                Icons.category_outlined,
                'Category',
                donation.foodType,
              ),

              const SizedBox(height: 8),

              _detailRow(
                Icons.inventory_2_outlined,
                'Quantity',
                donation.quantity,
              ),

              const SizedBox(height: 8),

              _detailRow(
                Icons.location_on_outlined,
                'Pickup',
                donation.pickupAddress.isEmpty
                    ? 'Address not provided'
                    : donation.pickupAddress,
              ),
            ],
          ),
        );
      },
    );
  }

  // DETAIL ROW
  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: primaryGreen,
        ),

        const SizedBox(width: 9),

        SizedBox(
          width: 85,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // EMPTY / ERROR MESSAGE
  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Container(
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
                style: TextStyle(
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
