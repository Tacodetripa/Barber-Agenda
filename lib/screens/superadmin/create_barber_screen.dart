import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/barbershop_provider.dart';
import '../../services/firestore_service.dart';

class CreateBarberScreen extends StatefulWidget {
  const CreateBarberScreen({super.key});

  @override
  State<CreateBarberScreen> createState() => _CreateBarberScreenState();
}

class _CreateBarberScreenState extends State<CreateBarberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String? _selectedBarbershopId;
  int _selectedDuration = 30; // Duración por defecto: 30 minutos
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear usuario en Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Crear barbero en Firestore
      final firestoreService = FirestoreService();
      await firestoreService.createBarber(
        uid: userCredential.user!.uid,
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        barbershopId: _selectedBarbershopId!,
        appointmentDuration: _selectedDuration, // ← Pasar la duración
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barbero creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'Error al crear barbero';
      if (e.code == 'email-already-in-use') {
        message = 'Este email ya está registrado';
      } else if (e.code == 'weak-password') {
        message = 'La contraseña debe tener al menos 6 caracteres';
      } else if (e.code == 'invalid-email') {
        message = 'Email inválido';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Barbero'),
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

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el email';
                  }
                  if (!value.contains('@')) {
                    return 'Ingresa un email válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
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
                          'No hay barberías disponibles. Crea una barbería primero.',
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

              // Botón de crear
              FilledButton(
                onPressed: _isLoading ? null : _handleSubmit,
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
                    : const Text('Crear Barbero'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}