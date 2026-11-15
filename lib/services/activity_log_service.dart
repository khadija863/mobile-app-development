
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/activity_log_model.dart';

class ActivityLogService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ActivityLogService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> verifyAdmin() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    final result = await user.getIdTokenResult(true);

    if (result.claims?['admin'] != true) {
      throw Exception('Admin access required.');
    }
  }

  Stream<List<ActivityLogModel>> watchRecentActivities({
    int limit = 10,
  }) {
    return _db
        .collection('activity_logs')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ActivityLogModel.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();
    });
  }
}
