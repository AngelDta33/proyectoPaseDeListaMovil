class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'teacher', 'student'
  final String? schoolId;
  final String? studentId; // solo para role='student'

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.schoolId,
    this.studentId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'teacher',
      schoolId: map['schoolId'] as String?,
      studentId: map['studentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      if (schoolId != null) 'schoolId': schoolId,
      if (studentId != null) 'studentId': studentId,
    };
  }
}
