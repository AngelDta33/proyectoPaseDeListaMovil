import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/student_model.dart';

class StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const StudentCard({
    super.key,
    required this.student,
    this.onTap,
    this.onDelete,
  });

  void _copyControlNumber(BuildContext context) {
    final number = student.controlNumber;
    if (number == null || number.isEmpty) return;
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Matrícula $number copiada al portapapeles'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            student.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(student.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Semestre/Grupo: ${student.semesterGroup}'),
            if (student.controlNumber != null)
            // long-press para copiar matrícula
              GestureDetector(
                onLongPress: () => _copyControlNumber(context),
                child: Row(
                  children: [
                    Text('Matrícula: ${student.controlNumber}'),
                    const SizedBox(width: 4),
                    const Icon(Icons.copy, size: 13, color: Colors.grey),
                  ],
                ),
              ),
            if (student.career != null) Text('Carrera: ${student.career}'),
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        )
            : null,
        onTap: onTap,
        isThreeLine: true,
      ),
    );
  }
}