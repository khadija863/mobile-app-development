
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  UserService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Get current logged-in user's UID
  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    return user.uid;
  }

  // Get current user's profile once
  Future<UserModel?> getMyProfile() async {
    final doc = await _db.collection('users').doc(_uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(doc.id, doc.data()!);
  }

  // Watch current user's profile in real time
  Stream<UserModel?> watchMyProfile() {
    return _db.collection('users').doc(_uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return UserModel.fromMap(doc.id, doc.data()!);
    });
  }

  // Update current user's profile
  Future<void> updateMyProfile({
    required String name,
    String phone = '',
    String? photoUrl,
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Name cannot be empty.');
    }

    final Map<String, dynamic> updateData = {
      'name': trimmedName,
      'phone': phone.trim(),
    };

    // Update photo_url only when a non-empty URL is provided.
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      updateData['photo_url'] = photoUrl.trim();
    }

    await _db.collection('users').doc(_uid).update(updateData);

    // Firebase Auth display name is secondary to the Firestore profile.
    // A display name update failure should not report the profile save as failed.
    try {
      await _auth.currentUser?.updateDisplayName(trimmedName);
    } catch (_) {
      // Firestore profile has already been updated.
    }
  }

  // Select user role (only pending users can select once)
  Future<void> selectRole(String role) async {
    const roles = {
      'donor',
      'receiver',
      'volunteer',
    };

    if (!roles.contains(role)) {
      throw ArgumentError('Invalid user role.');
    }

    final ref = _db.collection('users').doc(_uid);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        throw Exception('User profile not found.');
      }

      final data = snapshot.data()!;
      final currentRole = data['user_type'];
      final currentStatus = data['status'] ?? 'active';

      if (currentStatus != 'active') {
        throw Exception('Your account is not active.');
      }

      if (currentRole != 'pending') {
        throw Exception('Your role has already been selected.');
      }

      transaction.update(ref, {
        'user_type': role,
      });
    });
  }
}
