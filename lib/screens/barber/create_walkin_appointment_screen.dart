import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class CreateWalkinAppointmentScreen extends StatefulWidget {
  const CreateWalkinAppointmentScreen({super.key});

  @override
  State<CreateWalkinAppointmentScreen> createState() => _CreateWalkinAppointmentScreenState();
}

class _CreateWalkinAppointmentScreenState extends State<CreateWalkinAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  bool _isLoadingSlots = false;
  List<String> _availableTimeSlots = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser!;

    setState(() {
      _isLoadingSlots = true;
    });

    try {
      final firestoreService = FirestoreService();
      final barbershop = await firestoreService.getBarbershopById(currentUser.barbershopId!);

      if (barbershop == null) {
        setState(() {
          _isLoadingSlots = false;
          _availableTimeSlots = [];
        });
        return;
      }

      final weekdayMap = {
        1: 'monday',
        2: 'tuesday',
        3: 'wednesday',
        4: 'thursday',
        5: 'friday',
        6: 'saturday',
        7: 'sunday',
      };

      final dayName = weekdayMap[_selectedDate.weekday];
      if (!barbershop.workingDays.contains(dayName)) {
        setState(() {
          _isLoadingSlots = false;
          _availableTimeSlots = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La barbería no trabaja este día'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final openingParts = barbershop.openingTime.split(':');
      final closingParts = barbershop.closingTime.split(':');
      int startHour = int.parse(openingParts[0]);
      int startMinute = int.parse(openingParts[1]);
      int endHour = int.parse(closingParts[0]);
      int endMinute = int.parse(closingParts[1]);

      int currentMinutes = startHour * 60 + startMinute;
      int endMinutes = endHour * 60 + endMinute;
      final duration = currentUser.appointmentDuration ?? 30;

      List<String> allSlots = [];
      while (currentMinutes <= endMinutes) {
        final hour = (currentMinutes ~/ 60).toString().padLeft(2, '0');
        final minute = (currentMinutes % 60).toString().padLeft(2, '0');
        allSlots.add('$hour:$minute');
        currentMinutes += duration;
      }

      final existingAppointments = await firestoreService.getBarberAppointmentsByDateFuture(
        currentUser.uid,
        _selectedDate,
      );

      final occupiedSlots = existingAppointments
          .where((apt) => apt.status != AppointmentStatus.cancelled)
          .map((apt) => apt.appointmentTime)
          .toList();

      final availableSlots = allSlots.where((slot) {
        return !occupiedSlots.contains(slot);
      }).toList();

      setState(() {
        _availableTimeSlots = availableSlots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSlots = false;
        _availableTimeSlots = [];
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
      _loadAvailableSlots();
    }
  }

  Future<void> _createAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una hora'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final appointmentProvider = context.read<AppointmentProvider>();
    final currentUser = authProvider.currentUser!;

    final firestoreService = FirestoreService();
    final barbershop = await firestoreService.getBarbershopById(currentUser.barbershopId!);

    if (barbershop == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se encontró la barbería'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await appointmentProvider.createAppointment(
      clientId: 'walk-in-${DateTime.now().millisecondsSinceEpoch}',
      clientName: _clientNameController.text.trim(),
      clientNickname: null,
      barberId: currentUser.uid,
      barberName: currentUser.fullName,
      barbershopId: barbershop.id,
      barbershopName: barbershop.name,
      appointmentDate: _selectedDate,
      appointmentTime: _selectedTime!,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      conversationTopics: null,
    );

    if (mounted) {
      Navigator.pop(context);

      if (success) {
        final appointments = appointmentProvider.appointments;
        if (appointments.isNotEmpty) {
          final lastAppointment = appointments.first;
          await appointmentProvider.confirmAppointment(lastAppointment.id);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cita creada y confirmada!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appointmentProvider.errorMessage ?? 'Error al crear la cita'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cita'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Crea una cita para un cliente sin reserva previa',
                          style: TextStyle(color: Colors.blue[900], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text('Nombre del Cliente',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _clientNameController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Ej: Juan Pérez',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.person, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el nombre del cliente';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Text('Fecha', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Card(
                child: InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text('Hora', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),

              _isLoadingSlots
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  : _availableTimeSlots.isEmpty
                  ? Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 36, color: Colors.orange[700]),
                      const SizedBox(height: 10),
                      Text(
                        'No hay horarios disponibles',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange[900], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
                  : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _availableTimeSlots.map((time) {
                  final isSelected = _selectedTime == time;
                  return ChoiceChip(
                    label: Text(time, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTime = selected ? time : null;
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              Text('Notas (opcional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Ej: Corte degradado, sin barba...',
                  hintStyle: const TextStyle(fontSize: 11),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 40,
                child: FilledButton.icon(
                  onPressed: _createAppointment,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Crear y Confirmar Cita', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}