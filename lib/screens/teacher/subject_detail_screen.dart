import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/subject_model.dart';
import '../../models/student_model.dart';
import '../../models/task_model.dart';
import '../../services/student_service.dart';
import '../../services/task_service.dart';
import 'assign_task_screen.dart';

class SubjectDetailScreen extends StatelessWidget {
  final SubjectModel subject;
  final String teacherId;
  const SubjectDetailScreen(
      {super.key, required this.subject, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(subject.name),
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Alumnos'),
              Tab(icon: Icon(Icons.assignment), text: 'Tareas del grupo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StudentsTab(subject: subject, teacherId: teacherId),
            _GroupTasksTab(subject: subject, teacherId: teacherId),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Alumnos ───────────────────────────────────────────────────────────
class _StudentsTab extends StatelessWidget {
  final SubjectModel subject;
  final String teacherId;
  const _StudentsTab(
      {required this.subject, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    if (subject.studentIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No hay alumnos inscritos en esta materia.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Inscríbelos desde el ícono 👥 en Mis Asignaturas.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return FutureBuilder<List<StudentModel?>>(
      future: Future.wait(
          subject.studentIds.map((id) => StudentService().getStudentById(id))),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final students =
            snap.data?.whereType<StudentModel>().toList() ?? [];

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: students.length,
          itemBuilder: (context, i) {
            final student = students[i];
            return StreamBuilder<List<TaskModel>>(
              stream: TaskService()
                  .getIndividualTasksForStudent(student.id, subject.id),
              builder: (context, taskSnap) {
                final pendingCount = taskSnap.data
                        ?.where((t) => !t.seenBy.contains(student.id))
                        .length ??
                    0;
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          const Color(0xFF6A1B9A).withOpacity(0.15),
                      child: Text(
                        student.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: Color(0xFF6A1B9A),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(student.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(student.semesterGroup),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pendingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$pendingCount sin ver',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.add_comment_outlined,
                              color: Color(0xFF6A1B9A)),
                          tooltip: 'Asignar tarea/comentario',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssignTaskScreen(
                                subject: subject,
                                teacherId: teacherId,
                                student: student,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _showStudentTasks(context, student),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showStudentTasks(BuildContext context, StudentModel student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tareas de ${student.name}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<TaskModel>>(
                  stream: TaskService()
                      .getIndividualTasksForStudent(student.id, subject.id),
                  builder: (context, snap) {
                    final tasks = snap.data ?? [];
                    if (tasks.isEmpty) {
                      return const Center(
                          child: Text('Sin tareas individuales aún.',
                              style: TextStyle(color: Colors.grey)));
                    }
                    return ListView.builder(
                      controller: ctrl,
                      itemCount: tasks.length,
                      itemBuilder: (context, i) =>
                          _TaskTile(task: tasks[i], student: student),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  final StudentModel student;
  const _TaskTile({required this.task, required this.student});

  Future<void> _showGradeDialog(BuildContext context) async {
    final currentGrade = task.grades[student.id];
    final gradeCtrl = TextEditingController(text: currentGrade ?? '');

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Calificación — ${student.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(task.title,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: gradeCtrl,
              decoration: const InputDecoration(
                labelText: 'Calificación',
                hintText: 'Ej: 9.5, Aprobado, B+',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          if (currentGrade != null)
            TextButton(
              onPressed: () async {
                await TaskService().removeGrade(task.id, student.id);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Quitar', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final grade = gradeCtrl.text.trim();
              if (grade.isNotEmpty) {
                await TaskService().setGrade(task.id, student.id, grade);
              }
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
    final seen = task.seenBy.contains(student.id);
    final grade = task.grades[student.id];
    final color = _taskColor(task.type);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(_taskIcon(task.type), color: Colors.white, size: 18),
        ),
        title: Text(task.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(task.description!),
            if (task.dueDate != null)
              Text(
                  'Entrega: ${DateFormat('dd/MM/yyyy').format(task.dueDate!)}',
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            Row(
              children: [
                Text(
                  seen ? '✓ Visto' : 'Sin ver',
                  style: TextStyle(
                      color: seen ? Colors.green : Colors.orange,
                      fontSize: 12),
                ),
                if (grade != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      grade,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.grade_outlined,
                color: grade != null ? Colors.green : Colors.grey,
                size: 20,
              ),
              tooltip: grade != null ? 'Editar calificación' : 'Calificar',
              onPressed: () => _showGradeDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Eliminar tarea'),
                    content: Text('¿Eliminar "${task.title}"?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Eliminar',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (ok == true) await TaskService().deleteTask(task.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Tareas del grupo ──────────────────────────────────────────────────
class _GroupTasksTab extends StatelessWidget {
  final SubjectModel subject;
  final String teacherId;
  const _GroupTasksTab(
      {required this.subject, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssignTaskScreen(
              subject: subject,
              teacherId: teacherId,
            ),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea al grupo'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: TaskService().getGroupTasksBySubject(subject.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snap.data ?? [];
          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Sin tareas asignadas al grupo.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 100),
            itemCount: tasks.length,
            itemBuilder: (context, i) {
              final task = tasks[i];
              final seenCount = task.seenBy.length;
              final total = subject.studentIds.length;
              final color = _taskColor(task.type);
              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Icon(_taskIcon(task.type),
                        color: Colors.white, size: 18),
                  ),
                  title: Text(task.title,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.description != null &&
                          task.description!.isNotEmpty)
                        Text(task.description!),
                      if (task.dueDate != null)
                        Text(
                          'Entrega: ${DateFormat('dd/MM/yyyy').format(task.dueDate!)}',
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12),
                        ),
                      Text('$seenCount/$total alumnos lo vieron',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete,
                        color: Colors.red, size: 20),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Eliminar tarea'),
                          content: Text('¿Eliminar "${task.title}"?'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancelar')),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text('Eliminar',
                                  style:
                                      TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await TaskService().deleteTask(task.id);
                      }
                    },
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

Color _taskColor(String type) {
  switch (type) {
    case 'examen':
      return Colors.red;
    case 'comentario':
      return const Color(0xFF1565C0);
    case 'aviso':
      return Colors.orange;
    default:
      return const Color(0xFF6A1B9A);
  }
}

IconData _taskIcon(String type) {
  switch (type) {
    case 'examen':
      return Icons.quiz_outlined;
    case 'comentario':
      return Icons.comment_outlined;
    case 'aviso':
      return Icons.notifications_outlined;
    default:
      return Icons.assignment_outlined;
  }
}
