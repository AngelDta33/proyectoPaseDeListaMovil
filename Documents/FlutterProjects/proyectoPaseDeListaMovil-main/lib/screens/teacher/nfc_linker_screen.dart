import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../models/student_model.dart';
import '../../services/student_service.dart';

class NfcLinkerScreen extends StatefulWidget {
  final StudentModel student;
  const NfcLinkerScreen({super.key, required this.student});

  @override
  State<NfcLinkerScreen> createState() => _NfcLinkerScreenState();
}

class _NfcLinkerScreenState extends State<NfcLinkerScreen> {
  bool _nfcAvailable = false;
  bool _waiting = false;
  bool _done = false;
  String? _linkedUid;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _checkNfc() async {
    final available = await NfcManager.instance.isAvailable();
    if (mounted) setState(() => _nfcAvailable = available);
  }

  Future<void> _startLinking() async {
    setState(() {
      _waiting = true;
      _done = false;
      _errorMessage = null;
    });

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        final uid = _extractUid(tag);
        if (uid == null) {
          _finishWithError('No se pudo leer el UID de esta tarjeta.');
          return;
        }

        try {
          // Verificar que el UID no esté ya enlazado a otro alumno
          final existing = await StudentService().getStudentByNfcUid(uid);
          if (existing != null && existing.id != widget.student.id) {
            _finishWithError(
                'Esta tarjeta ya está enlazada a: ${existing.name}.\nDesenláza primero desde ese alumno.');
            return;
          }

          await StudentService().linkNfc(widget.student.id, uid);
          await NfcManager.instance.stopSession();

          if (mounted) {
            setState(() {
              _waiting = false;
              _done = true;
              _linkedUid = uid;
            });
          }
        } catch (e) {
          _finishWithError('Error al enlazar: $e');
        }
      },
    );
  }

  Future<void> _unlink() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desenlazar NFC'),
        content: Text(
            '¿Quitar la tarjeta NFC enlazada a ${widget.student.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desenlazar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await StudentService().unlinkNfc(widget.student.id);
    if (mounted) Navigator.pop(context);
  }

  void _finishWithError(String message) {
    NfcManager.instance.stopSession();
    if (mounted) {
      setState(() {
        _waiting = false;
        _errorMessage = message;
      });
    }
  }

  void _reset() {
    setState(() {
      _done = false;
      _errorMessage = null;
      _waiting = false;
      _linkedUid = null;
    });
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

  @override
  Widget build(BuildContext context) {
    final alreadyLinked = widget.student.nfcUid != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enlazar Tarjeta NFC'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info del alumno
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.person,
                        size: 40, color: Color(0xFF1565C0)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.student.name,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              'Semestre/Grupo: ${widget.student.semesterGroup}',
                              style: const TextStyle(color: Colors.grey)),
                          if (widget.student.controlNumber != null)
                            Text(
                                'Matrícula: ${widget.student.controlNumber}',
                                style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (alreadyLinked && !_done)
                      const Icon(Icons.nfc, color: Color(0xFF00838F)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (!_nfcAvailable) ...[
              const Icon(Icons.nfc, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'NFC no disponible o desactivado.\nActívalo en Ajustes e intenta de nuevo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ] else if (_done) ...[
              const Icon(Icons.link, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                '¡Tarjeta NFC enlazada correctamente!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                'UID: $_linkedUid',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'monospace'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Este alumno ya puede registrar su asistencia acercando esta tarjeta.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
                label: const Text('Cambiar tarjeta'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else if (_errorMessage != null) ...[
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startLinking,
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar de nuevo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else if (_waiting) ...[
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.nfc,
                    size: 80, color: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Acerca la tarjeta NFC al teléfono ahora…',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 12),
              const LinearProgressIndicator(color: Color(0xFF1565C0)),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  NfcManager.instance.stopSession();
                  setState(() => _waiting = false);
                },
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.grey)),
              ),
            ] else ...[
              Icon(Icons.nfc,
                  size: 64,
                  color: alreadyLinked
                      ? const Color(0xFF00838F)
                      : const Color(0xFF1565C0)),
              const SizedBox(height: 16),
              Text(
                alreadyLinked
                    ? 'Esta tarjeta ya tiene una tarjeta NFC enlazada.\nPuedes enlazar una nueva para reemplazarla.'
                    : 'Presiona el botón y acerca cualquier tarjeta NFC al teléfono para enlazarla con este alumno.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              if (alreadyLinked) ...[
                const SizedBox(height: 6),
                Text(
                  'UID actual: ${widget.student.nfcUid}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontFamily: 'monospace'),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _startLinking,
                icon: const Icon(Icons.nfc),
                label: Text(alreadyLinked
                    ? 'Enlazar nueva tarjeta'
                    : 'Enlazar tarjeta NFC'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (alreadyLinked) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _unlink,
                  icon: const Icon(Icons.link_off, color: Colors.red),
                  label: const Text('Desenlazar tarjeta',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
