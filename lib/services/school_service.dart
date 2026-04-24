import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/school_model.dart';
import '../models/user_model.dart';

class SchoolService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Genera un código de invitación de 6 caracteres alfanumérico en mayúsculas
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    var code = '';
    var seed = rand;
    for (var i = 0; i < 6; i++) {
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
      code += chars[seed % chars.length];
    }
    return code;
  }

  /// Crea una nueva escuela y devuelve el modelo creado
  Future<SchoolModel> createSchool(String name, String directorId) async {
    final id = const Uuid().v4();
    final code = _generateInviteCode();
    final school = SchoolModel(
      id: id,
      name: name,
      directorId: directorId,
      inviteCode: code,
      teacherIds: [],
      createdAt: DateTime.now(),
    );
    await _db.collection('schools').doc(id).set(school.toMap());
    // Actualiza el schoolId del director en users
    await _db.collection('users').doc(directorId).update({'schoolId': id});
    return school;
  }

  /// Busca una escuela por código de invitación
  Future<SchoolModel?> getSchoolByInviteCode(String code) async {
    final snap = await _db
        .collection('schools')
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return SchoolModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  /// Agrega un maestro a la escuela y actualiza su schoolId
  Future<void> joinSchool(String schoolId, String teacherId) async {
    await _db.collection('schools').doc(schoolId).update({
      'teacherIds': FieldValue.arrayUnion([teacherId]),
    });
    await _db.collection('users').doc(teacherId).update({'schoolId': schoolId});
  }

  /// Obtiene la escuela de un director
  Future<SchoolModel?> getSchoolByDirector(String directorId) async {
    final snap = await _db
        .collection('schools')
        .where('directorId', isEqualTo: directorId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return SchoolModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  /// Obtiene la escuela por ID
  Future<SchoolModel?> getSchoolById(String schoolId) async {
    final doc = await _db.collection('schools').doc(schoolId).get();
    if (!doc.exists) return null;
    return SchoolModel.fromMap(doc.data()!, doc.id);
  }

  /// Stream de maestros de una escuela (devuelve sus UserModel)
  Stream<List<UserModel>> getTeachersStream(String schoolId) {
    return _db
        .collection('users')
        .where('schoolId', isEqualTo: schoolId)
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
