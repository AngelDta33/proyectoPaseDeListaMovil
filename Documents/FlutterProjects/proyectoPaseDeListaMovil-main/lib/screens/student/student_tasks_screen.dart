import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/student_model.dart';
import '../../models/subject_model.dart';
import '../../models/task_model.dart';
import '../../services/student_service.dart';
import '../../services/subject_service.dart';
import '../../services/task_service.dart';

class StudentTasksScreen extends StatefulWidget {
  final UserModel user;
  const StudentTasksScreen({super.key, required this.user});

  @override
  State<StudentTasksScreen> createState() => _StudentTasksScreenState();
}

class _StudentTasksScreenState extends State<StudentTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── Estado principal ──────────────────────────────────────────────────────
  StudentModel? _student;
  List<TaskModel> _tasks = [];
  bool _loadingStudent = true;
  bool _loadingTasks = true;
  String? _error;

  DateTime _weekStart = _mondayOf(DateTime.now());
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  StreamSubscription<List<SubjectModel>>? _subSub;

  static DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadStudent();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _subSub?.cancel();
    super.dispose();
  }

  // ── Carga estudiante ──────────────────────────────────────────────────────
  Future<void> _loadStudent() async {
    try {
      final sid = widget.user.studentId;
      final student = (sid != null && sid.isNotEmpty)
          ? await StudentService().getStudentById(sid)
          : await StudentService().getStudentByAuthUid(widget.user.uid);

      if (!mounted) return;
      if (student == null) {
        setState(() {
          _loadingStudent = false;
          _error = 'No se encontró tu perfil.\nContacta a tu maestro.';
        });
        return;
      }
      setState(() {
        _student = student;
        _loadingStudent = false;
      });
      _subscribeSubjects(student);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingStudent = false;
          _error = 'Error al cargar perfil:\n$e';
        });
      }
    }
  }

  // ── Suscribe materias y recarga tareas cuando cambian ─────────────────────
  void _subscribeSubjects(StudentModel student) {
    _subSub = SubjectService()
        .getSubjectsByStudentId(student.id)
        .listen((subjects) async {
      if (!mounted) return;
      final subjectIds = subjects.map((s) => s.id).toList();
      await _loadTasks(student.id, subjectIds);
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _loadingTasks = false;
          _error = 'Error al cargar materias:\n$e';
        });
      }
    });
  }

  // ── Carga tareas ──────────────────────────────────────────────────────────
  Future<void> _loadTasks(String studentId, List<String> subjectIds) async {
    setState(() => _loadingTasks = true);
    try {
      final tasks =
          await TaskService().getTasksForStudent(studentId, subjectIds);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loadingTasks = false;
      });
      // Marcar como vistas
      for (final t in tasks) {
        if (!t.seenBy.contains(studentId)) {
          TaskService().markAsSeen(t.id, studentId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingTasks = false;
        });
      }
    }
  }

  // ── Recarga manual ────────────────────────────────────────────────────────
  Future<void> _refresh() async {
    if (_student == null) return;
    final subjects = await SubjectService()
        .getSubjectsByStudentId(_student!.id)
        .first;
    if (!mounted) return;
    await _loadTasks(_student!.id, subjects.map((s) => s.id).toList());
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.view_week_outlined), text: 'Semana'),
            Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Mes'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingStudent) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (_loadingTasks) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      controller: _tabCtrl,
      children: [
        _WeekView(
          tasks: _tasks,
          weekStart: _weekStart,
          studentId: _student?.id ?? '',
          onPrev: () => setState(() => _weekStart =
              _weekStart.subtract(const Duration(days: 7))),
          onNext: () => setState(() =>
              _weekStart = _weekStart.add(const Duration(days: 7))),
        ),
        _MonthView(
          tasks: _tasks,
          month: _month,
          studentId: _student?.id ?? '',
          onPrev: () => setState(
              () => _month = DateTime(_month.year, _month.month - 1)),
          onNext: () => setState(
              () => _month = DateTime(_month.year, _month.month + 1)),
        ),
      ],
    );
  }
}

