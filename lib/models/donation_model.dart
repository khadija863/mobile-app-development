
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationModel {
  final String id;
  final String donorId;
  final String donorName;
  final String title;
  final String description;
  final String foodType;
  final String quantity;
  final String imageUrl;
  final GeoPoint? pickupLocation;
  final String pickupAddress;
  final DateTime expiryTime;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DonationModel({
    this.id = '',
    required this.donorId,
    required this.donorName,
    required this.title,
    required this.description,
    required this.foodType,
    required this.quantity,
    this.imageUrl = '',
    this.pickupLocation,
    required this.pickupAddress,
    required this.expiryTime,
    this.status = 'available',
    this.createdAt,
    this.updatedAt,
  });

  static DateTime? _getDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  factory DonationModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return DonationModel(
      id: id,
      donorId: map['donor_id']?.toString() ?? '',
      donorName: map['donor_name']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      foodType: map['food_type']?.toString() ?? '',
      quantity: map['quantity']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      pickupLocation: map['pickup_location'] is GeoPoint
          ? map['pickup_location'] as GeoPoint
          : null,
      pickupAddress: map['pickup_address']?.toString() ?? '',
      expiryTime: _getDate(map['expiry_time']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: map['status']?.toString() ?? 'available',
      createdAt: _getDate(map['created_at']),
      updatedAt: _getDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'donor_id': donorId,
      'donor_name': donorName,
      'title': title,
      'description': description,
      'food_type': foodType,
      'quantity': quantity,
      'image_url': imageUrl,
      if (pickupLocation != null)
        'pickup_location': pickupLocation,
      'pickup_address': pickupAddress,
      'expiry_time': Timestamp.fromDate(expiryTime),
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'food_type': foodType,
      'quantity': quantity,
      'image_url': imageUrl,

      // Null হলে আগের location মুছে যাবে।
      'pickup_location': pickupLocation,

      'pickup_address': pickupAddress,
      'expiry_time': Timestamp.fromDate(expiryTime),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
