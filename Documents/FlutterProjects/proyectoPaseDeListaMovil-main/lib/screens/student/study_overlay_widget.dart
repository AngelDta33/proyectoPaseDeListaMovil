import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

// ─── App raíz del overlay (instancia Flutter separada) ────────────────────
class StudyOverlayApp extends StatelessWidget {
  const StudyOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StudyOverlayWidget(),
    );
  }
}

// ─── Widget principal del overlay ─────────────────────────────────────────
class StudyOverlayWidget extends StatefulWidget {
  const StudyOverlayWidget({super.key});

  @override
  State<StudyOverlayWidget> createState() => _StudyOverlayWidgetState();
}

class _StudyOverlayWidgetState extends State<StudyOverlayWidget> {
  // Datos de sesión
  String _activity = '';
  String _cancelCode = '';
  int _endTime = 0; // epoch ms
  bool _initialized = false;
  bool _timerFinished = false;

  // Timer interno
  Timer? _ticker;
  int _secondsLeft = 0;

  // Cancel: el alumno escribe el código en el campo de texto
  final TextEditingController _inputCtrl = TextEditingController();
  String? _inputError;
  bool _shaking = false;

  // ── Init ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Esperar datos del main app vía shareData
    FlutterOverlayWindow.overlayListener.listen((raw) {
      if (raw == null || _initialized || !mounted) return;
      try {
        final data = jsonDecode(raw.toString());
        if (data['cancelCode'] == null) return;
        setState(() {
          _activity   = data['activity']?.toString() ?? '';
          _cancelCode = data['cancelCode'].toString();
          _endTime    = data['endTime'] as int;
          _secondsLeft = _calcSecondsLeft();
          _initialized = true;
        });
        _startTicker();
      } catch (_) {}
    });
  }

  int _calcSecondsLeft() {
    final ms = _endTime - DateTime.now().millisecondsSinceEpoch;
    return ms > 0 ? (ms / 1000).ceil() : 0;
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final s = _calcSecondsLeft();
      setState(() => _secondsLeft = s);
      if (s <= 0) {
        _ticker?.cancel();
        setState(() => _timerFinished = true);
        _onComplete();
      }
    });
  }

  Future<void> _onComplete() async {
    try {
      await FlutterOverlayWindow.shareData(
          jsonEncode({'action': 'completed'}));
      await Future.delayed(const Duration(seconds: 4));
      await FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
  }

  // ── Lógica de cancelación ─────────────────────────────────────────────
  void _tryCancel() {
    final entered = _inputCtrl.text.trim();
    if (entered == _cancelCode) {
      _ticker?.cancel();
      FlutterOverlayWindow.shareData(jsonEncode({'action': 'cancelled'}))
          .then((_) => FlutterOverlayWindow.closeOverlay())
          .catchError((_) {});
    } else {
      _inputCtrl.clear();
      setState(() {
        _inputError = 'Código incorrecto, intenta de nuevo';
        _shaking = true;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _shaking = false);
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _inputError = null);
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _inputCtrl.dispose();
    super.dispose();
  }

  // ── Formato tiempo ────────────────────────────────────────────────────
  String get _timeString {
    final h = _secondsLeft ~/ 3600;
    final m = (_secondsLeft % 3600) ~/ 60;
    final s = _secondsLeft % 60;
    if (h > 0) {
      return '${_z(h)}:${_z(m)}:${_z(s)}';
    }
    return '${_z(m)}:${_z(s)}';
  }

  String _z(int n) => n.toString().padLeft(2, '0');

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_initialized) return _buildLoading();
    if (_timerFinished) return _buildCompleted();
    return _buildTimer();
  }

  // Pantalla de carga (antes de recibir datos)
  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      ),
    );
  }

  // Pantalla de sesión completada
  Widget _buildCompleted() {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 90, color: Colors.white),
            SizedBox(height: 20),
            Text('¡Sesión completada!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Excelente trabajo 🎉',
                style: TextStyle(color: Colors.white70, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  // Pantalla principal del temporizador
  Widget _buildTimer() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Cabecera ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                children: [
                  const Icon(Icons.menu_book_rounded,
                      color: Colors.white38, size: 26),
                  const SizedBox(height: 4),
                  const Text('MODO ESTUDIO',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          letterSpacing: 3)),
                  const SizedBox(height: 6),
                  Text(_activity,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            // ── Temporizador ───────────────────────────────────────────
            const Spacer(),
            Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Center(
                child: Text(
                  _timeString,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Spacer(),

            // ── Sección de cancelación ─────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              transform: _shaking
                  ? (Matrix4.identity()..translate(6.0))
                  : Matrix4.identity(),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: _inputError != null
                        ? Colors.orange.withOpacity(0.7)
                        : Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instrucción + código
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.5),
                      children: [
                        const TextSpan(
                            text:
                                'Ingresa lo siguiente para cancelar el timer:\n'),
                        TextSpan(
                          text: _cancelCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Campo de texto
                  TextField(
                    controller: _inputCtrl,
                    textAlign: TextAlign.center,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        letterSpacing: 6,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '_ _ _ _ _',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          letterSpacing: 6,
                          fontSize: 22),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.25)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.25)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.white70, width: 1.5),
                      ),
                      errorText: _inputError,
                      errorStyle: const TextStyle(
                          color: Colors.orange, fontSize: 12),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.orange, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.orange, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _tryCancel(),
                    onChanged: (v) {
                      if (v.length == 5) _tryCancel();
                    },
                  ),
                  const SizedBox(height: 10),

                  // Botón confirmar
                  ElevatedButton(
                    onPressed: _tryCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar temporizador'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
