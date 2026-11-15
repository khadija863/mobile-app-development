
import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService =
      NotificationService();

  late final Stream<List<NotificationModel>> _notificationStream;

  bool _isMarkingAllRead = false;

  @override
  void initState() {
    super.initState();
    _notificationStream =
        _notificationService.watchMyNotifications();
  }

  // =====================================================
  // NOTIFICATION COLOR
  // =====================================================

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'new_request':
      case 'request':
      case 'new_donation':
        return Colors.orange;

      case 'donation':
      case 'donation_approved':
      case 'donation_completed':
      case 'delivery_confirmed':
        return Colors.green;

      case 'donation_rejected':
      case 'request_rejected':
      case 'request_cancelled':
      case 'rejected':
        return Colors.red;

      case 'request_accepted':
      case 'accepted':
      case 'task_claimed':
        return Colors.blue;

      case 'food_picked_up':
      case 'food_delivered':
      case 'pickup_confirmed':
      case 'collection':
        return Colors.purple;

      default:
        return Colors.teal;
    }
  }

  // =====================================================
  // NOTIFICATION ICON
  // =====================================================

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'new_request':
      case 'request':
        return Icons.inbox_outlined;

      case 'new_donation':
      case 'donation':
        return Icons.volunteer_activism_outlined;

      case 'donation_approved':
      case 'donation_completed':
      case 'delivery_confirmed':
        return Icons.check_circle_outline;

      case 'donation_rejected':
      case 'request_rejected':
      case 'request_cancelled':
      case 'rejected':
        return Icons.cancel_outlined;

      case 'request_accepted':
      case 'accepted':
        return Icons.check_circle_outline;

      case 'task_claimed':
        return Icons.assignment_ind_outlined;

      case 'food_picked_up':
      case 'pickup_confirmed':
        return Icons.inventory_2_outlined;

      case 'food_delivered':
      case 'collection':
        return Icons.local_shipping_outlined;

      default:
        return Icons.notifications_outlined;
    }
  }

  // =====================================================
  // DATE FORMAT
  // =====================================================

  String _formatDate(DateTime? date) {
    if (date == null) return 'Just now';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute';
  }

  // =====================================================
  // MARK ONE AS READ
  // =====================================================

  Future<void> _markAsRead(
    NotificationModel notification,
  ) async {
    if (notification.isRead) return;

    try {
      await _notificationService.markAsRead(notification.id);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =====================================================
  // MARK ALL AS READ
  // =====================================================

  Future<void> _markAllAsRead() async {
    if (_isMarkingAllRead) return;

    setState(() {
      _isMarkingAllRead = true;
    });

    try {
      await _notificationService.markAllAsRead();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAllRead = false;
        });
      }
    }
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 85,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 20),
            const Text(
              'No Notifications Yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You are all caught up! When you receive updates '
              'about food donations or requests, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // NOTIFICATION CARD
  // =====================================================

  Widget _buildNotificationCard(
    NotificationModel notification,
  ) {
    final color = _getNotificationColor(notification.type);

    final isAdminAlert =
        notification.recipientRole.toLowerCase() == 'admin';

    return InkWell(
      onTap: () => _markAsRead(notification),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : Colors.green.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : Colors.green.shade200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          height: 9,
                          width: 9,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  if (isAdminAlert) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ADMIN ALERT',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 7),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _formatDate(notification.createdAt),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
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

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationStream,
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];

        final unreadCount =
            notifications.where((item) => !item.isRead).length;

        final hasUnread = unreadCount > 0;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F8F5),
          appBar: AppBar(
            title: const Text('Notifications'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: _isMarkingAllRead || !hasUnread
                    ? null
                    : _markAllAsRead,
                child: _isMarkingAllRead
                    ? const SizedBox(
                        height: 17,
                        width: 17,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Mark All Read',
                        style: TextStyle(
                          color: hasUnread
                              ? Colors.white
                              : Colors.white54,
                          fontSize: 12,
                        ),
                      ),
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.green,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Text(
                      'Could not load notifications.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              if (notifications.isEmpty) {
                return _buildEmptyState();
              }

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'You have $unreadCount unread notification(s).',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...notifications.map(_buildNotificationCard),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
