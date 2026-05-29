import 'package:flutter/material.dart';
import 'study_timer_screen.dart';

class StudyModeScreen extends StatefulWidget {
  const StudyModeScreen({super.key});

  @override
  State<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends State<StudyModeScreen> {
  int _minutes = 25;
  final _activityCtrl = TextEditingController();
  bool _starting = false;

  static const _primary = Color(0xFF1A237E);
  static const _presets = [15, 25, 30, 45, 60, 90, 120];

  @override
  void dispose() {
    _activityCtrl.dispose();
    super.dispose();
  }

  // ── Iniciar ───────────────────────────────────────────────────────────────
  Future<void> _startStudy() async {
    final activity = _activityCtrl.text.trim();
    if (activity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Escribe qué vas a estudiar primero')),
      );
      return;
    }

    setState(() => _starting = true);

    final result = await Navigator.of(context).push<String>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => StudyTimerScreen(
          activity: activity,
          totalSeconds: _minutes * 60,
        ),
        // Transición: deslizarse desde abajo, como un modal de pantalla completa
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeInOut)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return;
    setState(() => _starting = false);

    if (result == 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Sesión de estudio completada! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Estudio'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.menu_book_rounded,
                      size: 52, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Modo Estudio',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pantalla completa · sin distracciones',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Actividad ──────────────────────────────────────────
            const Text(
              '¿Qué vas a estudiar?',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _activityCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText:
                    'Ej: Matemáticas cap. 3, Repaso de Historia…',
                prefixIcon: const Icon(Icons.edit_note_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // ── Duración — chips ───────────────────────────────────
            const Text(
              'Duración',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((min) {
                final sel = _minutes == min;
                return ChoiceChip(
                  label: Text('${min}min'),
                  selected: sel,
                  onSelected: (_) =>
                      setState(() => _minutes = min),
                  selectedColor: _primary,
                  labelStyle: TextStyle(
                    color: sel ? Colors.white : null,
                    fontWeight: sel
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Slider
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: _primary),
                Expanded(
                  child: Slider(
                    value: _minutes.toDouble(),
                    min: 5,
                    max: 180,
                    divisions: 35,
                    activeColor: _primary,
                    label: '$_minutes min',
                    onChanged: (v) =>
                        setState(() => _minutes = v.round()),
                  ),
                ),
                SizedBox(
                  width: 58,
                  child: Text(
                    '$_minutes min',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),

            // Info pill
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_clock,
                      color: _primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'La pantalla se bloqueará por $_minutes'
                    ' minuto${_minutes != 1 ? "s" : ""}',
                    style: const TextStyle(
                        color: _primary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Botón iniciar ──────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _starting ? null : _startStudy,
              icon: _starting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Iniciar sesión de estudio',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),

            // Aviso código
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: Colors.grey, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Para salir deberás escribir un código de 5 '
                    'caracteres aleatorios que aparecerá en pantalla.',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
