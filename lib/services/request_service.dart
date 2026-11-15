
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/request_model.dart';

class RequestService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  RequestService({
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
  // VERIFY ACTIVE ROLE
  // =====================================================

  void _validateActiveRole(
    Map<String, dynamic> userData,
    String requiredRole,
  ) {
    if (userData['user_type'] != requiredRole) {
      throw Exception(
        'Only $requiredRole users can perform this action.',
      );
    }

    if (userData['status'] != 'active') {
      throw Exception('Your account is not active.');
    }
  }

  // =====================================================
  // NOTIFICATION PREFERENCE
  // =====================================================

  Future<bool> _shouldSendUpdate(
    Transaction transaction,
    String userId,
  ) async {
    final userRef = _db.collection('users').doc(userId);
    final snapshot = await transaction.get(userRef);

    if (!snapshot.exists) return false;

    final userData = snapshot.data() ?? {};
    final preferences = userData['notification_preferences'];

    if (preferences is! Map) return true;

    final enabled = preferences['updates_enabled'];

    return enabled is bool ? enabled : true;
  }

  // =====================================================
  // CREATE REQUEST
  // Receiver -> Donor Notification
  // Receiver -> Admin Notification
  // Activity Log
  //
  // Existing rejected/cancelled request can be retried.
  // =====================================================

  Future<String> createRequest({
    required String donationId,
    required String message,
  }) async {
    final uid = _uid;

    final userRef = _db.collection('users').doc(uid);
    final donationRef = _db.collection('donations').doc(donationId);

    // One request document per receiver + donation.
    final requestId = '${donationId}_$uid';

    final requestRef = _db.collection('requests').doc(requestId);

    // Donor notification.
    final donorNotificationRef =
        _db.collection('notifications').doc();

    // Admin notification.
    final adminNotificationRef =
        _db.collection('notifications').doc();

    final activityRef =
        _db.collection('activity_logs').doc();

    await _db.runTransaction((transaction) async {
      // ---------------- READ ----------------

      final userSnapshot = await transaction.get(userRef);
      final donationSnapshot = await transaction.get(donationRef);
      final existingSnapshot = await transaction.get(requestRef);

      if (!userSnapshot.exists) {
        throw Exception('User profile not found.');
      }

      if (!donationSnapshot.exists) {
        throw Exception('Donation not found.');
      }

      final userData = userSnapshot.data()!;
      final donationData = donationSnapshot.data()!;

      _validateActiveRole(userData, 'receiver');

      if (donationData['status'] != 'available') {
        throw Exception('This food is no longer available.');
      }

      final donorId = donationData['donor_id'];

      if (donorId is! String || donorId.isEmpty) {
        throw Exception('Donation donor information is missing.');
      }

      if (donorId == uid) {
        throw Exception('You cannot request your own donation.');
      }

      // Prevent duplicate pending or accepted requests.
      if (existingSnapshot.exists) {
        final existingData = existingSnapshot.data() ?? {};
        final existingStatus = existingData['status'];

        if (existingStatus == 'pending' ||
            existingStatus == 'accepted') {
          throw Exception(
            'You have already requested this donation.',
          );
        }

        if (existingStatus != 'rejected' &&
            existingStatus != 'cancelled') {
          throw Exception(
            'This request cannot be submitted again.',
          );
        }

        if (existingData['requester_id'] != uid ||
            existingData['donation_id'] != donationId ||
            existingData['donor_id'] != donorId) {
          throw Exception(
            'Existing request information mismatch.',
          );
        }
      }

      final shouldNotifyDonor = await _shouldSendUpdate(
        transaction,
        donorId,
      );

      final receiverName =
          userData['name']?.toString() ?? 'Someone';

      final donationTitle =
          donationData['title']?.toString() ?? 'food donation';

      // ---------------- WRITE REQUEST ----------------

      final requestData = {
        'donation_id': donationId,
        'donor_id': donorId,
        'requester_id': uid,
        'requester_role': 'receiver',
        'requester_name': receiverName,
        'message': message.trim(),
        'volunteer_id': '',
        'status': 'pending',
        'request_time': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (existingSnapshot.exists) {
        transaction.update(requestRef, requestData);
      } else {
        transaction.set(requestRef, requestData);
      }

      // ---------------- DONOR NOTIFICATION ----------------

      if (shouldNotifyDonor) {
        transaction.set(donorNotificationRef, {
          'user_id': donorId,
          'title': 'New Food Request',
          'message':
              '$receiverName requested your food donation "$donationTitle".',
          'type': 'new_request',
          'related_id': requestId,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      // ---------------- ADMIN NOTIFICATION ----------------

      transaction.set(adminNotificationRef, {
        'user_id': '',
        'recipient_role': 'admin',
        'title': 'New Food Request',
        'message':
            '$receiverName submitted a request for "$donationTitle".',
        'type': 'new_request',
        'related_id': requestId,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      // ---------------- ACTIVITY LOG ----------------

      transaction.set(activityRef, {
        'actor_id': uid,
        'actor_name': receiverName,
        'actor_role': 'receiver',
        'action': 'request_created',
        'description':
            '$receiverName requested "$donationTitle".',
        'related_id': requestId,
        'created_at': FieldValue.serverTimestamp(),
      });
    });

    return requestId;
  }

  // =====================================================
  // WATCH REQUESTS FOR MY DONATIONS
  // =====================================================

  Stream<List<RequestModel>> watchRequestsForMyDonations() {
    return _db
        .collection('requests')
        .where('donor_id', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        return RequestModel.fromMap(doc.id, doc.data());
      }).toList();

      requests.sort((a, b) {
        final aDate = a.requestTime;
        final bDate = b.requestTime;

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });

      return requests;
    });
  }

  // =====================================================
  // WATCH MY REQUESTS
  // =====================================================

  Stream<List<RequestModel>> watchMyRequests() {
    return _db
        .collection('requests')
        .where('requester_id', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        return RequestModel.fromMap(doc.id, doc.data());
      }).toList();

      requests.sort((a, b) {
        final aDate = a.requestTime;
        final bDate = b.requestTime;

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });

      return requests;
    });
  }

  // =====================================================
  // ACCEPT REQUEST
  // Donor -> Receiver Notification
  // Donor -> Admin Notification
  // Activity Log
  // Creates collection for Volunteer delivery.
  // =====================================================

  Future<void> acceptRequest(String requestId) async {
    final uid = _uid;

    final userRef = _db.collection('users').doc(uid);
    final requestRef = _db.collection('requests').doc(requestId);
    final collectionRef =
        _db.collection('collections').doc(requestId);

    // Receiver notification.
    final receiverNotificationRef =
        _db.collection('notifications').doc();

    // Admin notification.
    final adminNotificationRef =
        _db.collection('notifications').doc();

    final activityRef =
        _db.collection('activity_logs').doc();

    await _db.runTransaction((transaction) async {
      // ---------------- READ ----------------

      final userSnapshot = await transaction.get(userRef);
      final requestSnapshot = await transaction.get(requestRef);
      final collectionSnapshot = await transaction.get(collectionRef);

      if (!userSnapshot.exists) {
        throw Exception('User profile not found.');
      }

      if (!requestSnapshot.exists) {
        throw Exception('Request not found.');
      }

      _validateActiveRole(userSnapshot.data()!, 'donor');

      final requestData = requestSnapshot.data()!;

      if (requestData['donor_id'] != uid) {
        throw Exception(
          'Only the donor can accept this request.',
        );
      }

      if (requestData['status'] != 'pending') {
        throw Exception(
          'This request is no longer pending.',
        );
      }

      if (requestData['requester_role'] != 'receiver') {
        throw Exception(
          'Only receiver requests can be accepted.',
        );
      }

      if (collectionSnapshot.exists) {
        throw Exception(
          'A collection already exists for this request.',
        );
      }

      final donationId = requestData['donation_id'];
      final receiverId = requestData['requester_id'];

      if (donationId is! String || donationId.isEmpty) {
        throw Exception('Invalid donation information.');
      }

      if (receiverId is! String || receiverId.isEmpty) {
        throw Exception('Invalid receiver information.');
      }

      final donationRef =
          _db.collection('donations').doc(donationId);

      final donationSnapshot =
          await transaction.get(donationRef);

      if (!donationSnapshot.exists) {
        throw Exception('Donation not found.');
      }

      final donationData = donationSnapshot.data()!;

      if (donationData['status'] != 'available') {
        throw Exception(
          'This donation is no longer available.',
        );
      }

      if (donationData['donor_id'] != uid) {
        throw Exception('Donation ownership mismatch.');
      }

      // Check receiver notification preference.
      final shouldNotifyReceiver = await _shouldSendUpdate(
        transaction,
        receiverId,
      );

      final donorName =
          userSnapshot.data()?['name']?.toString() ?? 'Donor';

      final donationTitle =
          donationData['title']?.toString() ?? 'food donation';

      // ---------------- WRITE: ACCEPT REQUEST ----------------

      transaction.update(requestRef, {
        'status': 'accepted',
        'updated_at': FieldValue.serverTimestamp(),
      });

      // ---------------- WRITE: RESERVE DONATION ----------------

      transaction.update(donationRef, {
        'status': 'reserved',
        'active_request_id': requestId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // ---------------- WRITE: CREATE COLLECTION ----------------

      transaction.set(collectionRef, {
        'request_id': requestId,
        'donation_id': donationId,
        'donor_id': uid,
        'receiver_id': receiverId,
        'volunteer_id': '',
        'status': 'assigned',
        'created_at': FieldValue.serverTimestamp(),
      });

      // ---------------- RECEIVER NOTIFICATION ----------------

      if (shouldNotifyReceiver) {
        transaction.set(receiverNotificationRef, {
          'user_id': receiverId,
          'title': 'Request Accepted',
          'message':
              'Your request for "$donationTitle" has been accepted by the donor.',
          'type': 'request_accepted',
          'related_id': requestId,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      // ---------------- ADMIN NOTIFICATION ----------------

      transaction.set(adminNotificationRef, {
        'user_id': '',
        'recipient_role': 'admin',
        'title': 'Request Accepted',
        'message':
            '$donorName accepted a request for "$donationTitle".',
        'type': 'request_accepted',
        'related_id': requestId,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      // ---------------- ACTIVITY LOG ----------------

      transaction.set(activityRef, {
        'actor_id': uid,
        'actor_name': donorName,
        'actor_role': 'donor',
        'action': 'request_accepted',
        'description':
            '$donorName accepted a request for "$donationTitle".',
        'related_id': requestId,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  // =====================================================
  // REJECT REQUEST
  // Donor -> Receiver Notification + Activity Log
  // =====================================================

  Future<void> rejectRequest(String requestId) async {
    final uid = _uid;

    final userRef = _db.collection('users').doc(uid);
    final requestRef = _db.collection('requests').doc(requestId);

    final notificationRef =
        _db.collection('notifications').doc();

    final activityRef =
        _db.collection('activity_logs').doc();

    await _db.runTransaction((transaction) async {
      // READ
      final userSnapshot = await transaction.get(userRef);
      final requestSnapshot = await transaction.get(requestRef);

      if (!userSnapshot.exists) {
        throw Exception('User profile not found.');
      }

      if (!requestSnapshot.exists) {
        throw Exception('Request not found.');
      }

      _validateActiveRole(userSnapshot.data()!, 'donor');

      final data = requestSnapshot.data()!;

      if (data['donor_id'] != uid) {
        throw Exception(
          'Only the donor can reject this request.',
        );
      }

      if (data['status'] != 'pending') {
        throw Exception(
          'This request cannot be rejected.',
        );
      }

      final receiverId = data['requester_id'];

      if (receiverId is! String || receiverId.isEmpty) {
        throw Exception('Invalid receiver information.');
      }

      final shouldNotify = await _shouldSendUpdate(
        transaction,
        receiverId,
      );

      final donorName =
          userSnapshot.data()?['name']?.toString() ?? 'Donor';

      // WRITE
      transaction.update(requestRef, {
        'status': 'rejected',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (shouldNotify) {
        transaction.set(notificationRef, {
          'user_id': receiverId,
          'title': 'Request Rejected',
          'message':
              'Unfortunately, your food request was rejected by the donor.',
          'type': 'request_rejected',
          'related_id': requestId,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(activityRef, {
        'actor_id': uid,
        'actor_name': donorName,
        'actor_role': 'donor',
        'action': 'request_rejected',
        'description':
            '$donorName rejected a food request.',
        'related_id': requestId,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  // =====================================================
  // CANCEL MY REQUEST
  // Receiver -> Donor Notification + Activity Log
  // =====================================================

  Future<void> cancelMyRequest(String requestId) async {
    final uid = _uid;

    final userRef = _db.collection('users').doc(uid);
    final requestRef = _db.collection('requests').doc(requestId);

    final notificationRef =
        _db.collection('notifications').doc();

    final activityRef =
        _db.collection('activity_logs').doc();

    await _db.runTransaction((transaction) async {
      // READ
      final userSnapshot = await transaction.get(userRef);
      final requestSnapshot = await transaction.get(requestRef);

      if (!userSnapshot.exists) {
        throw Exception('User profile not found.');
      }

      if (!requestSnapshot.exists) {
        throw Exception('Request not found.');
      }

      _validateActiveRole(userSnapshot.data()!, 'receiver');

      final data = requestSnapshot.data()!;

      if (data['requester_id'] != uid) {
        throw Exception(
          'You cannot cancel another user request.',
        );
      }

      if (data['status'] != 'pending') {
        throw Exception(
          'Only pending requests can be cancelled.',
        );
      }

      final donorId = data['donor_id'];

      if (donorId is! String || donorId.isEmpty) {
        throw Exception('Invalid donor information.');
      }

      final shouldNotify = await _shouldSendUpdate(
        transaction,
        donorId,
      );

      final receiverName =
          userSnapshot.data()?['name']?.toString() ?? 'Receiver';

      // WRITE
      transaction.update(requestRef, {
        'status': 'cancelled',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (shouldNotify) {
        transaction.set(notificationRef, {
          'user_id': donorId,
          'title': 'Request Cancelled',
          'message':
              '$receiverName cancelled their food request.',
          'type': 'request_cancelled',
          'related_id': requestId,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(activityRef, {
        'actor_id': uid,
        'actor_name': receiverName,
        'actor_role': 'receiver',
        'action': 'request_cancelled',
        'description':
            '$receiverName cancelled a food request.',
        'related_id': requestId,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }
}
