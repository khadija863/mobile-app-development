
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/donation_model.dart';

class DonationService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  DonationService({
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
  // ADMIN VERIFICATION
  // =====================================================

  Future<void> _verifyAdmin() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    final tokenResult = await user.getIdTokenResult(true);

    if (tokenResult.claims?['admin'] != true) {
      throw Exception('Admin access required.');
    }
  }

  // =====================================================
  // DONOR VERIFICATION
  // =====================================================

  Future<void> _verifyActiveDonor(
    Transaction transaction,
    String uid,
  ) async {
    final userRef = _db.collection('users').doc(uid);
    final snapshot = await transaction.get(userRef);

    if (!snapshot.exists) {
      throw Exception('User profile not found.');
    }

    final data = snapshot.data() ?? {};

    if (data['user_type'] != 'donor') {
      throw Exception('Only donors can perform this action.');
    }

    if (data['status'] != 'active') {
      throw Exception('Your account is not active.');
    }
  }

  // =====================================================
  // CHECK NOTIFICATION PREFERENCE
  // =====================================================

  Future<bool> _shouldSendUpdate(
    Transaction transaction,
    String userId,
  ) async {
    final ref = _db.collection('users').doc(userId);
    final snapshot = await transaction.get(ref);

    if (!snapshot.exists) return false;

    final data = snapshot.data() ?? {};
    final preferences = data['notification_preferences'];

    if (preferences is! Map) return true;

    final enabled = preferences['updates_enabled'];

    return enabled is bool ? enabled : true;
  }

  // =====================================================
  // SORT DONATIONS
  // =====================================================

  List<DonationModel> _sortDonations(
    List<DonationModel> donations,
  ) {
    donations.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return donations;
  }

  // =====================================================
  // CREATE DONATION
  // Donation + Admin Notification + Activity Log
  // =====================================================

  Future<String> addDonation(DonationModel donation) async {
    final uid = _uid;

    final userRef = _db.collection('users').doc(uid);

    final donationRef = _db.collection('donations').doc();

    final adminNotificationRef =
        _db.collection('notifications').doc();

    final activityRef =
        _db.collection('activity_logs').doc();

    await _db.runTransaction((transaction) async {
      // READ
      final userSnapshot = await transaction.get(userRef);

      if (!userSnapshot.exists) {
        throw Exception('User profile not found.');
      }

      final userData = userSnapshot.data() ?? {};

      if (userData['user_type'] != 'donor') {
        throw Exception('Only donors can create donations.');
      }

      if (userData['status'] != 'active') {
        throw Exception('Your account is not active.');
      }

      final donorName = userData['name']?.toString() ?? '';

      // PREPARE DONATION
      final donationData = donation.toMap();

      donationData['donor_id'] = uid;
      donationData['donor_name'] = donorName;
      donationData['status'] = 'pending_approval';

      // WRITE DONATION
      transaction.set(donationRef, donationData);

      // WRITE ADMIN BROADCAST NOTIFICATION
      transaction.set(adminNotificationRef, {
        'user_id': '',
        'recipient_role': 'admin',
        'title': 'New Donation Submitted',
        'message': '$donorName submitted a new food donation: ${donation.title}.',
        'type': 'new_donation',
        'related_id': donationRef.id,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      // WRITE ACTIVITY LOG
      transaction.set(activityRef, {
        'actor_id': uid,
        'actor_name': donorName,
        'actor_role': 'donor',
        'action': 'donation_submitted',
        'description': '$donorName submitted donation "${donation.title}".',
        'related_id': donationRef.id,
        'created_at': FieldValue.serverTimestamp(),
      });
    });

    return donationRef.id;
  }

  // =====================================================
  // GET AVAILABLE DONATIONS
  // =====================================================

  Stream<List<DonationModel>> getAvailableDonations() {
    return _db
        .collection('donations')
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) {
      final donations = snapshot.docs.map((doc) {
        return DonationModel.fromMap(doc.id, doc.data());
      }).toList();

      return _sortDonations(donations);
    });
  }

  // =====================================================
  // WATCH MY DONATIONS
  // =====================================================

  Stream<List<DonationModel>> getMyDonations() {
    return _db
        .collection('donations')
        .where('donor_id', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
      final donations = snapshot.docs.map((doc) {
        return DonationModel.fromMap(doc.id, doc.data());
      }).toList();

      return _sortDonations(donations);
    });
  }

  // =====================================================
  // GET SINGLE DONATION
  // =====================================================

  Future<DonationModel?> getDonationById(
    String donationId,
  ) async {
    final snapshot =
        await _db.collection('donations').doc(donationId).get();

    if (!snapshot.exists) return null;

    final data = snapshot.data();

    if (data == null) return null;

    return DonationModel.fromMap(snapshot.id, data);
  }

  // =====================================================
  // ADMIN: WATCH PENDING DONATIONS
  // =====================================================

  Stream<List<DonationModel>> watchPendingDonations() {
    return _db
        .collection('donations')
        .where('status', isEqualTo: 'pending_approval')
        .snapshots()
        .map((snapshot) {
      final donations = snapshot.docs.map((doc) {
        return DonationModel.fromMap(doc.id, doc.data());
      }).toList();

      return _sortDonations(donations);
    });
  }

  // =====================================================
  // ADMIN: APPROVE DONATION
  // Donor Notification + Activity Log
  // =====================================================

  Future<void> approveDonation(String donationId) async {
    await _verifyAdmin();

    final uid = _uid;

    final donationRef =
        _db.collection('donations').doc(donationId);

    final adminRef = _db.collection('users').doc(uid);

    final notificationRef =
        _db.collection('notifications').doc();

    final activityRef =
        _db.collection('activity_logs').doc();

    await _db.runTransaction((transaction) async {
      // READ ALL DOCUMENTS FIRST
      final donationSnapshot = await transaction.get(donationRef);
      final adminSnapshot = await transaction.get(adminRef);

      if (!donationSnapshot.exists) {
        throw Exception('Donation not found.');
      }

      final data = donationSnapshot.data()!;

      if (data['status'] != 'pending_approval') {
        throw Exception(
          'This donation is not waiting for approval.',
        );
      }

      final donorId = data['donor_id'];

      if (donorId is! String || donorId.isEmpty) {
        throw Exception('Invalid donor information.');
      }

      if (!adminSnapshot.exists) {
        throw Exception('Admin profile not found.');
      }

      final adminData = adminSnapshot.data() ?? {};
      final adminName = adminData['name']?.toString() ?? 'Admin';

      final shouldNotify = await _shouldSendUpdate(
        transaction,
        donorId,
      );

      final donationTitle =
          data['title']?.toString() ?? 'Food donation';

      // WRITE
      transaction.update(donationRef, {
        'status': 'available',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (shouldNotify) {
        transaction.set(notificationRef, {
          'user_id': donorId,
          'title': 'Donation Approved',
          'message':
              'Your food donation has been approved and is now visible to receivers.',
          'type': 'donation_approved',
          'related_id': donationId,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(activityRef, {
        'actor_id': uid,
        'actor_name': adminName,
        'actor_role': 'admin',
        'action': 'donation_approved',
        'description':
            '$adminName approved donation "$donationTitle".',
        'related_id': donationId,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  // =====================================================
  // ADMIN: REJECT DONATION
  // Donor Notification + Activity Log
  // =====================================================

  Future<void> rejectDonation(String donationId) async {
    await _verifyAdmin();

    final uid = _uid;

    final donationRef =
        _db.collection('donations').doc(donationId);

    final adminRef = _db.collection('users').doc(uid);

    final notificationRef =
        _db.collection('notifications').doc();

    final activityRef =
        _db.collection('activity_logs').doc();

    await _db.runTransaction((transaction) async {
      // READ ALL DOCUMENTS FIRST
      final donationSnapshot = await transaction.get(donationRef);
      final adminSnapshot = await transaction.get(adminRef);

      if (!donationSnapshot.exists) {
        throw Exception('Donation not found.');
      }

      final data = donationSnapshot.data()!;

      if (data['status'] != 'pending_approval') {
        throw Exception(
          'This donation is not waiting for approval.',
        );
      }

      final donorId = data['donor_id'];

      if (donorId is! String || donorId.isEmpty) {
        throw Exception('Invalid donor information.');
      }

      if (!adminSnapshot.exists) {
        throw Exception('Admin profile not found.');
      }

      final adminData = adminSnapshot.data() ?? {};
      final adminName = adminData['name']?.toString() ?? 'Admin';

      final shouldNotify = await _shouldSendUpdate(
        transaction,
        donorId,
      );

      final donationTitle =
          data['title']?.toString() ?? 'Food donation';

      // WRITE
      transaction.update(donationRef, {
        'status': 'rejected',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (shouldNotify) {
        transaction.set(notificationRef, {
          'user_id': donorId,
          'title': 'Donation Rejected',
          'message':
              'Your food donation was not approved by the admin.',
          'type': 'donation_rejected',
          'related_id': donationId,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(activityRef, {
        'actor_id': uid,
        'actor_name': adminName,
        'actor_role': 'admin',
        'action': 'donation_rejected',
        'description':
            '$adminName rejected donation "$donationTitle".',
        'related_id': donationId,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  // =====================================================
  // UPDATE DONATION
  // =====================================================

  Future<void> updateDonation(
    String donationId,
    DonationModel donation,
  ) async {
    final uid = _uid;

    final donationRef =
        _db.collection('donations').doc(donationId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(donationRef);

      if (!snapshot.exists) {
        throw Exception('Donation not found.');
      }

      final data = snapshot.data()!;

      if (data['donor_id'] != uid) {
        throw Exception(
          'You cannot edit another donor donation.',
        );
      }

      if (data['status'] != 'available') {
        throw Exception(
          'Only available donations can be edited.',
        );
      }

      await _verifyActiveDonor(transaction, uid);

      transaction.update(
        donationRef,
        donation.toUpdateMap(),
      );
    });
  }

  // =====================================================
  // CANCEL DONATION
  // =====================================================

  Future<void> cancelDonation(String donationId) async {
    final uid = _uid;

    final donationRef =
        _db.collection('donations').doc(donationId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(donationRef);

      if (!snapshot.exists) {
        throw Exception('Donation not found.');
      }

      final data = snapshot.data()!;

      if (data['donor_id'] != uid) {
        throw Exception(
          'You cannot cancel another donor donation.',
        );
      }

      final status = data['status'];

      if (status != 'available' &&
          status != 'pending_approval') {
        throw Exception(
          'This donation cannot be cancelled.',
        );
      }

      await _verifyActiveDonor(transaction, uid);

      transaction.update(donationRef, {
        'status': 'cancelled',
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }
}
