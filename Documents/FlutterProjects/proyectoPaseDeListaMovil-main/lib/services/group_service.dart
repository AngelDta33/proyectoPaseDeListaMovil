import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addGroup(GroupModel group) async {
    await _db.collection('groups').doc(group.id).set(group.toMap());
  }

  Future<void> deleteGroup(String groupId) async {
    await _db.collection('groups').doc(groupId).delete();
  }

  Future<void> updateGroup(String groupId, String newName) async {
    await _db.collection('groups').doc(groupId).update({'name': newName});
  }

  Stream<List<GroupModel>> getGroupsByTeacher(String teacherId) {
    return _db
        .collection('groups')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => GroupModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  String generateGroupId() => const Uuid().v4();
}