// ─── Vista Semana ──────────────────────────────────────────────────────────
class _WeekView extends StatelessWidget {
  final List<TaskModel> tasks;
  final DateTime weekStart;
  final String studentId;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _WeekView({
    required this.tasks,
    required this.weekStart,
    required this.studentId,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final days =
        List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final weekEnd = days.last;

    return Column(
      children: [
        // Navegación semana
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left), onPressed: onPrev),
              Text(
                '${DateFormat('d MMM', 'es').format(weekStart)} – '
                '${DateFormat('d MMM yyyy', 'es').format(weekEnd)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onNext),
            ],
          ),
        ),
        // Columnas de días
        Expanded(
          child: tasks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No hay tareas asignadas',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: days.map((day) {
                      final dayKey =
                          DateFormat('yyyy-MM-dd').format(day);
                      final dayTasks = tasks.where((t) {
                        final ref = t.dueDate ?? t.assignedDate;
                        return DateFormat('yyyy-MM-dd').format(ref) ==
                            dayKey;
                      }).toList();
                      final isToday = dayKey ==
                          DateFormat('yyyy-MM-dd').format(DateTime.now());

                      return Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 4),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? const Color(0xFF6A1B9A)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat('EEE', 'es')
                                        .format(day)
                                        .toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isToday
                                            ? Colors.white
                                            : Colors.grey),
                                  ),
                                  Text(
                                    '${day.day}',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isToday
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...dayTasks.map((t) =>
                                _TaskChip(task: t, studentId: studentId)),
                            if (dayTasks.isEmpty)
                              const SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text('—',
                                      style:
                                          TextStyle(color: Colors.grey)),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Vista Mes ─────────────────────────────────────────────────────────────
class _MonthView extends StatelessWidget {
  final List<TaskModel> tasks;
  final DateTime month;
  final String studentId;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthView({
    required this.tasks,
    required this.month,
    required this.studentId,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = (firstDay.weekday - 1) % 7;
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final allDays = <DateTime?>[];
    for (var i = 0; i < startOffset; i++) allDays.add(null);
    for (var d = 1; d <= daysInMonth; d++) {
      allDays.add(DateTime(month.year, month.month, d));
    }

    const headers = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Navegación mes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left), onPressed: onPrev),
              Text(
                DateFormat('MMMM yyyy', 'es').format(month),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onNext),
            ],
          ),
        ),
        // Encabezados
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: headers
                .map((h) => Expanded(
                      child: Center(
                        child: Text(h,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey)),
                      ),
                    ))
                .toList(),
          ),
        ),
        // Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: allDays.length,
            itemBuilder: (context, i) {
              final day = allDays[i];
              if (day == null) return const SizedBox();
              final dayKey = DateFormat('yyyy-MM-dd').format(day);
              final dayTasks = tasks.where((t) {
                final ref = t.dueDate ?? t.assignedDate;
                return DateFormat('yyyy-MM-dd').format(ref) == dayKey;
              }).toList();
              final isToday = dayKey == todayKey;
              final hasTasks = dayTasks.isNotEmpty;

              return GestureDetector(
                onTap: hasTasks
                    ? () => _showDayTasks(context, day, dayTasks)
                    : null,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF6A1B9A).withOpacity(0.15)
                        : null,
                    shape: BoxShape.circle,
                    border: isToday
                        ? Border.all(
                            color: const Color(0xFF6A1B9A), width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${day.day}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: hasTasks
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      if (hasTasks)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dayTasks
                              .take(3)
                              .map((t) => Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: _typeColor(t.type),
                                      shape: BoxShape.circle,
                                    ),
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Leyenda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            children: const [
              _TypeLegend(type: 'tarea'),
              _TypeLegend(type: 'examen'),
              _TypeLegend(type: 'comentario'),
              _TypeLegend(type: 'aviso'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Próximas tareas
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Próximas tareas',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 4),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sin tareas asignadas.',
                style: TextStyle(color: Colors.grey)),
          )
        else
          ...tasks
              .where((t) {
                final ref = t.dueDate ?? t.assignedDate;
                return !ref.isBefore(
                    DateTime.now().subtract(const Duration(days: 1)));
              })
              .take(10)
              .map((t) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 2),
                    child: _TaskChip(task: t, studentId: studentId),
                  )),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showDayTasks(
      BuildContext context, DateTime day, List<TaskModel> dayTasks) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'es').format(day),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...dayTasks.map((t) => _TaskDetail(task: t, studentId: studentId)),
          ],
        ),
      ),
    );
  }
}

// ─── Colores e íconos ──────────────────────────────────────────────────────
Color _typeColor(String type) {
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

IconData _typeIcon(String type) {
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

// ─── Chip de tarea ─────────────────────────────────────────────────────────
class _TaskChip extends StatelessWidget {
  final TaskModel task;
  final String studentId;
  const _TaskChip({required this.task, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final seen = task.seenBy.contains(studentId);
    final grade = task.grades[studentId];
    final color = _typeColor(task.type);
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              Icon(_typeIcon(task.type), color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(task.title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null &&
                  task.description!.isNotEmpty)
                Text(task.description!),
              const SizedBox(height: 8),
              Text('Materia: ${task.subjectName}',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13)),
              if (task.dueDate != null)
                Text(
                  'Entrega: ${DateFormat('dd/MM/yyyy').format(task.dueDate!)}',
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w500),
                ),
              if (grade != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.grade, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Calificación: $grade',
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar')),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(seen ? 0.07 : 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(_typeIcon(task.type), size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight:
                        seen ? FontWeight.normal : FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (grade != null) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  grade,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Detalle de tarea ──────────────────────────────────────────────────────
class _TaskDetail extends StatelessWidget {
  final TaskModel task;
  final String studentId;
  const _TaskDetail({required this.task, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(task.type);
    final grade = task.grades[studentId];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: color,
            child: Icon(_typeIcon(task.type),
                color: Colors.white, size: 18)),
        title: Text(task.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null &&
                task.description!.isNotEmpty)
              Text(task.description!),
            Text(task.subjectName,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
            if (task.dueDate != null)
              Text(
                  'Entrega: ${DateFormat('dd/MM/yyyy').format(task.dueDate!)}',
                  style: const TextStyle(
                      color: Colors.red, fontSize: 12)),
            if (grade != null)
              Row(
                children: [
                  const Icon(Icons.grade, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Calificación: $grade',
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
        isThreeLine: true,
        trailing: grade != null
            ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  grade,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              )
            : null,
      ),
    );
  }
}

// ─── Leyenda ───────────────────────────────────────────────────────────────
class _TypeLegend extends StatelessWidget {
  final String type;
  const _TypeLegend({required this.type});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: _typeColor(type), shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(type,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
