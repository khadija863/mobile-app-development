
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPreferencesService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationPreferencesService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // =====================================================
  // CURRENT USER ID
  // =====================================================

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDocument {
    return _firestore.collection('users').doc(_uid);
  }

  // =====================================================
  // DEFAULT PREFERENCES
  // =====================================================

  Map<String, bool> get defaultPreferences {
    return {
      // Kept for backward compatibility.
      // Phone push notifications are not implemented.
      'push_enabled': true,

      // In-app workflow notifications are enabled by default.
      'updates_enabled': true,
    };
  }

  // =====================================================
  // GET NOTIFICATION PREFERENCES
  // =====================================================

  Future<Map<String, bool>> getPreferences() async {
    try {
      final snapshot = await _userDocument.get();

      if (!snapshot.exists) {
        throw Exception('User profile not found.');
      }

      final data = snapshot.data();

      final rawPreferences =
          data?['notification_preferences'];

      if (rawPreferences is! Map) {
        return defaultPreferences;
      }

      return {
        'push_enabled':
            rawPreferences['push_enabled'] is bool
                ? rawPreferences['push_enabled'] as bool
                : true,

        'updates_enabled':
            rawPreferences['updates_enabled'] is bool
                ? rawPreferences['updates_enabled'] as bool
                : true,
      };
    } catch (e) {
      throw Exception(
        'Failed to load notification preferences: $e',
      );
    }
  }

  // =====================================================
  // SAVE NOTIFICATION PREFERENCES
  // =====================================================

  Future<void> savePreferences({
    required bool pushEnabled,
    required bool updatesEnabled,
  }) async {
    try {
      await _userDocument.update({
        'notification_preferences.push_enabled': pushEnabled,
        'notification_preferences.updates_enabled': updatesEnabled,
      });
    } catch (e) {
      throw Exception(
        'Failed to save notification preferences: $e',
      );
    }
  }

  // =====================================================
  // UPDATE PUSH PREFERENCE
  // =====================================================

  // Retained only for backward compatibility.
  // This does not enable actual phone push notifications.

  Future<void> updatePushPreference(bool enabled) async {
    try {
      await _userDocument.update({
        'notification_preferences.push_enabled': enabled,
      });
    } catch (e) {
      throw Exception(
        'Failed to update legacy push preference: $e',
      );
    }
  }

  // =====================================================
  // UPDATE DONATION & REQUEST PREFERENCE
  // =====================================================

  Future<void> updateUpdatesPreference(bool enabled) async {
    try {
      await _userDocument.update({
        'notification_preferences.updates_enabled': enabled,
      });
    } catch (e) {
      throw Exception(
        'Failed to update notification preference: $e',
      );
    }
  }
}
