
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String userType;
  final String status;
  final String phone;
  final String photoUrl;
  final DateTime? createdAt;

  const UserModel({
    this.id = '',
    required this.name,
    required this.email,
    this.userType = 'pending',
    this.status = 'active',
    this.phone = '',
    this.photoUrl = '',
    this.createdAt,
  });

  // Safely read String values from Firestore.
  static String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    return value is String ? value : fallback;
  }

  // Safely convert Firestore Timestamp into DateTime.
  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // Convert Firestore data into UserModel.
  factory UserModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return UserModel(
      id: id,
      name: _readString(map['name']),
      email: _readString(map['email']),
      userType: _readString(
        map['user_type'],
        fallback: 'pending',
      ),
      status: _readString(
        map['status'],
        fallback: 'active',
      ),
      phone: _readString(map['phone']),
      photoUrl: _readString(map['photo_url']),
      createdAt: _readDate(map['created_at']),
    );
  }

  // Data for updating an existing user profile.
  Map<String, dynamic> toProfileUpdateMap() {
    return {
      'name': name,
      'phone': phone,
      'photo_url': photoUrl,
    };
  }
}
