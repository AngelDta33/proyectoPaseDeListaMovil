import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pantalla de temporizador de estudio.
///
/// - Ocupa toda la pantalla en modo inmersivo (sin barra de estado ni navegación).
/// - El botón atrás está deshabilitado (PopScope).
/// - Para salir hay que escribir el código de 5 caracteres mostrado en pantalla.
class StudyTimerScreen extends StatefulWidget {
  final String activity;
  final int totalSeconds;

  const StudyTimerScreen({
    super.key,
    required this.activity,
    required this.totalSeconds,
  });

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen>
    with WidgetsBindingObserver {
  // ── Estado ────────────────────────────────────────────────────────────────
  late int _secondsLeft;
  late final String _cancelCode;
  bool _finished = false;

  Timer? _timer;
  final _codeCtrl = TextEditingController();
  String? _codeError;
  bool _shaking = false;

  // ── Init / dispose ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsLeft = widget.totalSeconds;
    _cancelCode  = _genCode();
    _setFullScreen();
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si el alumno vuelve a la app, reactivar pantalla completa
    if (state == AppLifecycleState.resumed) _setFullScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _codeCtrl.dispose();
    _restoreUI();
    super.dispose();
  }

  // ── Sistema UI ────────────────────────────────────────────────────────────
  void _setFullScreen() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  void _restoreUI() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // ── Lógica del timer ──────────────────────────────────────────────────────
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _finished = true;
          _timer?.cancel();
        }
      });
    });
  }

  String _genCode() {
    const pool =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    final rnd = Random.secure();
    return List.generate(5, (_) => pool[rnd.nextInt(pool.length)]).join();
  }

  String get _timeString {
    final h = _secondsLeft ~/ 3600;
    final m = (_secondsLeft % 3600) ~/ 60;
    final s = _secondsLeft % 60;
    return h > 0
        ? '${_z(h)}:${_z(m)}:${_z(s)}'
        : '${_z(m)}:${_z(s)}';
  }

  String _z(int n) => n.toString().padLeft(2, '0');

  // ── Cancelación ───────────────────────────────────────────────────────────
  void _tryCancel() {
    if (_codeCtrl.text.trim() == _cancelCode) {
      _timer?.cancel();
      _restoreUI();
      Navigator.of(context).pop('cancelled');
    } else {
      _codeCtrl.clear();
      setState(() {
        _codeError = 'Código incorrecto, intenta de nuevo';
        _shaking = true;
      });
      Future.delayed(const Duration(milliseconds: 600),
          () { if (mounted) setState(() => _shaking = false); });
      Future.delayed(const Duration(seconds: 3),
          () { if (mounted) setState(() => _codeError = null); });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // desactiva el botón atrás
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: _finished ? _buildCompleted() : _buildTimer(),
      ),
    );
  }

  // ── Sesión completada ─────────────────────────────────────────────────────
  Widget _buildCompleted() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 100, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                '¡Sesión completada!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                widget.activity,
                style: const TextStyle(color: Colors.white60, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text('Excelente trabajo 🎉',
                  style: TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  _restoreUI();
                  Navigator.of(context).pop('completed');
                },
                icon: const Icon(Icons.celebration_outlined),
                label: const Text('Finalizar',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Temporizador corriendo ─────────────────────────────────────────────────
  Widget _buildTimer() {
    return SafeArea(
      child: Column(
        children: [
          // ── Cabecera ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                const Icon(Icons.menu_book_rounded,
                    color: Colors.white38, size: 28),
                const SizedBox(height: 4),
                const Text('MODO ESTUDIO',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 3)),
                const SizedBox(height: 8),
                Text(
                  widget.activity,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Reloj ──────────────────────────────────────────────────
          const Spacer(),
          Container(
            width: 220,
            height: 220,
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
                    fontSize: 52,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Spacer(),

          // ── Sección cancelar ───────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            transform: _shaking
                ? (Matrix4.identity()..translate(8.0))
                : Matrix4.identity(),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: _codeError != null
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
                        height: 1.6),
                    children: [
                      const TextSpan(
                          text:
                              'Ingresa lo siguiente para cancelar el timer:\n'),
                      TextSpan(
                        text: _cancelCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de texto
                TextField(
                  controller: _codeCtrl,
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
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.25))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.25))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.white70, width: 1.5)),
                    errorText: _codeError,
                    errorStyle: const TextStyle(
                        color: Colors.orange, fontSize: 12),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.orange, width: 1.5)),
                    focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.orange, width: 1.5)),
                  ),
                  onSubmitted: (_) => _tryCancel(),
                  onChanged: (v) {
                    if (_codeError != null) {
                      setState(() => _codeError = null);
                    }
                    if (v.trim().length >= 5) _tryCancel();
                  },
                ),
                const SizedBox(height: 12),

                // Botón confirmar
                ElevatedButton(
                  onPressed: _tryCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancelar temporizador',
                      style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
