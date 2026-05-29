import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../models/subject_model.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';
import '../../services/student_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  final SubjectModel subject;
  const AttendanceReportScreen({super.key, required this.subject});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  String? _selectedDate; // null = todas las fechas

  Future<void> _exportToExcel(BuildContext context,
      List<AttendanceModel> records, List<StudentModel> enrolled) async {
    final excel = Excel.createExcel();
    final sheet = excel['Asistencia'];

    sheet.appendRow([
      TextCellValue('Nombre'),
      TextCellValue('Fecha'),
      TextCellValue('Hora'),
      TextCellValue('Estado'),
    ]);

    // Presentes desde registros reales
    for (final r in records) {
      sheet.appendRow([
        TextCellValue(r.studentName),
        TextCellValue(DateFormat('dd/MM/yyyy').format(r.date)),
        TextCellValue(DateFormat('HH:mm').format(r.date)),
        TextCellValue('Presente'),
      ]);
    }

    // Ausentes: inscritos sin registro hoy
    if (enrolled.isNotEmpty) {
      final presentIds = records.map((r) => r.studentId).toSet();
      final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
      for (final s in enrolled) {
        if (!presentIds.contains(s.id)) {
          sheet.appendRow([
            TextCellValue(s.name),
            TextCellValue(today),
            TextCellValue('—'),
            TextCellValue('Ausente'),
          ]);
        }
      }
    }

    final bytes = excel.save();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final fileName =
        'asistencia_${widget.subject.name.replaceAll(' ', '_')}_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Reporte de asistencia: ${widget.subject.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reporte: ${widget.subject.name}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Object>>(
        future: Future.wait([
          AttendanceService().getAttendanceBySubjectOnce(widget.subject.id),
          widget.subject.studentIds.isNotEmpty
              ? Future.wait(widget.subject.studentIds
              .map((id) => StudentService().getStudentById(id)))
              .then((list) => list.whereType<StudentModel>().toList())
              : Future.value(<StudentModel>[]),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records =
              (snapshot.data?[0] as List<AttendanceModel>?) ?? [];
          final enrolled =
              (snapshot.data?[1] as List<StudentModel>?) ?? [];

          // Alumnos inscritos que no tienen registro hoy
          final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
          final presentTodayIds = records
              .where((r) =>
          DateFormat('dd/MM/yyyy').format(r.date) == today)
              .map((r) => r.studentId)
              .toSet();
          final absentToday = enrolled
              .where((s) => !presentTodayIds.contains(s.id))
              .toList();

          if (records.isEmpty && enrolled.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay registros de asistencia aún',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Agrupar presentes por fecha
          final Map<String, List<AttendanceModel>> grouped = {};
          for (final r in records) {
            final key = DateFormat('dd/MM/yyyy').format(r.date);
            grouped.putIfAbsent(key, () => []).add(r);
          }

          // Filtrar registros por fecha seleccionada
          final filteredRecords = _selectedDate == null
              ? records
              : records
              .where((r) =>
          DateFormat('dd/MM/yyyy').format(r.date) == _selectedDate)
              .toList();

          final Map<String, List<AttendanceModel>> filteredGrouped = {};
          for (final r in filteredRecords) {
            final key = DateFormat('dd/MM/yyyy').format(r.date);
            filteredGrouped.putIfAbsent(key, () => []).add(r);
          }

          return Column(
            children: [
              // Chips de filtro por fecha
              if (grouped.length > 1)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Todas'),
                          selected: _selectedDate == null,
                          onSelected: (_) => setState(() => _selectedDate = null),
                          selectedColor: const Color(0xFF1565C0),
                          labelStyle: TextStyle(
                            color: _selectedDate == null ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ...grouped.keys.map((date) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(date),
                          selected: _selectedDate == date,
                          onSelected: (_) => setState(() => _selectedDate = date),
                          selectedColor: const Color(0xFF1565C0),
                          labelStyle: TextStyle(
                            color: _selectedDate == date ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              // Resumen
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                        label: 'Registros',
                        value: '${filteredRecords.length}',
                        color: const Color(0xFF1565C0)),
                    _StatItem(
                        label: 'Días con clase',
                        value: '${filteredGrouped.length}',
                        color: const Color(0xFF2E7D32)),
                    if (enrolled.isNotEmpty)
                      _StatItem(
                          label: 'Ausentes hoy',
                          value: '${absentToday.length}',
                          color: Colors.red),
                  ],
                ),
              ),
              // Ausentes hoy
              if (absentToday.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Ausentes hoy ($today)',
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                ...absentToday.map(
                      (s) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 2),
                    child: Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 16,
                          child: Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                        title: Text(s.name),
                        subtitle:
                        Text('Semestre/Grupo: ${s.semesterGroup}'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Botón exportar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _exportToExcel(context, records, enrolled),
                    icon: const Icon(Icons.download),
                    label: const Text('Exportar a Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Lista agrupada por fecha
              Expanded(
                child: filteredRecords.isEmpty
                    ? const Center(
                    child: Text('Sin asistencias registradas',
                        style: TextStyle(color: Colors.grey)))
                    : ListView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16),
                  children: filteredGrouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(vertical: 8),
                          child: Text(entry.key,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1565C0))),
                        ),
                        ...entry.value.map((r) => Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF2E7D32),
                              child: Icon(Icons.check,
                                  color: Colors.white, size: 18),
                            ),
                            title: Text(r.studentName),
                            trailing: Text(
                              DateFormat('HH:mm').format(r.date),
                              style: const TextStyle(
                                  color: Colors.grey),
                            ),
                          ),
                        )),
                        const Divider(),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
