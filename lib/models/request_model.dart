
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String donationId;
  final String donorId;
  final String requesterId;
  final String requesterRole;
  final String requesterName;
  final String message;
  final String volunteerId;
  final String status;
  final DateTime? requestTime;
  final DateTime? updatedAt;

  const RequestModel({
    this.id = '',
    required this.donationId,
    required this.donorId,
    required this.requesterId,
    required this.requesterRole,
    required this.requesterName,
    this.message = '',
    this.volunteerId = '',
    this.status = 'pending',
    this.requestTime,
    this.updatedAt,
  });

  // Safely read String values from Firestore.
  static String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value is String) {
      return value;
    }

    return fallback;
  }

  // Safely read DateTime values from Firestore.
  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // Convert Firestore data into RequestModel.
  factory RequestModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return RequestModel(
      id: id,
      donationId: _readString(map['donation_id']),
      donorId: _readString(map['donor_id']),
      requesterId: _readString(map['requester_id']),
      requesterRole: _readString(map['requester_role']),
      requesterName: _readString(map['requester_name']),
      message: _readString(map['message']),
      volunteerId: _readString(map['volunteer_id']),
      status: _readString(
        map['status'],
        fallback: 'pending',
      ),
      requestTime: _readDate(map['request_time']),
      updatedAt: _readDate(map['updated_at']),
    );
  }

  // Convert RequestModel into Firestore data.
  Map<String, dynamic> toMap() {
    return {
      'donation_id': donationId,
      'donor_id': donorId,
      'requester_id': requesterId,
      'requester_role': requesterRole,
      'requester_name': requesterName,
      'message': message,
      'volunteer_id': volunteerId,
      'status': status,
      'request_time': requestTime != null
          ? Timestamp.fromDate(requestTime!)
          : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
