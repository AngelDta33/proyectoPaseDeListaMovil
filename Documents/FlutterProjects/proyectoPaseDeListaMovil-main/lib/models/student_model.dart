class StudentModel {
  final String id;
  final String name;
  final String semesterGroup;
  final String? controlNumber;
  final String? career;
  final String teacherId;
  final String schoolId;
  final String? nfcUid;
  final String? inviteCode;
  final String? studentAuthUid;

  StudentModel({
    required this.id,
    required this.name,
    required this.semesterGroup,
    this.controlNumber,
    this.career,
    required this.teacherId,
    required this.schoolId,
    this.nfcUid,
    this.inviteCode,
    this.studentAuthUid,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map, String id) {
    return StudentModel(
      id: id,
      name: map['name'] ?? '',
      semesterGroup: map['semesterGroup'] ?? '',
      controlNumber: map['controlNumber'],
      career: map['career'],
      teacherId: map['teacherId'] ?? '',
      schoolId: map['schoolId'] ?? '',
      nfcUid: map['nfcUid'],
      inviteCode: map['inviteCode'],
      studentAuthUid: map['studentAuthUid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'semesterGroup': semesterGroup,
      'controlNumber': controlNumber,
      'career': career,
      'teacherId': teacherId,
      'schoolId': schoolId,
      if (nfcUid != null) 'nfcUid': nfcUid,
      if (inviteCode != null) 'inviteCode': inviteCode,
      if (studentAuthUid != null) 'studentAuthUid': studentAuthUid,
    };
  }
}
