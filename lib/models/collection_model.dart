
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionModel {
  final String id;
  final String requestId;
  final String donationId;
  final String donorId;
  final String receiverId;
  final String volunteerId;
  final String status;
  final DateTime? pickupTime;
  final DateTime? deliveryTime;
  final DateTime? createdAt;

  const CollectionModel({
    this.id = '',
    required this.requestId,
    required this.donationId,
    required this.donorId,
    required this.receiverId,
    this.volunteerId = '',
    this.status = 'assigned',
    this.pickupTime,
    this.deliveryTime,
    this.createdAt,
  });

  // Safely read String values.
  static String _readString(
    dynamic value, [
    String fallback = '',
  ]) {
    return value is String ? value : fallback;
  }

  // Safely read DateTime values.
  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // Convert Firestore data into CollectionModel.
  factory CollectionModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return CollectionModel(
      id: id,
      requestId: _readString(map['request_id']),
      donationId: _readString(map['donation_id']),
      donorId: _readString(map['donor_id']),
      receiverId: _readString(map['receiver_id']),
      volunteerId: _readString(map['volunteer_id']),
      status: _readString(map['status'], 'assigned'),
      pickupTime: _readDate(map['pickup_time']),
      deliveryTime: _readDate(map['delivery_time']),
      createdAt: _readDate(map['created_at']),
    );
  }

  // Convert CollectionModel into Firestore data.
  Map<String, dynamic> toMap() {
    return {
      'request_id': requestId,
      'donation_id': donationId,
      'donor_id': donorId,
      'receiver_id': receiverId,
      'volunteer_id': volunteerId,
      'status': status,
      'pickup_time': pickupTime != null
          ? Timestamp.fromDate(pickupTime!)
          : null,
      'delivery_time': deliveryTime != null
          ? Timestamp.fromDate(deliveryTime!)
          : null,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
