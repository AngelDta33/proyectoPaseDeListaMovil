import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject_model.dart';

class SubjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addSubject(SubjectModel subject) async {
    await _db.collection('subjects').doc(subject.id).set(subject.toMap());
  }

  Future<void> deleteSubject(String subjectId) async {
    await _db.collection('subjects').doc(subjectId).delete();
  }

  Future<void> setEnrolledStudents(
      String subjectId, List<String> studentIds) async {
    await _db
        .collection('subjects')
        .doc(subjectId)
        .update({'studentIds': studentIds});
  }

  Stream<List<SubjectModel>> getSubjectsByTeacher(String teacherId) {
    return _db
        .collection('subjects')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SubjectModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<SubjectModel>> getSubjectsByStudentId(String studentId) {
    return _db
        .collection('subjects')
        .where('studentIds', arrayContains: studentId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SubjectModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<SubjectModel>> getAllSubjects() {
    return _db
        .collection('subjects')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SubjectModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<SubjectModel>> getSubjectsBySchool(String schoolId) {
    return _db
        .collection('subjects')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SubjectModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
