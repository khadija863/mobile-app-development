
import 'package:flutter/material.dart';

import '../models/donation_model.dart';
import '../services/donation_service.dart';
import '../services/request_service.dart';

class BrowseFoodScreen extends StatefulWidget {
  final VoidCallback onBack;

  const BrowseFoodScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<BrowseFoodScreen> createState() =>
      _BrowseFoodScreenState();
}

class _BrowseFoodScreenState extends State<BrowseFoodScreen> {
  final TextEditingController searchController =
      TextEditingController();

  final DonationService _donationService = DonationService();
  final RequestService _requestService = RequestService();

  late final Stream<List<DonationModel>> _donationsStream;

  final Set<String> _requestingDonationIds = {};

  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Cooked Food',
    'Rice & Grains',
    'Fruits & Vegetables',
    'Bakery Items',
    'Packaged Food',
    'Other',
  ];

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color backgroundColor = Color(0xFFF5F8F5);

  @override
  void initState() {
    super.initState();
    _donationsStream = _donationService.getAvailableDonations();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =====================================================
  // FILTER DONATIONS
  // =====================================================

  List<DonationModel> _filterDonations(
    List<DonationModel> donations,
  ) {
    final String searchText =
        searchController.text.trim().toLowerCase();

    final DateTime now = DateTime.now();

    return donations.where((donation) {
      if (!donation.expiryTime.isAfter(now)) {
        return false;
      }

      if (selectedCategory != 'All' &&
          donation.foodType != selectedCategory) {
        return false;
      }

      if (searchText.isNotEmpty) {
        final bool matchesSearch =
            donation.title.toLowerCase().contains(searchText) ||
            donation.description.toLowerCase().contains(searchText) ||
            donation.donorName.toLowerCase().contains(searchText) ||
            donation.pickupAddress.toLowerCase().contains(searchText);

        if (!matchesSearch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // =====================================================
  // FORMAT DATE
  // =====================================================

  String _formatDate(DateTime date) {
    final DateTime localDate = date.toLocal();

    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }

  // =====================================================
  // RESET FILTERS
  // =====================================================

  void _resetFilters() {
    searchController.clear();

    setState(() {
      selectedCategory = 'All';
    });
  }

  // =====================================================
  // REQUEST FOOD DIALOG
  // =====================================================

  Future<String?> _showRequestDialog(
    DonationModel donation,
  ) async {
    String messageText = '';

    final String? message = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Request Food'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Do you want to request "${donation.title}"?',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Message to Donor (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                maxLength: 200,
                onChanged: (value) {
                  messageText = value;
                },
                decoration: InputDecoration(
                  hintText: 'Write a message to the donor...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  messageText.trim(),
                );
              },
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );

    return message;
  }

  // =====================================================
  // SEND FOOD REQUEST
  // =====================================================

  Future<void> _sendFoodRequest(
    DonationModel donation,
  ) async {
    if (_requestingDonationIds.contains(donation.id)) {
      return;
    }

    final String? message = await _showRequestDialog(donation);

    if (message == null || !mounted) {
      return;
    }

    setState(() {
      _requestingDonationIds.add(donation.id);
    });

    try {
      await _requestService.createRequest(
        donationId: donation.id,
        message: message,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food request sent successfully!'),
          backgroundColor: primaryGreen,
        ),
      );
    } catch (e) {
      debugPrint('FOOD REQUEST ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not send request: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _requestingDonationIds.remove(donation.id);
        });
      }
    }
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
        title: const Text('Browse Food'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find Available Food',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Explore food donations available in your area.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            // SEARCH FIELD
            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search food...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.green,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 22),

            // CATEGORY TITLE
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // CATEGORY FILTERS
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected =
                      selectedCategory == category;

                  return ChoiceChip(
                    label: Text(category),
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
                        selectedCategory = category;
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // RESULTS HEADING
            const Text(
              'Available Donations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // FIRESTORE DONATION STREAM
            StreamBuilder<List<DonationModel>>(
              stream: _donationsStream,
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
                  debugPrint(
                    'BROWSE FOOD ERROR: ${snapshot.error}',
                  );

                  return _messageCard(
                    icon: Icons.error_outline,
                    title: 'Something Went Wrong',
                    message:
                        'Unable to load food donations. Please try again later.',
                    buttonText: 'Reset Filters',
                    onPressed: _resetFilters,
                  );
                }

                final List<DonationModel> allDonations =
                    snapshot.data ?? [];

                final List<DonationModel> filteredDonations =
                    _filterDonations(allDonations);

                if (filteredDonations.isEmpty) {
                  final bool noDonations =
                      allDonations.isEmpty;

                  return _messageCard(
                    icon: Icons.fastfood_outlined,
                    title: noDonations
                        ? 'No Food Donations Yet'
                        : 'No Matching Donations',
                    message: noDonations
                        ? 'There are no available food donations right now. Please check again later.'
                        : 'No donations match your search or selected category.',
                    buttonText: 'Reset Filters',
                    onPressed: _resetFilters,
                  );
                }

                return Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filteredDonations.length} donation(s) found',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ListView.separated(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: filteredDonations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 15),
                      itemBuilder: (context, index) {
                        final donation =
                            filteredDonations[index];

                        return _donationCard(donation);
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // DONATION CARD
  // =====================================================

  Widget _donationCard(DonationModel donation) {
    final bool isRequesting =
        _requestingDonationIds.contains(donation.id);

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
          // FOOD ICON AND CATEGORY
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_outlined,
                  size: 27,
                  color: primaryGreen,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      donation.foodType,
                      style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
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

          const SizedBox(height: 15),

          // DESCRIPTION
          Text(
            donation.description,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 15),

          const Divider(height: 1),

          const SizedBox(height: 13),

          // QUANTITY
          _detailRow(
            icon: Icons.inventory_2_outlined,
            label: 'Quantity',
            value: donation.quantity,
          ),

          const SizedBox(height: 10),

          // DONOR
          _detailRow(
            icon: Icons.person_outline,
            label: 'Donor',
            value: donation.donorName.isEmpty
                ? 'FoodLink User'
                : donation.donorName,
          ),

          const SizedBox(height: 10),

          // PICKUP ADDRESS
          _detailRow(
            icon: Icons.location_on_outlined,
            label: 'Pickup Address',
            value: donation.pickupAddress.isEmpty
                ? 'Address not provided'
                : donation.pickupAddress,
          ),

          // GPS LOCATION
          if (donation.pickupLocation != null) ...[
            const SizedBox(height: 12),
            _buildGpsLocation(donation),
          ],

          const SizedBox(height: 10),

          // EXPIRY DATE
          _detailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Available Until',
            value: _formatDate(donation.expiryTime),
          ),

          const SizedBox(height: 18),

          // REQUEST FOOD BUTTON
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isRequesting
                  ? null
                  : () => _sendFoodRequest(donation),
              icon: isRequesting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.volunteer_activism),
              label: Text(
                isRequesting
                    ? 'Sending Request...'
                    : 'Request Food',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    Colors.green.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // GPS LOCATION DISPLAY
  // =====================================================

  Widget _buildGpsLocation(DonationModel donation) {
    final location = donation.pickupLocation!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.my_location,
                color: primaryGreen,
                size: 19,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'GPS Location Available',
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 18,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Latitude: ${location.latitude.toStringAsFixed(6)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Longitude: ${location.longitude.toStringAsFixed(6)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DONATION DETAILS ROW
  // =====================================================

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.green,
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

  // =====================================================
  // EMPTY / ERROR MESSAGE CARD
  // =====================================================

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
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
            onPressed: onPressed,
            icon: const Icon(Icons.refresh),
            label: Text(buttonText),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
