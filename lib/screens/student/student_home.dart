import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/student_model.dart';
import '../../models/subject_model.dart';
import '../../models/attendance_model.dart';
import '../../services/auth_service.dart';
import '../../services/student_service.dart';
import '../../services/subject_service.dart';
import '../../services/attendance_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/connectivity_banner.dart';
import 'student_attendance_screen.dart';
import 'student_tasks_screen.dart';

class StudentHome extends StatefulWidget {
  final UserModel user;
  const StudentHome({super.key, required this.user});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final uid = widget.user.uid;
    final studentId = widget.user.studentId;
    // Guardar token FCM del usuario actual
    await NotificationService.saveToken(uid);
    // Verificar y mostrar notificaciones pendientes si es alumno
    if (studentId != null && studentId.isNotEmpty) {
      await NotificationService.checkPendingNotifications(studentId);
    }
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
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio'),
            NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: 'Asistencias'),
            NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: 'Tareas'),
          ],
        ),
      ),
    );
  }
}

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
        builder: (context, studentSnap) {
          if (studentSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (studentSnap.hasError) {
            return Center(
              child: Text('Error: ${studentSnap.error}',
                  style: const TextStyle(color: Colors.red)));
          }
          final student = studentSnap.data;
          if (student == null) {
            return const Center(
                child: Text(
                    'No se encontró tu perfil.\nContacta a tu maestro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)));
          }
          return _StudentDashboard(user: widget.user, student: student);
        },
      ),
    );
  }
}

class _StudentDashboard extends StatelessWidget {
  final UserModel user;
  final StudentModel student;
  const _StudentDashboard({required this.user, required this.student});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SubjectModel>>(
      stream: SubjectService().getSubjectsByStudentId(student.id),
      builder: (context, subSnap) {
        final subjects = subSnap.data ?? [];
        return FutureBuilder<List<AttendanceModel>>(
          future: AttendanceService().getAttendanceByStudent(student.id),
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
                            student.name[0].toUpperCase(),
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
                              Text('Hola, ${student.name.split(' ').first}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  'Semestre/Grupo: ${student.semesterGroup}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              if (student.career != null)
                                Text(student.career!,
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
                // Stats globales
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
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
