import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import '../../models/subject_model.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import '../../services/student_service.dart';
import '../../services/attendance_service.dart';
import '../../services/connectivity_service.dart';

class ScannerScreen extends StatefulWidget {
  final SubjectModel subject;
  final String teacherId;
  const ScannerScreen(
      {super.key, required this.subject, required this.teacherId});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  StudentModel? _lastScanned;
  String? _message;
  bool _success = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    final studentId = barcode!.rawValue!;
    setState(() => _processing = true);
    _controller.stop();

    final isConnected = await ConnectivityService().isConnected();
    if (!isConnected) {
      setState(() {
        _message = 'Sin conexión. Conéctate a internet e intenta de nuevo.';
        _success = false;
        _lastScanned = null;
      });
      _resumeAfterDelay();
      return;
    }

    try {
      final alreadyScanned = await AttendanceService()
          .alreadyScannedToday(studentId, widget.subject.id);
      if (alreadyScanned) {
        setState(() {
          _message = 'Este alumno ya fue registrado hoy en esta materia.';
          _success = false;
          _lastScanned = null;
        });
        _resumeAfterDelay();
        return;
      }
      final student = await StudentService().getStudentById(studentId);
      if (student == null) {
        setState(() {
          _message = 'Alumno no encontrado. QR no válido.';
          _success = false;
          _lastScanned = null;
        });
        _resumeAfterDelay();
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
      setState(() {
        _lastScanned = student;
        _message = '¡Asistencia registrada!';
        _success = true;
      });
      _resumeAfterDelay();
    } catch (e) {
      setState(() {
        _message = 'Error al registrar asistencia.';
        _success = false;
      });
      _resumeAfterDelay();
    }
  }

  void _resumeAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _processing = false;
          _message = null;
          _lastScanned = null;
        });
        _controller.start();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista: ${widget.subject.name}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Marco de escaneo
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instrucción superior
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Apunta al código QR del alumno\n${widget.subject.name} — ${widget.subject.semesterGroup}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
          // Resultado del escaneo
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