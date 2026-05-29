class GroupModel {
  final String id;
  final String name;
  final String teacherId;
  final String schoolId;

  GroupModel({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.schoolId,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      id: id,
      name: map['name'] ?? '',
      teacherId: map['teacherId'] ?? '',
      schoolId: map['schoolId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'teacherId': teacherId,
      'schoolId': schoolId,
    };
  }
}
