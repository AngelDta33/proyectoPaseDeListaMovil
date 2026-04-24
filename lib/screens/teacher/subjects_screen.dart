import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../../models/subject_model.dart';
import '../../services/subject_service.dart';
import 'scanner_screen.dart';
import 'nfc_scanner_screen.dart';
import 'enroll_students_screen.dart';
import 'subject_detail_screen.dart';
import 'attendance_report_screen.dart';

class SubjectsScreen extends StatelessWidget {
  final UserModel user;
  const SubjectsScreen({super.key, required this.user});

  void _showAddSubjectDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final semesterCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva Asignatura'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre de la materia *',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: semesterCtrl,
                decoration: const InputDecoration(
                    labelText: 'Semestre/Grupo *',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final subject = SubjectModel(
                id: const Uuid().v4(),
                name: nameCtrl.text.trim(),
                semesterGroup: semesterCtrl.text.trim(),
                teacherId: user.uid,
                schoolId: user.schoolId ?? '',
              );
              await SubjectService().addSubject(subject);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Asignaturas'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva asignatura'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<SubjectModel>>(
        stream: SubjectService().getSubjectsByTeacher(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final subjects = snapshot.data ?? [];
          if (subjects.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tienes asignaturas registradas',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 80),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Ícono materia
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.book_outlined,
                            color: Color(0xFF1565C0), size: 22),
                      ),
                      const SizedBox(width: 12),
                      // Nombre y grupo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subject.semesterGroup,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                            if (subject.studentIds.isNotEmpty)
                              Text(
                                '${subject.studentIds.length} alumno${subject.studentIds.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                    color: Color(0xFF6A1B9A),
                                    fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      // Pasar lista QR
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner,
                            color: Color(0xFF1565C0)),
                        tooltip: 'Lista QR',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScannerScreen(
                                subject: subject,
                                teacherId: user.uid),
                          ),
                        ),
                      ),
                      // Pasar lista NFC
                      IconButton(
                        icon: const Icon(Icons.nfc,
                            color: Color(0xFF00838F)),
                        tooltip: 'Lista NFC',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NfcScannerScreen(
                                subject: subject,
                                teacherId: user.uid),
                          ),
                        ),
                      ),
                      // Menú más opciones
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: Colors.grey),
                        onSelected: (value) async {
                          switch (value) {
                            case 'alumnos':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EnrollStudentsScreen(
                                      subject: subject,
                                      teacherId: user.uid),
                                ),
                              );
                              break;
                            case 'tareas':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SubjectDetailScreen(
                                      subject: subject,
                                      teacherId: user.uid),
                                ),
                              );
                              break;
                            case 'reporte':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AttendanceReportScreen(
                                      subject: subject),
                                ),
                              );
                              break;
                            case 'eliminar':
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title:
                                      const Text('Eliminar asignatura'),
                                  content: Text(
                                      '¿Eliminar "${subject.name}"?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(
                                            context, false),
                                        child: const Text('Cancelar')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(
                                          context, true),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      child: const Text('Eliminar',
                                          style: TextStyle(
                                              color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await SubjectService()
                                    .deleteSubject(subject.id);
                              }
                              break;
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'alumnos',
                            child: ListTile(
                              leading: Icon(Icons.people,
                                  color: Color(0xFF6A1B9A)),
                              title: Text('Alumnos inscritos'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'tareas',
                            child: ListTile(
                              leading: Icon(Icons.assignment_outlined,
                                  color: Color(0xFF6A1B9A)),
                              title: Text('Tareas y comentarios'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'reporte',
                            child: ListTile(
                              leading: Icon(Icons.bar_chart,
                                  color: Color(0xFF2E7D32)),
                              title: Text('Ver reporte'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'eliminar',
                            child: ListTile(
                              leading:
                                  Icon(Icons.delete, color: Colors.red),
                              title: Text('Eliminar',
                                  style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}