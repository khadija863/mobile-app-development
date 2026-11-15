
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/activity_log_model.dart';
import '../services/activity_log_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const AdminDashboardScreen({
    super.key,
    this.onBack,
  });

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  bool _isCheckingAdmin = true;
  bool _isAdmin = false;
  String? _error;

  final ActivityLogService _activityLogService =
      ActivityLogService();

  late final Stream<List<ActivityLogModel>> _activityStream;

  @override
  void initState() {
    super.initState();
    _activityStream =
        _activityLogService.watchRecentActivities(limit: 10);
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

  Stream<int> _countStream(Query query) {
    return query.snapshots().map((snapshot) => snapshot.size);
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCountCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<int> stream,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        String value = '--';

        if (snapshot.hasData) {
          value = snapshot.data.toString();
        } else if (snapshot.hasError) {
          value = 'Error';
        }

        return _buildStatCard(
          title: title,
          icon: icon,
          color: color,
          value: value,
        );
      },
    );
  }

  IconData _getActivityIcon(String action) {
    switch (action.toLowerCase()) {
      case 'donation_submitted':
        return Icons.volunteer_activism_outlined;
      case 'donation_approved':
        return Icons.check_circle_outline;
      case 'donation_rejected':
        return Icons.cancel_outlined;
      case 'request_created':
        return Icons.note_add_outlined;
      case 'request_accepted':
        return Icons.task_alt_outlined;
      case 'request_rejected':
        return Icons.block_outlined;
      case 'request_cancelled':
        return Icons.assignment_return_outlined;
      case 'task_claimed':
        return Icons.delivery_dining_outlined;
      case 'food_picked_up':
        return Icons.inventory_2_outlined;
      case 'food_delivered':
        return Icons.local_shipping_outlined;
      default:
        return Icons.history;
    }
  }

  Color _getActivityColor(String action) {
    switch (action.toLowerCase()) {
      case 'donation_submitted':
      case 'request_created':
        return Colors.orange;
      case 'donation_approved':
      case 'request_accepted':
      case 'food_delivered':
        return Colors.green;
      case 'donation_rejected':
      case 'request_rejected':
      case 'request_cancelled':
        return Colors.red;
      case 'task_claimed':
      case 'food_picked_up':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

  String _formatActivityTime(DateTime? date) {
    if (date == null) return 'Just now';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} day(s) ago';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _buildActivityItem(ActivityLogModel activity) {
    final color = _getActivityColor(activity.action);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getActivityIcon(activity.action),
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${activity.actorName} • ${activity.actorRole}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatActivityTime(activity.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return StreamBuilder<List<ActivityLogModel>>(
      stream: _activityStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(25),
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 38,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Could not load activity logs.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          );
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 30,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3F3E5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history,
                    size: 42,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'No Recent Activity',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Platform activities will appear here '
                  'when users submit donations, create requests '
                  'or complete deliveries.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < activities.length; i++) ...[
                _buildActivityItem(activities[i]),
                if (i != activities.length - 1)
                  Divider(
                    height: 8,
                    color: Colors.grey.shade100,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboard() {
    final db = FirebaseFirestore.instance;

    final totalUsersStream = _countStream(
      db.collection('users'),
    );

    final totalDonationsStream = _countStream(
      db.collection('donations'),
    );

    final pendingRequestsStream = _countStream(
      db.collection('requests').where(
        'status',
        isEqualTo: 'pending',
      ),
    );

    final completedDonationsStream = _countStream(
      db.collection('donations').where(
        'status',
        isEqualTo: 'collected',
      ),
    );

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final crossAxisCount = screenWidth >= 600 ? 3 : 2;

          final cardRatio = screenWidth < 360
              ? 0.78
              : screenWidth < 600
                  ? 0.85
                  : 1.0;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor FoodLink platform activities.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 25),
                _buildSectionTitle('Statistics'),
                const SizedBox(height: 15),
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: cardRatio,
                  children: [
                    _buildCountCard(
                      title: 'Total Users',
                      icon: Icons.people_outline,
                      color: Colors.blue,
                      stream: totalUsersStream,
                    ),
                    _buildCountCard(
                      title: 'Total Donations',
                      icon: Icons.volunteer_activism_outlined,
                      color: Colors.green,
                      stream: totalDonationsStream,
                    ),
                    _buildCountCard(
                      title: 'Pending Requests',
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                      stream: pendingRequestsStream,
                    ),
                    _buildCountCard(
                      title: 'Completed Donations',
                      icon: Icons.check_circle_outline,
                      color: Colors.purple,
                      stream: completedDonationsStream,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildSectionTitle('Recent Activity'),
                const SizedBox(height: 15),
                _buildRecentActivity(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
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
              'You do not have permission to access this dashboard.',
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
          onPressed: widget.onBack ??
              () {
                Navigator.maybePop(context);
              },
        ),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
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
          : _isAdmin
              ? _buildDashboard()
              : _buildAccessDenied(),
    );
  }
}
