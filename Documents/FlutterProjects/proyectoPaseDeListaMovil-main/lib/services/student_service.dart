import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class StudentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    var seed = DateTime.now().microsecondsSinceEpoch;
    var code = '';
    for (var i = 0; i < 6; i++) {
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
      code += chars[seed % chars.length];
    }
    return code;
  }

  Future<void> addStudent(StudentModel student) async {
    await _db.collection('students').doc(student.id).set(student.toMap());
  }

  Future<void> updateStudent(StudentModel student) async {
    await _db.collection('students').doc(student.id).update(student.toMap());
  }

  Future<void> deleteStudent(String studentId) async {
    await _db.collection('students').doc(studentId).delete();
  }

  Stream<List<StudentModel>> getStudentsByTeacher(String teacherId) {
    return _db
        .collection('students')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<StudentModel?> getStudentById(String studentId) async {
    final doc = await _db.collection('students').doc(studentId).get();
    if (!doc.exists) return null;
    return StudentModel.fromMap(doc.data()!, doc.id);
  }

  Future<StudentModel?> getStudentByNfcUid(String nfcUid) async {
    final snap = await _db
        .collection('students')
        .where('nfcUid', isEqualTo: nfcUid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return StudentModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  Future<StudentModel?> getStudentByInviteCode(String code) async {
    final snap = await _db
        .collection('students')
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return StudentModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  Future<StudentModel?> getStudentByAuthUid(String authUid) async {
    final snap = await _db
        .collection('students')
        .where('studentAuthUid', isEqualTo: authUid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return StudentModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  Future<void> linkNfc(String studentId, String nfcUid) async {
    await _db.collection('students').doc(studentId).update({'nfcUid': nfcUid});
  }

  Future<void> unlinkNfc(String studentId) async {
    await _db.collection('students').doc(studentId).update({'nfcUid': null});
  }

  Future<void> linkAuthUid(String studentId, String authUid) async {
    await _db
        .collection('students')
        .doc(studentId)
        .update({'studentAuthUid': authUid});
  }

  Future<void> regenerateInviteCode(String studentId) async {
    await _db.collection('students').doc(studentId).update({
      'inviteCode': generateInviteCode(),
    });
  }

  Stream<List<StudentModel>> getAllStudents() {
    return _db
        .collection('students')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<StudentModel>> getStudentsBySchool(String schoolId) {
    return _db
        .collection('students')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
