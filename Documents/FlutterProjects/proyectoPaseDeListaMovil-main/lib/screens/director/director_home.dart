import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../models/subject_model.dart';
import '../../models/student_model.dart';
import '../../models/school_model.dart';
import '../../services/auth_service.dart';
import '../../services/subject_service.dart';
import '../../services/student_service.dart';
import '../../services/school_service.dart';
import '../../widgets/connectivity_banner.dart';
import 'director_report_screen.dart';

class DirectorHome extends StatelessWidget {
  final UserModel user;
  const DirectorHome({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final schoolId = user.schoolId;

    return ConnectivityBanner(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Director'),
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async => await AuthService().signOut(),
            ),
          ],
        ),
        body: schoolId == null
            ? const Center(
                child: Text('Sin escuela asignada',
                    style: TextStyle(color: Colors.grey)))
            : _DirectorBody(user: user, schoolId: schoolId),
      ),
    );
  }
}

class _DirectorBody extends StatelessWidget {
  final UserModel user;
  final String schoolId;

  const _DirectorBody({required this.user, required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SchoolModel?>(
      future: SchoolService().getSchoolById(schoolId),
      builder: (context, schoolSnap) {
        final school = schoolSnap.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bienvenido, ${user.name}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Vista global de la institución',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),

              // Tarjeta de escuela con código de invitación
              if (school != null) _SchoolInfoCard(school: school),

              const SizedBox(height: 20),

              // Resumen general
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      stream: SubjectService()
                          .getSubjectsBySchool(schoolId)
                          .map((s) => s.length),
                      label: 'Asignaturas',
                      icon: Icons.book_outlined,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      stream: StudentService()
                          .getStudentsBySchool(schoolId)
                          .map((s) => s.length),
                      label: 'Alumnos',
                      icon: Icons.people_outline,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Lista de maestros
              const Text('Maestros',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<List<UserModel>>(
                stream: SchoolService().getTeachersStream(schoolId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final teachers = snapshot.data ?? [];
                  if (teachers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('No hay maestros en la escuela aún',
                          style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = teachers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1565C0),
                            child: Text(
                              teacher.name.isNotEmpty
                                  ? teacher.name[0].toUpperCase()
                                  : '?',
                              style:
                                  const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(teacher.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(teacher.email),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
              const Text('Todas las Asignaturas',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              StreamBuilder<List<SubjectModel>>(
                stream: SubjectService().getSubjectsBySchool(schoolId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final subjects = snapshot.data ?? [];
                  if (subjects.isEmpty) {
                    return const Center(
                        child: Text('No hay asignaturas registradas',
                            style: TextStyle(color: Colors.grey)));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A1B9A)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.book_outlined,
                                color: Color(0xFF6A1B9A)),
                          ),
                          title: Text(subject.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle:
                              Text('Grupo: ${subject.semesterGroup}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.bar_chart,
                                color: Color(0xFF6A1B9A)),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DirectorReportScreen(
                                    subject: subject),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
              const Text('Todos los Alumnos',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              StreamBuilder<List<StudentModel>>(
                stream: StudentService().getStudentsBySchool(schoolId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final students = snapshot.data ?? [];
                  if (students.isEmpty) {
                    return const Center(
                        child: Text('No hay alumnos registrados',
                            style: TextStyle(color: Colors.grey)));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF6A1B9A),
                            child: Text(
                                student.name.isNotEmpty
                                    ? student.name[0].toUpperCase()
                                    : '?',
                                style:
                                    const TextStyle(color: Colors.white)),
                          ),
                          title: Text(student.name),
                          subtitle: Text(
                              'Grupo: ${student.semesterGroup}${student.career != null ? ' · ${student.career}' : ''}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SchoolInfoCard extends StatelessWidget {
  final SchoolModel school;
  const _SchoolInfoCard({required this.school});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF6A1B9A).withOpacity(0.08),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, color: Color(0xFF6A1B9A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    school.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A1B9A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Código de invitación para maestros:',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A1B9A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    school.inviteCode,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, color: Color(0xFF6A1B9A)),
                  tooltip: 'Copiar código',
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: school.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Código copiado al portapapeles')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Stream<int> stream;
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.stream,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            StreamBuilder<int>(
              stream: stream,
              builder: (context, snapshot) => Text(
                '${snapshot.data ?? 0}',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ),
            Text(label,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
