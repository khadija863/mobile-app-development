
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String id;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String action;
  final String description;
  final String relatedId;
  final DateTime? createdAt;

  const ActivityLogModel({
    this.id = '',
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.description,
    required this.relatedId,
    this.createdAt,
  });

  factory ActivityLogModel.fromMap(
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

    return ActivityLogModel(
      id: id,
      actorId: map['actor_id']?.toString() ?? '',
      actorName: map['actor_name']?.toString() ?? '',
      actorRole: map['actor_role']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      relatedId: map['related_id']?.toString() ?? '',
      createdAt: date,
    );
  }
}
