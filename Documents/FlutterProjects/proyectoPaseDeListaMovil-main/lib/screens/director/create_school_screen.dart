import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../services/school_service.dart';
import 'director_home.dart';

class CreateSchoolScreen extends StatefulWidget {
  final UserModel user;
  const CreateSchoolScreen({super.key, required this.user});

  @override
  State<CreateSchoolScreen> createState() => _CreateSchoolScreenState();
}

class _CreateSchoolScreenState extends State<CreateSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _inviteCode;
  String? _schoolId;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createSchool() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final school = await SchoolService().createSchool(
        _nameController.text.trim(),
        widget.user.uid,
      );
      setState(() {
        _inviteCode = school.inviteCode;
        _schoolId = school.id;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Error al crear la escuela: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _continue() {
    final updatedUser = UserModel(
      uid: widget.user.uid,
      name: widget.user.name,
      email: widget.user.email,
      role: widget.user.role,
      schoolId: _schoolId,
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => DirectorHome(user: updatedUser)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A1B9A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.school, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Crear tu Escuela',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Después podrás invitar maestros con un código',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _inviteCode == null
                        ? Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre de la escuela',
                                    prefixIcon:
                                        Icon(Icons.business_outlined),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Ingresa el nombre'
                                      : null,
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  Text(_errorMessage!,
                                      style: const TextStyle(
                                          color: Colors.red)),
                                ],
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed:
                                        _loading ? null : _createSchool,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF6A1B9A),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2))
                                        : const Text('Crear Escuela',
                                            style:
                                                TextStyle(fontSize: 16)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF2E7D32), size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                '¡Escuela creada!',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Comparte este código con tus maestros:',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6A1B9A)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF6A1B9A)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _inviteCode!,
                                      style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 8,
                                          color: Color(0xFF6A1B9A)),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.copy,
                                          color: Color(0xFF6A1B9A)),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: _inviteCode!));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('Código copiado')),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'También puedes verlo en tu panel en cualquier momento',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _continue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF6A1B9A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Ir al Panel',
                                      style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
