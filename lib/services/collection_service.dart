
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/collection_model.dart';

class CollectionService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionService({
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

  CollectionReference<Map<String, dynamic>> get _collections =>
      _db.collection('collections');

  // =====================================================
  // VERIFY ACTIVE VOLUNTEER
  // Returns volunteer profile data.
  // =====================================================

  Future<Map<String, dynamic>> _verifyVolunteer(
    Transaction transaction,
    String uid,
  ) async {
    final userRef = _db.collection('users').doc(uid);
    final snapshot = await transaction.get(userRef);

    if (!snapshot.exists) {
      throw Exception('User profile not found.');
    }

    final userData = snapshot.data() ?? {};

    if (userData['user_type'] != 'volunteer') {
      throw Exception('Only volunteers can perform this action.');
    }

    if (userData['status'] != 'active') {
      throw Exception('Your account is not active.');
    }

    return userData;
  }

  // =====================================================
  // CHECK IN-APP NOTIFICATION PREFERENCE
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
  // WATCH AVAILABLE COLLECTIONS
  // Volunteer sees unclaimed delivery tasks.
  // =====================================================

  Stream<List<CollectionModel>> watchAvailableCollections() {
    return _collections
        .where('status', isEqualTo: 'assigned')
        .where('volunteer_id', isEqualTo: '')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CollectionModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // =====================================================
  // CLAIM COLLECTION
  // Volunteer Notification + Activity Log
  // =====================================================

  Future<void> claimCollection(String collectionId) async {
    final uid = _uid;

    final collectionRef = _collections.doc(collectionId);
    final volunteerNotificationRef =
        _db.collection('notifications').doc();
    final activityRef =
        _db.collection('activity_logs').doc();

    await _db.runTransaction((transaction) async {
      // READ VOLUNTEER
      final volunteerData = await _verifyVolunteer(
        transaction,
        uid,
      );

      // READ COLLECTION
      final collectionSnapshot =
          await transaction.get(collectionRef);

      if (!collectionSnapshot.exists) {
        throw Exception('Collection not found.');
      }

      final data = collectionSnapshot.data()!;

      if (data['status'] != 'assigned') {
        throw Exception('This task is no longer available.');
      }

      if (data['volunteer_id'] != '') {
        throw Exception('This task has already been claimed.');
      }

      final volunteerName =
          volunteerData['name']?.toString() ?? 'Volunteer';

      // final donationId = data['donation_id']?.toString() ?? '';

      // READ VOLUNTEER NOTIFICATION PREFERENCE
      final shouldNotifyVolunteer = await _shouldSendUpdate(
        transaction,
        uid,
      );

      // WRITE: CLAIM TASK
      transaction.update(collectionRef, {
        'volunteer_id': uid,
      });

      // WRITE: VOLUNTEER CONFIRMATION
      if (shouldNotifyVolunteer) {
        transaction.set(volunteerNotificationRef, {
          'user_id': uid,
          'title': 'Delivery Task Claimed',
          'message':
              'You have successfully claimed a food delivery task.',
          'type': 'task_claimed',
          'related_id': collectionId,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      // WRITE: ACTIVITY LOG
      transaction.set(activityRef, {
        'actor_id': uid,
        'actor_name': volunteerName,
        'actor_role': 'volunteer',
        'action': 'task_claimed',
        'description':
            '$volunteerName claimed a delivery task.',
        'related_id': collectionId,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  // =====================================================
  // WATCH MY VOLUNTEER COLLECTIONS
  // =====================================================

  Stream<List<CollectionModel>> watchMyCollections() {
    return _collections
        .where('volunteer_id', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CollectionModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // =====================================================
  // WATCH COLLECTIONS FOR MY DONATIONS
  // =====================================================

  Stream<List<CollectionModel>> watchCollectionsForMyDonations() {
    return _collections
        .where('donor_id', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CollectionModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // =====================================================
  // WATCH MY RECEIVED COLLECTIONS
  // =====================================================

  Stream<List<CollectionModel>> watchMyReceivedCollections() {
    return _collections
        .where('receiver_id', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CollectionModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // =====================================================
  // MARK COLLECTION AS PICKED UP
  // Receiver Notification + Activity Log
  // Volunteer Confirmation
  // =====================================================

  Future<void> markPickedUp(String collectionId) async {
    final uid = _uid;

    final collectionRef = _collections.doc(collectionId);

    final receiverNotificationRef =
        _db.collection('notifications').doc();

    final volunteerNotificationRef =
        _db.collection('notifications').doc();

    final activityRef =
        _db.collection('activity_logs').doc();

    await _db.runTransaction((transaction) async {
      // READ VOLUNTEER
      final volunteerData = await _verifyVolunteer(
        transaction,
        uid,
      );

      // READ COLLECTION
      final collectionSnapshot =
          await transaction.get(collectionRef);

      if (!collectionSnapshot.exists) {
        throw Exception('Collection not found.');
      }

      final data = collectionSnapshot.data()!;

      if (data['volunteer_id'] != uid) {
        throw Exception(
          'You are not assigned to this collection.',
        );
      }

      if (data['status'] != 'assigned') {
        throw Exception(
          'This collection cannot be marked as picked up.',
        );
      }

      final receiverId = data['receiver_id'];

      if (receiverId is! String || receiverId.isEmpty) {
        throw Exception('Receiver information is missing.');
      }

      final volunteerName =
          volunteerData['name']?.toString() ?? 'Volunteer';

      // READ NOTIFICATION PREFERENCES
      final shouldNotifyReceiver = await _shouldSendUpdate(
        transaction,
        receiverId,
      );

      final shouldNotifyVolunteer = await _shouldSendUpdate(
        transaction,
        uid,
      );

      // WRITE: UPDATE COLLECTION
      transaction.update(collectionRef, {
        'status': 'picked_up',
        'pickup_time': FieldValue.serverTimestamp(),
      });

      // WRITE: RECEIVER NOTIFICATION
      if (shouldNotifyReceiver) {
        transaction.set(receiverNotificationRef, {
          'user_id': receiverId,
          'title': 'Food Picked Up',
          'message':
              'The volunteer has picked up your requested food. It is on the way.',
          'type': 'food_picked_up',
          'related_id': collectionId,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      // WRITE: VOLUNTEER CONFIRMATION
      if (shouldNotifyVolunteer) {
        transaction.set(volunteerNotificationRef, {
          'user_id': uid,
          'title': 'Pickup Confirmed',
          'message':
              'You successfully marked the food as picked up.',
          'type': 'pickup_confirmed',
          'related_id': collectionId,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      // WRITE: ACTIVITY LOG
      transaction.set(activityRef, {
        'actor_id': uid,
        'actor_name': volunteerName,
        'actor_role': 'volunteer',
        'action': 'food_picked_up',
        'description':
            '$volunteerName picked up a food delivery.',
        'related_id': collectionId,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  // =====================================================
  // MARK COLLECTION AS DELIVERED
  // UPDATE COLLECTION + DONATION + REQUEST
  // Receiver + Donor + Volunteer Notifications
  // Activity Log
  // =====================================================

  Future<void> markDelivered(String collectionId) async {
    final uid = _uid;

    final collectionRef = _collections.doc(collectionId);

    final receiverNotificationRef =
        _db.collection('notifications').doc();

    final donorNotificationRef =
        _db.collection('notifications').doc();

    final volunteerNotificationRef =
        _db.collection('notifications').doc();

    final activityRef =
        _db.collection('activity_logs').doc();

    await _db.runTransaction((transaction) async {
      // READ VOLUNTEER
      final volunteerData = await _verifyVolunteer(
        transaction,
        uid,
      );

      // READ COLLECTION
      final collectionSnapshot =
          await transaction.get(collectionRef);

      if (!collectionSnapshot.exists) {
        throw Exception('Collection not found.');
      }

      final collectionData = collectionSnapshot.data()!;

      if (collectionData['volunteer_id'] != uid) {
        throw Exception(
          'Only the assigned volunteer can deliver this food.',
        );
      }

      if (collectionData['status'] != 'picked_up') {
        throw Exception(
          'Food must be picked up before delivery.',
        );
      }

      final donationId = collectionData['donation_id'];
      final requestId = collectionData['request_id'];
      final receiverId = collectionData['receiver_id'];
      final donorId = collectionData['donor_id'];

      if (donationId is! String || donationId.isEmpty) {
        throw Exception('Invalid donation information.');
      }

      if (requestId is! String || requestId.isEmpty) {
        throw Exception('Invalid request information.');
      }

      if (receiverId is! String || receiverId.isEmpty) {
        throw Exception('Invalid receiver information.');
      }

      if (donorId is! String || donorId.isEmpty) {
        throw Exception('Invalid donor information.');
      }

      if (collectionId != requestId) {
        throw Exception(
          'Collection and request IDs do not match.',
        );
      }

      final donationRef =
          _db.collection('donations').doc(donationId);

      final requestRef =
          _db.collection('requests').doc(requestId);

      // READ DONATION AND REQUEST
      final donationSnapshot =
          await transaction.get(donationRef);

      final requestSnapshot =
          await transaction.get(requestRef);

      if (!donationSnapshot.exists) {
        throw Exception('Donation not found.');
      }

      if (!requestSnapshot.exists) {
        throw Exception('Request not found.');
      }

      final donationData = donationSnapshot.data()!;
      final requestData = requestSnapshot.data()!;

      // VALIDATE DONATION
      if (donationData['status'] != 'reserved') {
        throw Exception(
          'This donation is not in reserved status.',
        );
      }

      if (donationData['active_request_id'] != requestId) {
        throw Exception(
          'Donation and collection do not match.',
        );
      }

      if (donationData['donor_id'] != donorId) {
        throw Exception(
          'Donation donor information mismatch.',
        );
      }

      // VALIDATE REQUEST
      if (requestData['status'] != 'accepted') {
        throw Exception(
          'This request is not in accepted status.',
        );
      }

      if (requestData['requester_role'] != 'receiver' ||
          requestData['donation_id'] != donationId ||
          requestData['donor_id'] != donorId ||
          requestData['requester_id'] != receiverId) {
        throw Exception(
          'Request and collection information do not match.',
        );
      }

      final volunteerName =
          volunteerData['name']?.toString() ?? 'Volunteer';

      // READ ALL NOTIFICATION PREFERENCES
      final shouldNotifyReceiver = await _shouldSendUpdate(
        transaction,
        receiverId,
      );

      final shouldNotifyDonor = await _shouldSendUpdate(
        transaction,
        donorId,
      );

      final shouldNotifyVolunteer = await _shouldSendUpdate(
        transaction,
        uid,
      );

      // WRITE: UPDATE COLLECTION
      transaction.update(collectionRef, {
        'status': 'delivered',
        'delivery_time': FieldValue.serverTimestamp(),
      });

      // WRITE: UPDATE DONATION
      transaction.update(donationRef, {
        'status': 'collected',
        'updated_at': FieldValue.serverTimestamp(),
      });

      // WRITE: COMPLETE REQUEST
      transaction.update(requestRef, {
        'status': 'completed',
        'updated_at': FieldValue.serverTimestamp(),
      });

      // WRITE: RECEIVER NOTIFICATION
      if (shouldNotifyReceiver) {
        transaction.set(receiverNotificationRef, {
          'user_id': receiverId,
          'title': 'Food Delivered',
          'message':
              'Your requested food has been successfully delivered.',
          'type': 'food_delivered',
          'related_id': collectionId,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      // WRITE: DONOR NOTIFICATION
      if (shouldNotifyDonor) {
        transaction.set(donorNotificationRef, {
          'user_id': donorId,
          'title': 'Donation Completed',
          'message':
              'Your donated food has been successfully delivered to the receiver.',
          'type': 'donation_completed',
          'related_id': collectionId,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      // WRITE: VOLUNTEER CONFIRMATION
      if (shouldNotifyVolunteer) {
        transaction.set(volunteerNotificationRef, {
          'user_id': uid,
          'title': 'Delivery Confirmed',
          'message':
              'You successfully completed this food delivery.',
          'type': 'delivery_confirmed',
          'related_id': collectionId,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      // WRITE: ACTIVITY LOG
      transaction.set(activityRef, {
        'actor_id': uid,
        'actor_name': volunteerName,
        'actor_role': 'volunteer',
        'action': 'food_delivered',
        'description':
            '$volunteerName successfully delivered a food donation.',
        'related_id': collectionId,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }
}
