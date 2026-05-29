import 'package:cloud_firestore/cloud_firestore.dart';

/// Crea un documento de configuración en la colección _app_config
/// para que las colecciones reales (students, subjects, attendance, users)
/// aparezcan en la consola de Firebase sin contaminar datos reales.
///
/// IMPORTANTE: Se llama DESPUÉS de que el usuario se autentica,
/// porque las reglas de Firestore requieren request.auth != null.
///
/// Las colecciones reales NO necesitan pre-crearse: Firestore las
/// genera automáticamente cuando se escribe el primer documento real.
class FirestoreInitService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initCollections() async {
    try {
      final ref = _db.collection('_app_config').doc('metadata');
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'appName': 'Control de Asistencia QR',
          'collections': ['users', 'students', 'subjects', 'attendance', 'schools'],
          'initializedAt': FieldValue.serverTimestamp(),
          'version': '1.0.0',
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('[FirestoreInit] Error al inicializar config: $e');
    }
  }
}
