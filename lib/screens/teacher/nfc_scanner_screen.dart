import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:uuid/uuid.dart';
import '../../models/subject_model.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import '../../services/student_service.dart';
import '../../services/attendance_service.dart';
import '../../services/connectivity_service.dart';

class NfcScannerScreen extends StatefulWidget {
  final SubjectModel subject;
  final String teacherId;
  const NfcScannerScreen(
      {super.key, required this.subject, required this.teacherId});

  @override
  State<NfcScannerScreen> createState() => _NfcScannerScreenState();
}

class _NfcScannerScreenState extends State<NfcScannerScreen> {
  bool _processing = false;
  StudentModel? _lastScanned;
  String? _message;
  bool _success = false;
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkNfcAndStart();
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _checkNfcAndStart() async {
    final available = await NfcManager.instance.isAvailable();
    if (!mounted) return;
    setState(() => _nfcAvailable = available);
    if (available) _startListening();
  }

  void _startListening() {
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        if (_processing) return;
        final uid = _extractUid(tag);
        if (uid == null) {
          _showResult('No se pudo leer esta tarjeta NFC.', false, null);
          return;
        }
        await _registerAttendance(uid);
      },
    );
  }

  String? _extractUid(NfcTag tag) {
    for (final key in [
      'nfca', 'nfcb', 'nfcf', 'nfcv',
      'isodep', 'mifareclassic', 'mifareultralight'
    ]) {
      final tech = tag.data[key];
      if (tech == null) continue;
      final identifier = tech['identifier'];
      if (identifier is List && identifier.isNotEmpty) {
        return Uint8List.fromList(identifier.cast<int>())
            .map((e) => e.toRadixString(16).padLeft(2, '0'))
            .join()
            .toUpperCase();
      }
    }
    return null;
  }

  Future<void> _registerAttendance(String nfcUid) async {
    setState(() => _processing = true);
    NfcManager.instance.stopSession();

    final isConnected = await ConnectivityService().isConnected();
    if (!isConnected) {
      _showResult(
          'Sin conexión. Conéctate a internet e intenta de nuevo.', false, null);
      return;
    }

    try {
      final student = await StudentService().getStudentByNfcUid(nfcUid);
      if (student == null) {
        _showResult(
            'Tarjeta no enlazada a ningún alumno.\nEnlázala primero desde "Mis Alumnos".',
            false,
            null);
        return;
      }

      final alreadyScanned = await AttendanceService()
          .alreadyScannedToday(student.id, widget.subject.id);
      if (alreadyScanned) {
        _showResult(
            '${student.name} ya fue registrado hoy en esta materia.',
            false,
            null);
        return;
      }

      final attendance = AttendanceModel(
        id: const Uuid().v4(),
        studentId: student.id,
        studentName: student.name,
        subjectId: widget.subject.id,
        teacherId: widget.teacherId,
        date: DateTime.now(),
        present: true,
        schoolId: widget.subject.schoolId,
      );
      await AttendanceService().registerAttendance(attendance);
      _showResult('¡Asistencia registrada!', true, student);
    } catch (_) {
      _showResult('Error al registrar asistencia.', false, null);
    }
  }

  void _showResult(String message, bool success, StudentModel? student) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _success = success;
      _lastScanned = student;
      _processing = false;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _message = null;
          _lastScanned = null;
        });
        _startListening();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista NFC: ${widget.subject.name}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: !_nfcAvailable
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.nfc, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'NFC no disponible o desactivado en este dispositivo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Activa el NFC en Ajustes e intenta de nuevo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF1565C0), width: 3),
                        ),
                        child: const Icon(Icons.nfc,
                            size: 90, color: Color(0xFF1565C0)),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        widget.subject.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(widget.subject.semesterGroup,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Acerca la tarjeta NFC del alumno al teléfono',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_message != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: _success ? Colors.green : Colors.red,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _success ? Icons.check_circle : Icons.error,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          if (_lastScanned != null) ...[
                            Text(
                              _lastScanned!.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Semestre/Grupo: ${_lastScanned!.semesterGroup}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            if (_lastScanned!.career != null)
                              Text(
                                'Carrera: ${_lastScanned!.career}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                          ],
                          Text(
                            _message!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
