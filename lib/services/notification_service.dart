
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // =====================================================
  // CURRENT USER
  // =====================================================

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    return user.uid;
  }

  // =====================================================
  // VERIFY ADMIN CUSTOM CLAIM
  // =====================================================

  Future<bool> _isAdmin() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    final tokenResult = await user.getIdTokenResult(true);

    return tokenResult.claims?['admin'] == true;
  }

  // =====================================================
  // GET CURRENT USER NOTIFICATION QUERY
  // Admin sees role-based broadcast notifications.
  // Other users see their own notifications.
  // =====================================================

  Future<Query<Map<String, dynamic>>> _getMyNotificationQuery()
      async {
    final admin = await _isAdmin();

    if (admin) {
      return _db
          .collection('notifications')
          .where('recipient_role', isEqualTo: 'admin')
          .orderBy('created_at', descending: true);
    }

    return _db
        .collection('notifications')
        .where('user_id', isEqualTo: _uid)
        .orderBy('created_at', descending: true);
  }

  // =====================================================
  // WATCH MY NOTIFICATIONS
  // =====================================================

  Stream<List<NotificationModel>> watchMyNotifications() async* {
    final query = await _getMyNotificationQuery();

    await for (final snapshot in query.snapshots()) {
      yield snapshot.docs.map((doc) {
        return NotificationModel.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();
    }
  }

  // =====================================================
  // CHECK NOTIFICATION OWNERSHIP
  // Supports both personal and Admin notifications.
  // =====================================================

  Future<void> _verifyNotificationAccess(
    Map<String, dynamic> data,
  ) async {
    final admin = await _isAdmin();

    final recipientRole =
        data['recipient_role']?.toString() ?? '';

    final userId = data['user_id']?.toString() ?? '';

    // Admin broadcast notification.
    if (recipientRole == 'admin') {
      if (!admin) {
        throw Exception(
          'Only administrators can access this notification.',
        );
      }

      return;
    }

    // Personal notification.
    if (userId != _uid) {
      throw Exception(
        'You cannot access this notification.',
      );
    }
  }

  // =====================================================
  // MARK ONE NOTIFICATION AS READ
  // =====================================================

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.trim().isEmpty) {
      throw ArgumentError('Invalid notification ID.');
    }

    final ref =
        _db.collection('notifications').doc(notificationId);

    final snapshot = await ref.get();

    if (!snapshot.exists) {
      throw Exception('Notification not found.');
    }

    final data = snapshot.data();

    if (data == null) {
      throw Exception('Notification data not found.');
    }

    await _verifyNotificationAccess(data);

    if (data['is_read'] == true) {
      return;
    }

    await ref.update({
      'is_read': true,
    });
  }

  // =====================================================
  // MARK ALL NOTIFICATIONS AS READ
  // Works for Admin and normal users.
  // =====================================================

  Future<void> markAllAsRead() async {
    final query = await _getMyNotificationQuery();

    final snapshot = await query
        .where('is_read', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    // Firestore batch maximum is 500 writes.
    const batchSize = 450;

    for (int i = 0; i < snapshot.docs.length; i += batchSize) {
      final batch = _db.batch();

      final end = (i + batchSize < snapshot.docs.length)
          ? i + batchSize
          : snapshot.docs.length;

      for (int j = i; j < end; j++) {
        batch.update(
          snapshot.docs[j].reference,
          {
            'is_read': true,
          },
        );
      }

      await batch.commit();
    }
  }
}
