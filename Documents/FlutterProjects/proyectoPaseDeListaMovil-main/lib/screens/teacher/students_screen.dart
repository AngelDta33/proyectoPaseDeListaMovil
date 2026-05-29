import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../../models/student_model.dart';
import '../../models/group_model.dart';
import '../../services/student_service.dart';
import '../../services/group_service.dart';
import '../../widgets/student_card.dart';
import 'qr_generator_screen.dart';
import 'nfc_linker_screen.dart';

class StudentsScreen extends StatelessWidget {
  final UserModel user;
  const StudentsScreen({super.key, required this.user});

  void _showCodeOptions(BuildContext context, StudentModel student) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  student.name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              // Código de invitación
              if (student.inviteCode != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: student.studentAuthUid != null
                          ? Colors.green.shade50
                          : const Color(0xFF1565C0).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.studentAuthUid != null
                                  ? 'Cuenta creada ✓'
                                  : 'Código de invitación',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: student.studentAuthUid != null
                                      ? Colors.green
                                      : Colors.grey),
                            ),
                            Text(
                              student.inviteCode!,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 6),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              tooltip: 'Copiar código',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: student.inviteCode!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Código copiado'),
                                      duration: Duration(seconds: 1)),
                                );
                              },
                            ),
                            if (student.studentAuthUid == null)
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                tooltip: 'Regenerar código',
                                onPressed: () async {
                                  await StudentService()
                                      .regenerateInviteCode(student.id);
                                  if (context.mounted) Navigator.pop(context);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () async {
                    await StudentService().regenerateInviteCode(student.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: const Text('Generar código de invitación'),
                ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1565C0),
                  child: Icon(Icons.qr_code, color: Colors.white),
                ),
                title: const Text('Ver código QR'),
                subtitle: const Text('Para imprimir o compartir por WhatsApp'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => QrGeneratorScreen(student: student)),
                  );
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: student.nfcUid != null
                      ? const Color(0xFF00838F)
                      : Colors.grey.shade400,
                  child: const Icon(Icons.nfc, color: Colors.white),
                ),
                title: Text(student.nfcUid != null
                    ? 'Tarjeta NFC enlazada'
                    : 'Enlazar tarjeta NFC'),
                subtitle: Text(student.nfcUid != null
                    ? 'Toca para cambiar o desenlazar'
                    : 'Acerca cualquier tarjeta NFC para vincularla'),
                trailing: student.nfcUid != null
                    ? const Icon(Icons.link,
                        color: Color(0xFF00838F), size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => NfcLinkerScreen(student: student)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final semesterCtrl = TextEditingController();
    final controlCtrl = TextEditingController();
    final careerCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => _AddStudentDialog(
        user: user,
        nameCtrl: nameCtrl,
        semesterCtrl: semesterCtrl,
        controlCtrl: controlCtrl,
        careerCtrl: careerCtrl,
        formKey: formKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Alumnos'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar alumno'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<StudentModel>>(
        stream: StudentService().getStudentsByTeacher(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tienes alumnos registrados',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 80),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return StudentCard(
                student: student,
                onTap: () => _showCodeOptions(context, student),
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Eliminar alumno'),
                      content: Text(
                          '¿Seguro que deseas eliminar a ${student.name}?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Eliminar',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await StudentService().deleteStudent(student.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Diálogo de agregar alumno con selector de grupo ─────────────────────────
class _AddStudentDialog extends StatefulWidget {
  final UserModel user;
  final TextEditingController nameCtrl;
  final TextEditingController semesterCtrl;
  final TextEditingController controlCtrl;
  final TextEditingController careerCtrl;
  final GlobalKey<FormState> formKey;

  const _AddStudentDialog({
    required this.user,
    required this.nameCtrl,
    required this.semesterCtrl,
    required this.controlCtrl,
    required this.careerCtrl,
    required this.formKey,
  });

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  String? _selectedGroupName; // null = escribir manualmente
  bool _useManual = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Alumno'),
      content: SingleChildScrollView(
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: widget.nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre *', border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),
              // Campo Semestre/Grupo con dropdown de grupos
              StreamBuilder<List<GroupModel>>(
                stream: GroupService()
                    .getGroupsByTeacher(widget.user.uid),
                builder: (context, snap) {
                  final groups = snap.data ?? [];

                  if (groups.isEmpty || _useManual) {
                    // Sin grupos creados o modo manual
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: widget.semesterCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Semestre/Grupo *',
                              border: OutlineInputBorder()),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Campo obligatorio'
                              : null,
                        ),
                        if (groups.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() {
                              _useManual = false;
                              widget.semesterCtrl.clear();
                            }),
                            child: const Text('Elegir de mis grupos'),
                          ),
                      ],
                    );
                  }

                  // Opciones: grupos del maestro + "Otro..."
                  final items = <DropdownMenuItem<String>>[
                    ...groups.map((g) => DropdownMenuItem(
                          value: g.name,
                          child: Text(g.name),
                        )),
                    const DropdownMenuItem(
                      value: '__otro__',
                      child: Text('Otro...'),
                    ),
                  ];

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Semestre/Grupo *',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedGroupName,
                    items: items,
                    onChanged: (val) {
                      if (val == '__otro__') {
                        setState(() {
                          _useManual = true;
                          _selectedGroupName = null;
                          widget.semesterCtrl.clear();
                        });
                      } else {
                        setState(() {
                          _selectedGroupName = val;
                          widget.semesterCtrl.text = val ?? '';
                        });
                      }
                    },
                    validator: (v) =>
                        v == null || v.isEmpty || v == '__otro__'
                            ? 'Selecciona un grupo'
                            : null,
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: widget.controlCtrl,
                decoration: const InputDecoration(
                    labelText: 'Matrícula (opcional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: widget.careerCtrl,
                decoration: const InputDecoration(
                    labelText: 'Carrera (opcional)',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            if (!widget.formKey.currentState!.validate()) return;
            final semGroup = _useManual
                ? widget.semesterCtrl.text.trim()
                : (_selectedGroupName ?? widget.semesterCtrl.text.trim());
            if (semGroup.isEmpty) return;
            final student = StudentModel(
              id: const Uuid().v4(),
              name: widget.nameCtrl.text.trim(),
              semesterGroup: semGroup,
              controlNumber: widget.controlCtrl.text.trim().isEmpty
                  ? null
                  : widget.controlCtrl.text.trim(),
              career: widget.careerCtrl.text.trim().isEmpty
                  ? null
                  : widget.careerCtrl.text.trim(),
              teacherId: widget.user.uid,
              schoolId: widget.user.schoolId ?? '',
              inviteCode: StudentService.generateInviteCode(),
            );
            await StudentService().addStudent(student);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}