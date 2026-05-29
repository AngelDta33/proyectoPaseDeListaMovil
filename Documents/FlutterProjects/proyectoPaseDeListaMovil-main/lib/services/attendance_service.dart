import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registerAttendance(AttendanceModel attendance) async {
    await _db
        .collection('attendance')
        .doc(attendance.id)
        .set(attendance.toMap());
  }

  Stream<List<AttendanceModel>> getAttendanceBySubject(String subjectId) {
    return _db
        .collection('attendance')
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date)); // descending
      return list;
    });
  }

  Future<List<AttendanceModel>> getAttendanceBySubjectOnce(
      String subjectId) async {
    final snap = await _db
        .collection('attendance')
        .where('subjectId', isEqualTo: subjectId)
        .get();
    final list = snap.docs
        .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => a.date.compareTo(b.date)); // ascending
    return list;
  }

  Future<List<AttendanceModel>> getAttendanceByStudent(
      String studentId) async {
    final snap = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .get();
    final list = snap.docs
        .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => a.date.compareTo(b.date)); // ascending
    return list;
  }

  Future<List<AttendanceModel>> getAttendanceByStudentAndSubject(
      String studentId, String subjectId) async {
    final snap = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .where('subjectId', isEqualTo: subjectId)
        .get();
    final list = snap.docs
        .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => a.date.compareTo(b.date)); // ascending
    return list;
  }

  Future<bool> alreadyScannedToday(
      String studentId, String subjectId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Solo dos filtros para evitar índice compuesto — la fecha se filtra en Dart
    final snap = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .where('subjectId', isEqualTo: subjectId)
        .get();

    return snap.docs.any((doc) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final day = DateTime(date.year, date.month, date.day);
      return day == today;
    });
  }
}
