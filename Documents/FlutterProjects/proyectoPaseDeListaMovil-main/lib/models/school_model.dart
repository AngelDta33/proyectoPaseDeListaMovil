import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolModel {
  final String id;
  final String name;
  final String directorId;
  final String inviteCode;
  final List<String> teacherIds;
  final DateTime createdAt;

  SchoolModel({
    required this.id,
    required this.name,
    required this.directorId,
    required this.inviteCode,
    required this.teacherIds,
    required this.createdAt,
  });

  factory SchoolModel.fromMap(Map<String, dynamic> map, String id) {
    return SchoolModel(
      id: id,
      name: map['name'] ?? '',
      directorId: map['directorId'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      teacherIds: List<String>.from(map['teacherIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'directorId': directorId,
      'inviteCode': inviteCode,
      'teacherIds': teacherIds,
      'createdAt': createdAt,
    };
  }
}
