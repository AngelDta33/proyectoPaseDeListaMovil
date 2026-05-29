import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/student_model.dart';
import '../../models/subject_model.dart';
import '../../models/task_model.dart';
import '../../models/attendance_model.dart';
import '../../services/auth_service.dart';
import '../../services/student_service.dart';
import '../../services/subject_service.dart';
import '../../services/attendance_service.dart';
import '../../services/task_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/connectivity_banner.dart';
import 'student_attendance_screen.dart';
import 'student_tasks_screen.dart';
import 'study_mode_screen.dart';

class StudentHome extends StatefulWidget {
  final UserModel user;
  const StudentHome({super.key, required this.user});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _tab = 0;

  // Badge: tareas no vistas
  int _unseenTaskCount = 0;
  StudentModel? _cachedStudent;
  StreamSubscription<List<SubjectModel>>? _subSub;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _initBadge();
  }

  @override
  void dispose() {
    _subSub?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    await NotificationService.saveToken(widget.user.uid);
    final sid = widget.user.studentId;
    if (sid != null && sid.isNotEmpty) {
      await NotificationService.checkPendingNotifications(sid);
    }
  }

  /// Carga el perfil del alumno y suscribe conteo de tareas no vistas.
  Future<void> _initBadge() async {
    try {
      final sid = widget.user.studentId;
      final student = (sid != null && sid.isNotEmpty)
          ? await StudentService().getStudentById(sid)
          : await StudentService().getStudentByAuthUid(widget.user.uid);

      if (student == null || !mounted) return;
      _cachedStudent = student;

      _subSub = SubjectService()
          .getSubjectsByStudentId(student.id)
          .listen((subjects) async {
        if (!mounted) return;
        final subjectIds = subjects.map((s) => s.id).toList();
        final tasks = await TaskService()
            .getTasksForStudent(student.id, subjectIds);
        if (!mounted) return;
        final unseen =
            tasks.where((t) => !t.seenBy.contains(student.id)).length;
        setState(() => _unseenTaskCount = unseen);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityBanner(
      child: Scaffold(
        body: IndexedStack(
          index: _tab,
          children: [
            _HomeTab(user: widget.user),
            StudentAttendanceScreen(user: widget.user),
            StudentTasksScreen(user: widget.user),
            const StudyModeScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) {
            // Al entrar a Tareas, limpiar badge localmente
            if (i == 2) setState(() => _unseenTaskCount = 0);
            setState(() => _tab = i);
          },
          destinations: [
            const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio'),
            const NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: 'Asistencias'),
            // Badge en el tab de Tareas
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _unseenTaskCount > 0,
                label: Text('$_unseenTaskCount'),
                child: const Icon(Icons.assignment_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: _unseenTaskCount > 0,
                label: Text('$_unseenTaskCount'),
                child: const Icon(Icons.assignment),
              ),
              label: 'Tareas',
            ),
            const NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Estudiar'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  final UserModel user;
  const _HomeTab({required this.user});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  late Future<StudentModel?> _studentFuture;

  @override
  void initState() {
    super.initState();
    final sid = widget.user.studentId;
    _studentFuture = (sid != null && sid.isNotEmpty)
        ? StudentService().getStudentById(sid)
        : StudentService().getStudentByAuthUid(widget.user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Escuela'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await AuthService().signOut(),
          ),
        ],
      ),
      body: FutureBuilder<StudentModel?>(
        future: _studentFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: Text('Error: ${snap.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          final student = snap.data;
          if (student == null) {
            return const Center(
                child: Text('No se encontró tu perfil.\nContacta a tu maestro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)));
          }
          return _StudentDashboard(user: widget.user, student: student);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StudentDashboard extends StatefulWidget {
  final UserModel user;
  final StudentModel student;
  const _StudentDashboard({required this.user, required this.student});

  @override
  State<_StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<_StudentDashboard> {
  int _pendingTaskCount = 0;
  bool _tasksLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPendingTasks();
  }

  Future<void> _loadPendingTasks() async {
    try {
      final subjects = await SubjectService()
          .getSubjectsByStudentId(widget.student.id)
          .first;
      final ids = subjects.map((s) => s.id).toList();
      final tasks =
      await TaskService().getTasksForStudent(widget.student.id, ids);

      final pending = tasks
          .where((t) =>
      (t.type == 'tarea' || t.type == 'examen') &&
          !t.grades.containsKey(widget.student.id))
          .length;

      if (!mounted) return;
      setState(() {
        _pendingTaskCount = pending;
        _tasksLoaded = true;
      });

      // Snackbar de felicitación si todas están calificadas
      if (tasks.isNotEmpty && pending == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(children: [
                Text('🎉  '),
                Expanded(child: Text('¡Estás al día con todas tus tareas!')),
              ]),
              backgroundColor: Color(0xFF2E7D32),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SubjectModel>>(
      stream: SubjectService().getSubjectsByStudentId(widget.student.id),
      builder: (context, subSnap) {
        final subjects = subSnap.data ?? [];
        return FutureBuilder<List<AttendanceModel>>(
          future:
          AttendanceService().getAttendanceByStudent(widget.student.id),
          builder: (context, attSnap) {
            final records = attSnap.data ?? [];
            final totalPresent = records.where((r) => r.present).length;
            final totalRecords = records.length;
            final pct = totalRecords == 0
                ? 0
                : (totalPresent * 100 ~/ totalRecords);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Bienvenida
                Card(
                  color: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: Text(
                            widget.student.name[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Hola, ${widget.student.name.split(' ').first}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  'Semestre/Grupo: ${widget.student.semesterGroup}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              if (widget.student.career != null)
                                Text(widget.student.career!,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Banner tareas pendientes
                if (_tasksLoaded) ...[
                  _PendingTasksBanner(count: _pendingTaskCount),
                  const SizedBox(height: 16),
                ],

                // Stats
                Row(
                  children: [
                    _StatCard(
                        label: 'Asistencias',
                        value: '$totalPresent',
                        icon: Icons.check_circle,
                        color: const Color(0xFF2E7D32)),
                    const SizedBox(width: 12),
                    _StatCard(
                        label: 'Faltas',
                        value: '${totalRecords - totalPresent}',
                        icon: Icons.cancel,
                        color: Colors.red),
                    const SizedBox(width: 12),
                    _StatCard(
                        label: 'Promedio',
                        value: '$pct%',
                        icon: Icons.bar_chart,
                        color: pct >= 80
                            ? const Color(0xFF2E7D32)
                            : pct >= 60
                            ? Colors.orange
                            : Colors.red),
                  ],
                ),
                const SizedBox(height: 20),

                // Materias
                const Text('Mis Materias',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (subjects.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          'No estás inscrito en ninguna materia aún.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ...subjects.map((s) {
                    final subRecords =
                    records.where((r) => r.subjectId == s.id).toList();
                    final subPresent =
                        subRecords.where((r) => r.present).length;
                    final subPct = subRecords.isEmpty
                        ? 0
                        : (subPresent * 100 ~/ subRecords.length);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                            const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.book_outlined,
                              color: Color(0xFF2E7D32)),
                        ),
                        title: Text(s.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(s.semesterGroup),
                        trailing: _AttendancePill(pct: subPct),
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _PendingTasksBanner extends StatelessWidget {
  final int count;
  const _PendingTasksBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final allDone = count == 0;
    final color =
    allDone ? const Color(0xFF2E7D32) : const Color(0xFF6A1B9A);
    final icon = allDone
        ? Icons.check_circle_outline
        : Icons.assignment_late_outlined;
    final label = allDone
        ? '¡Sin tareas pendientes por calificar!'
        : count == 1
        ? '1 tarea pendiente de calificación'
        : '$count tareas pendientes de calificación';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
        required this.value,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendancePill extends StatelessWidget {
  final int pct;
  const _AttendancePill({required this.pct});

  @override
  Widget build(BuildContext context) {
    final color = pct >= 80
        ? const Color(0xFF2E7D32)
        : pct >= 60
        ? Colors.orange
        : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$pct%',
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
    );
  }
}