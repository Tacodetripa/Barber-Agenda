import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/barbershop_model.dart';
import '../../providers/barbershop_provider.dart';

class EditBarberScreen extends StatefulWidget {
  final UserModel barber;

  const EditBarberScreen({
    Key? key,
    required this.barber,
  }) : super(key: key);

  @override
  State<EditBarberScreen> createState() => _EditBarberScreenState();
}

class _EditBarberScreenState extends State<EditBarberScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;

  String? _selectedBarbershopId;
  int _selectedDuration = 30;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.barber.firstName);
    _lastNameController = TextEditingController(text: widget.barber.lastName);
    _emailController = TextEditingController(text: widget.barber.email);
    _selectedBarbershopId = widget.barber.barbershopId;
    _selectedDuration = widget.barber.appointmentDuration ?? 30;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBarbershopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una barbería'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Actualizar en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.barber.uid)
          .update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'barbershopId': _selectedBarbershopId,
        'appointmentDuration': _selectedDuration,
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barbero actualizado'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Retornar true para indicar cambios
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Barbero'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre
              TextFormField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Apellido
              TextFormField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el apellido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email (solo lectura)
              TextFormField(
                controller: _emailController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  helperText: 'El email no se puede modificar',
                ),
              ),

              const SizedBox(height: 24),

              // Selector de Barbería
              Consumer<BarbershopProvider>(
                builder: (context, provider, _) {
                  if (provider.barbershops.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No hay barberías disponibles',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedBarbershopId,
                    decoration: const InputDecoration(
                      labelText: 'Barbería',
                      prefixIcon: Icon(Icons.store),
                    ),
                    items: provider.barbershops.map((barbershop) {
                      return DropdownMenuItem(
                        value: barbershop.id,
                        child: Text(barbershop.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBarbershopId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor selecciona una barbería';
                      }
                      return null;
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // Título: Duración de cita
              Text(
                'Duración de cita',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Selector de Duración
              DropdownButtonFormField<int>(
                value: _selectedDuration,
                decoration: const InputDecoration(
                  labelText: 'Tiempo por cita',
                  prefixIcon: Icon(Icons.access_time),
                  helperText: 'Tiempo que toma hacer un corte',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 30,
                    child: Text('30 minutos (Corte rápido)'),
                  ),
                  DropdownMenuItem(
                    value: 45,
                    child: Text('45 minutos (Corte normal)'),
                  ),
                  DropdownMenuItem(
                    value: 60,
                    child: Text('60 minutos (Corte + detalles)'),
                  ),
                  DropdownMenuItem(
                    value: 90,
                    child: Text('90 minutos (Corte completo + barba)'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDuration = value!;
                  });
                },
              ),

              const SizedBox(height: 38),

              // Botón de actualizar
              FilledButton(
                onPressed: _isLoading ? null : _handleUpdate,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}