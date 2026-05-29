import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String subjectId;
  final String teacherId;
  final DateTime date;
  final bool present;
  final String schoolId;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subjectId,
    required this.teacherId,
    required this.date,
    required this.present,
    required this.schoolId,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      subjectId: map['subjectId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      present: map['present'] ?? false,
      schoolId: map['schoolId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'date': date,
      'present': present,
      'schoolId': schoolId,
    };
  }
}
