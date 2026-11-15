
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String recipientRole;
  final String title;
  final String message;
  final String type;
  final String relatedId;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    this.id = '',
    required this.userId,
    this.recipientRole = '',
    required this.title,
    required this.message,
    required this.type,
    this.relatedId = '',
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final value = map['created_at'];

    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    return NotificationModel(
      id: id,
      userId: map['user_id']?.toString() ?? '',
      recipientRole: map['recipient_role']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      relatedId: map['related_id']?.toString() ?? '',
      isRead: map['is_read'] == true,
      createdAt: date,
    );
  }
}
