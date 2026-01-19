import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/barbershop_provider.dart';
import '../../models/barbershop_model.dart';

class EditBarbershopScreen extends StatefulWidget {
  final BarbershopModel barbershop;

  const EditBarbershopScreen({
    Key? key,
    required this.barbershop,
  }) : super(key: key);

  @override
  State<EditBarbershopScreen> createState() => _EditBarbershopScreenState();
}

class _EditBarbershopScreenState extends State<EditBarbershopScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _openingTimeController;
  late TextEditingController _closingTimeController;

  late List<String> _selectedDays;

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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.barbershop.name);
    _addressController = TextEditingController(text: widget.barbershop.address);
    _phoneController = TextEditingController(text: widget.barbershop.phoneNumber ?? '');
    _openingTimeController = TextEditingController(text: widget.barbershop.openingTime);
    _closingTimeController = TextEditingController(text: widget.barbershop.closingTime);
    _selectedDays = List.from(widget.barbershop.workingDays);
  }

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

  Future<void> _handleUpdate() async {
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

    final barbershopProvider = context.read<BarbershopProvider>();

    // 🆕 CREAR MAP CON LOS DATOS
    final updates = {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'phoneNumber': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      'workingDays': _selectedDays,
      'openingTime': _openingTimeController.text,
      'closingTime': _closingTimeController.text,
      'updatedAt': DateTime.now(),
    };

    final success = await barbershopProvider.updateBarbershop(
      widget.barbershop.id,
      updates,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barbería actualizada'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(barbershopProvider.errorMessage ?? 'Error al actualizar'),
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
        title: const Text('Editar Barbería'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Días de trabajo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
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
              Text(
                'Horario de trabajo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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
              FilledButton(
                onPressed: provider.isLoading ? null : _handleUpdate,
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
                    : const Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}