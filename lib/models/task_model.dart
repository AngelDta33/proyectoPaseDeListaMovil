import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String type; // 'tarea', 'examen', 'comentario', 'aviso'
  final String scope; // 'individual', 'group'
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String schoolId;
  final String? studentId; // solo scope='individual'
  final DateTime assignedDate;
  final DateTime? dueDate;
  final List<String> seenBy; // studentIds que ya lo vieron
  final Map<String, String> grades; // {studentId: "calificacion"}

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.scope,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.schoolId,
    this.studentId,
    required this.assignedDate,
    this.dueDate,
    this.seenBy = const [],
    this.grades = const {},
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      type: map['type'] ?? 'tarea',
      scope: map['scope'] ?? 'group',
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      teacherId: map['teacherId'] ?? '',
      schoolId: map['schoolId'] ?? '',
      studentId: map['studentId'],
      assignedDate: (map['assignedDate'] as Timestamp).toDate(),
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      seenBy: List<String>.from(map['seenBy'] ?? []),
      grades: Map<String, String>.from(map['grades'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'scope': scope,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'schoolId': schoolId,
      if (studentId != null) 'studentId': studentId,
      'assignedDate': Timestamp.fromDate(assignedDate),
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      'seenBy': seenBy,
      'grades': grades,
    };
  }
}
