
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/donation_model.dart';
import '../models/request_model.dart';
import '../services/donation_service.dart';

class ManageDonationsRequestsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ManageDonationsRequestsScreen({
    super.key,
    this.onBack,
  });

  @override
  State<ManageDonationsRequestsScreen> createState() =>
      _ManageDonationsRequestsScreenState();
}

class _ManageDonationsRequestsScreenState
    extends State<ManageDonationsRequestsScreen> {
  String selectedTab = 'Donations';
  String selectedStatus = 'All';

  bool _isCheckingAdmin = true;
  bool _isAdmin = false;
  String? _error;

  final DonationService _donationService = DonationService();

  final Set<String> _processingDonationIds = {};

  List<String> get statuses {
    if (selectedTab == 'Donations') {
      return [
        'All',
        'Pending Approval',
        'Available',
        'Reserved',
        'Collected',
        'Rejected',
        'Cancelled',
        'Expired',
      ];
    }

    return [
      'All',
      'Pending',
      'Accepted',
      'Rejected',
      'Cancelled',
    ];
  }

  @override
  void initState() {
    super.initState();
    _verifyAdmin();
  }

  Future<void> _verifyAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Please log in first.');
      }

      final tokenResult = await user.getIdTokenResult(true);

      if (!mounted) return;

      setState(() {
        _isAdmin = tokenResult.claims?['admin'] == true;
        _isCheckingAdmin = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isCheckingAdmin = false;
      });
    }
  }

  String _statusValue(String status) {
    switch (status) {
      case 'Pending Approval':
        return 'pending_approval';
      default:
        return status.toLowerCase();
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pending_approval':
      case 'reserved':
        return Colors.orange;

      case 'accepted':
        return Colors.blue;

      case 'available':
        return Colors.green;

      case 'rejected':
      case 'cancelled':
        return Colors.red;

      case 'collected':
      case 'expired':
        return Colors.purple;

      default:
        return Colors.green.shade700;
    }
  }

  String _statusLabel(String status) {
    if (status == 'pending_approval') {
      return 'PENDING APPROVAL';
    }

    return status.replaceAll('_', ' ').toUpperCase();
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
          final color = getStatusColor(_statusValue(status));

          return ChoiceChip(
            label: Text(status),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: color,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? color : Colors.grey.shade300,
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
              if (selected) {
                setState(() {
                  selectedStatus = status;
                });
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildBadge(String status) {
    final color = getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _handleDonationApproval(
    DonationModel donation,
    bool approve,
  ) async {
    if (_processingDonationIds.contains(donation.id)) return;

    final action = approve ? 'Approve' : 'Reject';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('$action Donation?'),
          content: Text(
            approve
                ? 'Are you sure you want to approve "${donation.title}"? '
                    'It will become visible to receivers.'
                : 'Are you sure you want to reject "${donation.title}"? '
                    'It will not be visible to receivers.',
          ),
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
                backgroundColor:
                    approve ? Colors.green : Colors.red,
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
      _processingDonationIds.add(donation.id);
    });

    try {
      if (approve) {
        await _donationService.approveDonation(donation.id);
      } else {
        await _donationService.rejectDonation(donation.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'Donation approved successfully.'
                : 'Donation rejected successfully.',
          ),
          backgroundColor:
              approve ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingDonationIds.remove(donation.id);
        });
      }
    }
  }

  Widget _buildDonationCard(DonationModel donation) {
    final isPending = donation.status == 'pending_approval';
    final isProcessing =
        _processingDonationIds.contains(donation.id);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.volunteer_activism_outlined,
                color: Colors.green,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  donation.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildBadge(donation.status),
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

          const SizedBox(height: 13),

          _buildInfoRow('Donor', donation.donorName),
          _buildInfoRow('Donor ID', donation.donorId),
          _buildInfoRow('Category', donation.foodType),
          _buildInfoRow('Quantity', donation.quantity),
          _buildInfoRow('Pickup Address', donation.pickupAddress),

          if (isPending) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            const Text(
              'Admin Review Required',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),

            const SizedBox(height: 12),

            if (isProcessing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    color: Colors.green,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _handleDonationApproval(donation, false);
                      },
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                      ),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(
                          color: Colors.red,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _handleDonationApproval(donation, true);
                      },
                      icon: const Icon(
                        Icons.check,
                        size: 18,
                      ),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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

  Widget _buildRequestCard(RequestModel request) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                color: Colors.green,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Food Request',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildBadge(request.status),
            ],
          ),

          const SizedBox(height: 13),

          _buildInfoRow('Request ID', request.id),
          _buildInfoRow('Donation ID', request.donationId),
          _buildInfoRow('Donor ID', request.donorId),
          _buildInfoRow('Requester', request.requesterName),
          _buildInfoRow('Requester ID', request.requesterId),
          _buildInfoRow('Role', request.requesterRole),

          if (request.message.isNotEmpty)
            _buildInfoRow('Message', request.message),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
        ],
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
        border: Border.all(color: Colors.grey.shade100),
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
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDonation
                  ? Icons.volunteer_activism_outlined
                  : Icons.assignment_outlined,
              size: 48,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            selectedStatus == 'All'
                ? (isDonation
                    ? 'No Donations Available'
                    : 'No Requests Available')
                : 'No $selectedStatus '
                    '${isDonation ? 'Donations' : 'Requests'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'No records match the selected filter.',
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
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reset Filter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade700),
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

  Widget _buildRecords() {
    if (selectedTab == 'Donations') {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
            return _buildError(snapshot.error.toString());
          }

          final donations = snapshot.data?.docs.map((doc) {
                return DonationModel.fromMap(doc.id, doc.data());
              }).toList() ??
              <DonationModel>[];

          final filtered = selectedStatus == 'All'
              ? donations
              : donations.where((item) {
                  return item.status.toLowerCase() ==
                      _statusValue(selectedStatus);
                }).toList();

          if (filtered.isEmpty) return buildEmptyState();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRecordCount(filtered.length),
              const SizedBox(height: 12),
              ...filtered.map(_buildDonationCard),
            ],
          );
        },
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .orderBy('request_time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
          return _buildError(snapshot.error.toString());
        }

        final requests = snapshot.data?.docs.map((doc) {
              return RequestModel.fromMap(doc.id, doc.data());
            }).toList() ??
            <RequestModel>[];

        final filtered = selectedStatus == 'All'
            ? requests
            : requests.where((item) {
                return item.status.toLowerCase() ==
                    selectedStatus.toLowerCase();
              }).toList();

        if (filtered.isEmpty) return buildEmptyState();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecordCount(filtered.length),
            const SizedBox(height: 12),
            ...filtered.map(_buildRequestCard),
          ],
        );
      },
    );
  }

  Widget _buildRecordCount(int count) {
    return Text(
      '$count record(s) found',
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 13,
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Could not load records.\n$error',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.red,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 75,
              color: Colors.red.shade300,
            ),

            const SizedBox(height: 18),

            const Text(
              'Admin Access Required',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'You do not have permission to manage donations '
              'and requests.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isCheckingAdmin = true;
                  _error = null;
                });
                _verifyAdmin();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          tooltip: 'Back to Home',
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Manage Donations & Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isCheckingAdmin
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            )
          : !_isAdmin
              ? _buildAccessDenied()
              : SafeArea(
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

                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.03,
                                ),
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

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
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

                        _buildRecords(),

                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
    );
  }
}
