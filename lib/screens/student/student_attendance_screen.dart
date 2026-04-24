import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/student_model.dart';
import '../../models/subject_model.dart';
import '../../models/attendance_model.dart';
import '../../services/student_service.dart';
import '../../services/subject_service.dart';
import '../../services/attendance_service.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final UserModel user;
  const StudentAttendanceScreen({super.key, required this.user});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  // ── Estado principal ──────────────────────────────────────────────────────
  StudentModel? _student;
  List<SubjectModel> _subjects = [];
  SubjectModel? _selected;
  List<AttendanceModel> _records = [];
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool _loadingStudent = true;
  bool _loadingSubjects = true;
  bool _loadingRecords = false;
  String? _error;

  StreamSubscription<List<SubjectModel>>? _subSub;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  @override
  void dispose() {
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

  // ── Suscribe a materias del alumno ────────────────────────────────────────
  void _subscribeSubjects(StudentModel student) {
    _subSub =
        SubjectService().getSubjectsByStudentId(student.id).listen((subjects) {
      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _loadingSubjects = false;
      });
      // Seleccionar primera materia automáticamente
      if (_selected == null && subjects.isNotEmpty) {
        _selectSubject(subjects.first);
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _loadingSubjects = false;
          _error = 'Error al cargar materias:\n$e';
        });
      }
    });
  }

  // ── Selecciona materia y carga asistencias ────────────────────────────────
  Future<void> _selectSubject(SubjectModel s) async {
    setState(() {
      _selected = s;
      _loadingRecords = true;
      _records = [];
    });
    try {
      final records = await AttendanceService()
          .getAttendanceByStudentAndSubject(_student!.id, s.id);
      if (mounted) {
        setState(() {
          _records = records;
          _loadingRecords = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRecords = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Asistencias'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
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
    if (_loadingSubjects) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_subjects.isEmpty) {
      return const Center(
        child: Text('No estás inscrito en ninguna materia.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        // ── Chips de materias ──────────────────────────────────────────────
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _subjects.length,
            itemBuilder: (context, i) {
              final s = _subjects[i];
              final sel = _selected?.id == s.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s.name),
                  selected: sel,
                  onSelected: (_) => _selectSubject(s),
                  selectedColor: const Color(0xFF1565C0),
                  labelStyle:
                      TextStyle(color: sel ? Colors.white : null),
                ),
              );
            },
          ),
        ),
        // ── Contenido de asistencias ───────────────────────────────────────
        Expanded(child: _buildAttendanceContent()),
      ],
    );
  }

  Widget _buildAttendanceContent() {
    if (_loadingRecords) {
      return const Center(child: CircularProgressIndicator());
    }

    final presentDays = _records
        .where((r) => r.present)
        .map((r) => DateFormat('yyyy-MM-dd').format(r.date))
        .toSet();
    final absences = _records.length - presentDays.length;
    final pct = _records.isEmpty
        ? 0
        : (presentDays.length * 100 ~/ _records.length);

    return Column(
      children: [
        // Stats
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Pill('${presentDays.length} presentes',
                  const Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              _Pill('$absences faltas', Colors.red),
              const SizedBox(width: 8),
              _Pill(
                  '$pct%',
                  pct >= 80
                      ? const Color(0xFF2E7D32)
                      : pct >= 60
                          ? Colors.orange
                          : Colors.red),
            ],
          ),
        ),
        // Navegación de mes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() =>
                  _month = DateTime(_month.year, _month.month - 1)),
            ),
            Text(
              DateFormat('MMMM yyyy', 'es').format(_month),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() =>
                  _month = DateTime(_month.year, _month.month + 1)),
            ),
          ],
        ),
        // Calendario
        Expanded(
          child: _MonthCalendar(
            month: _month,
            presentDays: presentDays,
            allRecords: _records,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _MonthCalendar extends StatelessWidget {
  final DateTime month;
  final Set<String> presentDays;
  final List<AttendanceModel> allRecords;

  const _MonthCalendar({
    required this.month,
    required this.presentDays,
    required this.allRecords,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = (firstDay.weekday - 1) % 7;

    final allDays = <DateTime?>[];
    for (var i = 0; i < startOffset; i++) allDays.add(null);
    for (var d = 1; d <= daysInMonth; d++) {
      allDays.add(DateTime(month.year, month.month, d));
    }

    const headers = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Encabezados días
          Row(
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
          const SizedBox(height: 4),
          // Grid de días
          GridView.builder(
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
              final key = DateFormat('yyyy-MM-dd').format(day);
              final hasRecord = allRecords.any(
                  (r) => DateFormat('yyyy-MM-dd').format(r.date) == key);
              final isPresent = presentDays.contains(key);
              final isToday = key == todayKey;

              Color? bg;
              Color textColor = Colors.black87;
              if (hasRecord) {
                bg = isPresent ? const Color(0xFF2E7D32) : Colors.red;
                textColor = Colors.white;
              } else if (isToday) {
                bg = const Color(0xFF1565C0).withOpacity(0.15);
              }

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: isToday && bg == null
                      ? Border.all(
                          color: const Color(0xFF1565C0), width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                        fontWeight: hasRecord
                            ? FontWeight.bold
                            : FontWeight.normal),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Leyenda
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                  color: const Color(0xFF2E7D32), label: 'Presente'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.red, label: 'Falta'),
            ],
          ),
          const SizedBox(height: 8),
          // Mensaje si no hay registros
          if (allRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Sin registros de asistencia aún.',
                  style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
