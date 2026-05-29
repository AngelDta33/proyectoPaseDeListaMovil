import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firestore_init_service.dart';
import 'school_service.dart';
import 'student_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, user.uid);
  }

  Future<UserModel?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _db.collection('users').doc(result.user!.uid).get();
    if (!doc.exists) return null;
    // Inicializa colecciones en Firestore ahora que el usuario está autenticado
    await FirestoreInitService().initCollections();
    return UserModel.fromMap(doc.data()!, result.user!.uid);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> createUser(
      String email, String password, String name, String role) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = UserModel(
      uid: result.user!.uid,
      name: name,
      email: email,
      role: role,
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
    await FirestoreInitService().initCollections();
    return user;
  }

  /// Registra un alumno usando su código de invitación.
  Future<UserModel?> registerStudent(
      String email, String password, String inviteCode) async {
    final student = await StudentService().getStudentByInviteCode(inviteCode);
    if (student == null) throw Exception('Código de invitación no válido.');
    if (student.studentAuthUid != null) {
      throw Exception('Este código ya fue usado. Pide uno nuevo a tu maestro.');
    }
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = result.user!.uid;
    final user = UserModel(
      uid: uid,
      name: student.name,
      email: email,
      role: 'student',
      schoolId: student.schoolId,
      studentId: student.id,
    );
    await _db.collection('users').doc(uid).set(user.toMap());
    await StudentService().linkAuthUid(student.id, uid);
    await FirestoreInitService().initCollections();
    return user;
  }

  /// Registra un maestro y crea automáticamente su salón propio.
  Future<UserModel?> createTeacherWithAutoSchool(
      String email, String password, String name) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = result.user!.uid;
    final user = UserModel(uid: uid, name: name, email: email, role: 'teacher');
    await _db.collection('users').doc(uid).set(user.toMap());
    await FirestoreInitService().initCollections();
    final school = await SchoolService().createSchool('Salón de $name', uid);
    return UserModel(
        uid: uid, name: name, email: email, role: 'teacher', schoolId: school.id);
  }
}