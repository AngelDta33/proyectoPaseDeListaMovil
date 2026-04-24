import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/subject_model.dart';
import '../../models/student_model.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../services/notification_service.dart';

class AssignTaskScreen extends StatefulWidget {
  final SubjectModel subject;
  final String teacherId;
  final StudentModel? student; // null = grupo completo

  const AssignTaskScreen({
    super.key,
    required this.subject,
    required this.teacherId,
    this.student,
  });

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'tarea';
  DateTime? _dueDate;
  bool _saving = false;

  bool get _isIndividual => widget.student != null;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final task = TaskModel(
        id: const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        type: _type,
        scope: _isIndividual ? 'individual' : 'group',
        subjectId: widget.subject.id,
        subjectName: widget.subject.name,
        teacherId: widget.teacherId,
        schoolId: widget.subject.schoolId,
        studentId: widget.student?.id,
        assignedDate: DateTime.now(),
        dueDate: _dueDate,
      );
      await TaskService().addTask(task);

      // Enviar notificaciones push a los alumnos afectados
      final notifTitle = _notifTitle(task.type, task.title);
      final notifBody = task.description?.isNotEmpty == true
          ? task.description!
          : 'Materia: ${task.subjectName}';

      if (_isIndividual && widget.student != null) {
        // Tarea individual: notificar solo a ese alumno
        await NotificationService.sendTaskNotification(
          studentId: widget.student!.id,
          title: notifTitle,
          body: notifBody,
          type: task.type,
          taskId: task.id,
        );
      } else {
        // Tarea de grupo: notificar a todos los alumnos de la materia
        final studentIds = widget.subject.studentIds;
        for (final sid in studentIds) {
          await NotificationService.sendTaskNotification(
            studentId: sid,
            title: notifTitle,
            body: notifBody,
            type: task.type,
            taskId: task.id,
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al guardar'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _notifTitle(String type, String taskTitle) {
    switch (type) {
      case 'examen':
        return '📝 Examen: $taskTitle';
      case 'comentario':
        return '💬 Comentario: $taskTitle';
      case 'aviso':
        return '🔔 Aviso: $taskTitle';
      default:
        return '📚 Tarea: $taskTitle';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isIndividual ? 'Tarea Individual' : 'Tarea al Grupo'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A quién va
              Card(
                color: const Color(0xFF6A1B9A).withOpacity(0.07),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        _isIndividual ? Icons.person : Icons.group,
                        color: const Color(0xFF6A1B9A),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isIndividual
                                ? widget.student!.name
                                : 'Todo el grupo',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          Text(widget.subject.name,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Tipo
              const Text('Tipo',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['tarea', 'examen', 'comentario', 'aviso']
                    .map((t) => ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_typeIcon(t), size: 16),
                              const SizedBox(width: 4),
                              Text(t[0].toUpperCase() + t.substring(1)),
                            ],
                          ),
                          selected: _type == t,
                          onSelected: (_) => setState(() => _type = t),
                          selectedColor: _typeColor(t),
                          labelStyle: TextStyle(
                              color: _type == t ? Colors.white : null),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              // Fecha de entrega
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(_dueDate == null
                    ? 'Fecha de entrega (opcional)'
                    : 'Entrega: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (_dueDate != null) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => setState(() => _dueDate = null),
                  child: const Text('Quitar fecha',
                      style: TextStyle(color: Colors.grey)),
                ),
              ],
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send),
                label: const Text('Asignar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _typeColor(String type) {
  switch (type) {
    case 'examen':
      return Colors.red;
    case 'comentario':
      return const Color(0xFF1565C0);
    case 'aviso':
      return Colors.orange;
    default:
      return const Color(0xFF6A1B9A);
  }
}

IconData _typeIcon(String type) {
  switch (type) {
    case 'examen':
      return Icons.quiz_outlined;
    case 'comentario':
      return Icons.comment_outlined;
    case 'aviso':
      return Icons.notifications_outlined;
    default:
      return Icons.assignment_outlined;
  }
}
