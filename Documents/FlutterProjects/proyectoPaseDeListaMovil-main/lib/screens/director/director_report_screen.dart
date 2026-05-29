import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../models/subject_model.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';

class DirectorReportScreen extends StatelessWidget {
  final SubjectModel subject;
  const DirectorReportScreen({super.key, required this.subject});

  Future<void> _exportToExcel(
      BuildContext context, List<AttendanceModel> records) async {
    final excel = Excel.createExcel();
    final sheet = excel['Asistencia'];
    sheet.appendRow([
      TextCellValue('Nombre'),
      TextCellValue('Fecha'),
      TextCellValue('Hora'),
      TextCellValue('Estado'),
    ]);
    for (final r in records) {
      sheet.appendRow([
        TextCellValue(r.studentName),
        TextCellValue(DateFormat('dd/MM/yyyy').format(r.date)),
        TextCellValue(DateFormat('HH:mm').format(r.date)),
        TextCellValue(r.present ? 'Presente' : 'Ausente'),
      ]);
    }
    final bytes = excel.save();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final fileName =
        'reporte_${subject.name.replaceAll(' ', '_')}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)],
        text: 'Reporte: ${subject.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<AttendanceModel>>(
        future:
            AttendanceService().getAttendanceBySubjectOnce(subject.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(
                child: Text('Sin registros de asistencia',
                    style: TextStyle(color: Colors.grey)));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _exportToExcel(context, records),
                    icon: const Icon(Icons.download),
                    label: const Text('Exportar a Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final r = records[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF2E7D32),
                        child: Icon(Icons.check,
                            color: Colors.white, size: 18),
                      ),
                      title: Text(r.studentName),
                      subtitle: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(r.date)),
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