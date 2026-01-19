import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/barbershop_provider.dart';
import '../../providers/auth_provider.dart';

class CreateBarbershopScreen extends StatefulWidget {
  const CreateBarbershopScreen({super.key});

  @override
  State<CreateBarbershopScreen> createState() => _CreateBarbershopScreenState();
}

class _CreateBarbershopScreenState extends State<CreateBarbershopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _openingTimeController = TextEditingController(text: '09:00');
  final _closingTimeController = TextEditingController(text: '19:00');

  final List<String> _selectedDays = [];

  final Map<String, String> _daysMap = {
    'monday': 'Lunes',
    'tuesday': 'Martes',
    'wednesday': 'Miércoles',
    'thursday': 'Jueves',
    'friday': 'Viernes',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un día de trabajo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar que el horario de cierre sea después del de apertura
    final openingParts = _openingTimeController.text.split(':');
    final closingParts = _closingTimeController.text.split(':');

    final openingMinutes = int.parse(openingParts[0]) * 60 + int.parse(openingParts[1]);
    final closingMinutes = int.parse(closingParts[0]) * 60 + int.parse(closingParts[1]);

    if (closingMinutes <= openingMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Horario inválido',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'La hora de cierre (${_closingTimeController.text}) debe ser después de la hora de apertura (${_openingTimeController.text})',
              ),
              const SizedBox(height: 8),
              const Text(
                'Usa formato 24 horas: 14:00 para 2 PM, 17:00 para 5 PM, 22:00 para 10 PM',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final barbershopProvider = context.read<BarbershopProvider>();

    final barbershopId = await barbershopProvider.createBarbershop(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      ownerId: authProvider.currentUser!.uid,
      workingDays: _selectedDays,
      openingTime: _openingTimeController.text,
      closingTime: _closingTimeController.text,
    );

    if (!mounted) return;

    if (barbershopId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barbería creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            barbershopProvider.errorMessage ?? 'Error al crear barbería',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BarbershopProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Barbería'),
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
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Barbería',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Dirección
              TextFormField(
                controller: _addressController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la dirección';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),

              const SizedBox(height: 24),

              // Días de trabajo
              Text(
                'Días de trabajo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              if (_selectedDays.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${_selectedDays.length} día(s) seleccionado(s)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _daysMap.entries.map((entry) {
                  final isSelected = _selectedDays.contains(entry.key);
                  return FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(entry.key);
                        } else {
                          _selectedDays.remove(entry.key);
                        }
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Horarios
              Text(
                'Horario de trabajo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Usa formato 24 horas (14:00 = 2 PM, 17:00 = 5 PM, 22:00 = 10 PM)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _openingTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Hora de apertura',
                        prefixIcon: Icon(Icons.access_time),
                        helperText: 'Ej: 09:00 (9 AM)',
                      ),
                      onTap: () => _selectTime(_openingTimeController),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _closingTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Hora de cierre',
                        prefixIcon: Icon(Icons.access_time),
                        helperText: 'Ej: 19:00 (7 PM)',
                      ),
                      onTap: () => _selectTime(_closingTimeController),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Botón de crear
              FilledButton(
                onPressed: provider.isLoading ? null : _handleSubmit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Crear Barbería'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}