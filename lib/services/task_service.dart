import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addTask(TaskModel task) async {
    await _db.collection('tasks').doc(task.id).set(task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  Future<void> markAsSeen(String taskId, String studentId) async {
    await _db.collection('tasks').doc(taskId).update({
      'seenBy': FieldValue.arrayUnion([studentId]),
    });
  }

  // Tareas de grupo para una materia (maestro y alumno)
  Stream<List<TaskModel>> getGroupTasksBySubject(String subjectId) {
    return _db
        .collection('tasks')
        .where('subjectId', isEqualTo: subjectId)
        .where('scope', isEqualTo: 'group')
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.assignedDate.compareTo(a.assignedDate)); // descending
      return list;
    });
  }

  // Tareas individuales para un alumno en una materia (maestro)
  Stream<List<TaskModel>> getIndividualTasksForStudent(
      String studentId, String subjectId) {
    return _db
        .collection('tasks')
        .where('studentId', isEqualTo: studentId)
        .where('subjectId', isEqualTo: subjectId)
        .where('scope', isEqualTo: 'individual')
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.assignedDate.compareTo(a.assignedDate)); // descending
      return list;
    });
  }

  // Todas las tareas para una materia (vista del maestro)
  Stream<List<TaskModel>> getAllTasksBySubject(String subjectId) {
    return _db
        .collection('tasks')
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.assignedDate.compareTo(a.assignedDate)); // descending
      return list;
    });
  }

  Future<void> setGrade(String taskId, String studentId, String grade) async {
    await _db.collection('tasks').doc(taskId).update({
      'grades.$studentId': grade,
    });
  }

  Future<void> removeGrade(String taskId, String studentId) async {
    await _db.collection('tasks').doc(taskId).update({
      'grades.$studentId': FieldValue.delete(),
    });
  }

  // Todas las tareas visibles para un alumno (individuales + grupo de sus materias)
  Future<List<TaskModel>> getTasksForStudent(
      String studentId, List<String> subjectIds) async {
    if (subjectIds.isEmpty) return [];

    final futures = <Future<List<TaskModel>>>[];

    // Tareas individuales
    futures.add(_db
        .collection('tasks')
        .where('studentId', isEqualTo: studentId)
        .where('scope', isEqualTo: 'individual')
        .get()
        .then((s) =>
            s.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList()));

    // Tareas de grupo por materia (Firestore limita arrayContains a 1 valor por query)
    for (final subjectId in subjectIds) {
      futures.add(_db
          .collection('tasks')
          .where('subjectId', isEqualTo: subjectId)
          .where('scope', isEqualTo: 'group')
          .get()
          .then((s) =>
              s.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList()));
    }

    final results = await Future.wait(futures);
    final all = results.expand((l) => l).toList();
    // Deduplicar por id
    final seen = <String>{};
    return all.where((t) => seen.add(t.id)).toList()
      ..sort((a, b) => b.assignedDate.compareTo(a.assignedDate));
  }
}
