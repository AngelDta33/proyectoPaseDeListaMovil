class SubjectModel {
  final String id;
  final String name;
  final String semesterGroup;
  final String teacherId;
  final String schoolId;
  final List<String> studentIds;

  SubjectModel({
    required this.id,
    required this.name,
    required this.semesterGroup,
    required this.teacherId,
    required this.schoolId,
    this.studentIds = const [],
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map, String id) {
    return SubjectModel(
      id: id,
      name: map['name'] ?? '',
      semesterGroup: map['semesterGroup'] ?? '',
      teacherId: map['teacherId'] ?? '',
      schoolId: map['schoolId'] ?? '',
      studentIds: List<String>.from(map['studentIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'semesterGroup': semesterGroup,
      'teacherId': teacherId,
      'schoolId': schoolId,
      'studentIds': studentIds,
    };
  }
}
