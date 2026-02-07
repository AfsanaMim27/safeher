import 'package:cloud_firestore/cloud_firestore.dart';

class SosAlert {
  final String id;
  final String userId;
  final Timestamp createdAt;
  final String status;

  SosAlert({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'createdAt': createdAt,
      'status': status,
    };
  }
}
