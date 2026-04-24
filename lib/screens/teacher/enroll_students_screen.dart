import 'package:flutter/material.dart';
import '../../models/subject_model.dart';
import '../../models/student_model.dart';
import '../../services/student_service.dart';
import '../../services/subject_service.dart';

class EnrollStudentsScreen extends StatefulWidget {
  final SubjectModel subject;
  final String teacherId;
  const EnrollStudentsScreen(
      {super.key, required this.subject, required this.teacherId});

  @override
  State<EnrollStudentsScreen> createState() => _EnrollStudentsScreenState();
}

class _EnrollStudentsScreenState extends State<EnrollStudentsScreen> {
  late Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.subject.studentIds);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SubjectService()
          .setEnrolledStudents(widget.subject.id, _selected.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lista de alumnos guardada'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alumnos: ${widget.subject.name}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save, color: Colors.white),
            label: const Text('Guardar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<List<StudentModel>>(
        stream: StudentService().getStudentsByTeacher(widget.teacherId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tienes alumnos registrados aún.',
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Agrégalos desde "Mis Alumnos".',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Ordenar: inscritos primero
          final sorted = [...students]..sort((a, b) {
              final aIn = _selected.contains(a.id) ? 0 : 1;
              final bIn = _selected.contains(b.id) ? 0 : 1;
              return aIn.compareTo(bIn);
            });

          return Column(
            children: [
              // Resumen
              Container(
                margin: const EdgeInsets.all(16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selected.length} de ${students.length} inscritos',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0)),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => setState(
                              () => _selected = students.map((s) => s.id).toSet()),
                          child: const Text('Todos'),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selected = {}),
                          child: const Text('Ninguno',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final student = sorted[index];
                    final enrolled = _selected.contains(student.id);
                    return CheckboxListTile(
                      value: enrolled,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selected.add(student.id);
                          } else {
                            _selected.remove(student.id);
                          }
                        });
                      },
                      title: Text(student.name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle:
                          Text('Semestre/Grupo: ${student.semesterGroup}'),
                      secondary: CircleAvatar(
                        backgroundColor: enrolled
                            ? const Color(0xFF1565C0)
                            : Colors.grey.shade300,
                        child: Text(
                          student.name[0].toUpperCase(),
                          style: TextStyle(
                              color: enrolled ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      activeColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
