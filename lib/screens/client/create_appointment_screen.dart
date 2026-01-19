import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/barbershop_model.dart';
import '../../models/appointment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../services/firestore_service.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final UserModel barber;
  final BarbershopModel barbershop;

  const CreateAppointmentScreen({
    super.key,
    required this.barber,
    required this.barbershop,
  });

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  final _notesController = TextEditingController();
  final _topicsController = TextEditingController();

  List<String>? _cachedAvailableSlots;
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailableSlots();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _topicsController.dispose();
    super.dispose();
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
        _cachedAvailableSlots = null;
      });
      _loadAvailableSlots();
    }
  }

  bool _isWorkingDay() {
    final weekdayMap = {
      1: 'monday',
      2: 'tuesday',
      3: 'wednesday',
      4: 'thursday',
      5: 'friday',
      6: 'saturday',
      7: 'sunday',
    };

    final dayName = weekdayMap[_selectedDate.weekday]!;

    // 🆕 USAR HORARIOS DEL BARBERO, NO DE LA BARBERÍA
    if (widget.barber.workingDays != null && widget.barber.workingDays!.isNotEmpty) {
      return widget.barber.workingDays!.contains(dayName);
    }

    // Si el barbero no tiene configurado, usar barbería como fallback
    return widget.barbershop.workingDays.contains(dayName);
  }

  List<String> _generateTimeSlots() {
    final slots = <String>[];

    final weekdayMap = {
      1: 'monday',
      2: 'tuesday',
      3: 'wednesday',
      4: 'thursday',
      5: 'friday',
      6: 'saturday',
      7: 'sunday',
    };

    final dayName = weekdayMap[_selectedDate.weekday]!;

    // 🆕 OBTENER HORARIOS DEL BARBERO
    String openingTime = widget.barbershop.openingTime;
    String closingTime = widget.barbershop.closingTime;

    // Si el barbero tiene customSchedule, usar sus horarios
    if (widget.barber.customSchedule != null &&
        widget.barber.customSchedule!.containsKey(dayName)) {
      final schedule = widget.barber.customSchedule![dayName]!;

      // Verificar que esté trabajando ese día
      if (!schedule.isWorking) {
        return []; // No trabaja ese día
      }

      openingTime = schedule.openingTime;
      closingTime = schedule.closingTime;
    }

    // Parsear horarios
    final openingParts = openingTime.split(':');
    final closingParts = closingTime.split(':');

    int startHour = int.parse(openingParts[0]);
    int startMinute = int.parse(openingParts[1]);
    int endHour = int.parse(closingParts[0]);
    int endMinute = int.parse(closingParts[1]);

    int currentMinutes = startHour * 60 + startMinute;
    int endMinutes = endHour * 60 + endMinute;

    // 🆕 USAR DURACIÓN DEL BARBERO
    final duration = widget.barber.appointmentDuration ?? 30;

    // Generar slots
    while (currentMinutes < endMinutes) { // Cambiado <= a
      final hour = (currentMinutes ~/ 60).toString().padLeft(2, '0');
      final minute = (currentMinutes % 60).toString().padLeft(2, '0');
      slots.add('$hour:$minute');

      currentMinutes += duration;
    }

    return slots;
  }

  Future<void> _loadAvailableSlots() async {
    if (_cachedAvailableSlots != null) return;

    setState(() {
      _isLoadingSlots = true;
    });

    final slots = await _getAvailableTimeSlots();

    if (mounted) {
      setState(() {
        _cachedAvailableSlots = slots;
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _handleCreateAppointment() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una hora'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final timeParts = _selectedTime!.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final appointmentDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );

    if (appointmentDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No puedes agendar citas en horarios pasados'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final appointmentProvider = context.read<AppointmentProvider>();

    final success = await appointmentProvider.createAppointment(
      clientId: authProvider.currentUser!.uid,
      clientName: authProvider.currentUser!.fullName,
      clientNickname: authProvider.currentUser!.nickname,
      barberId: widget.barber.uid,
      barberName: widget.barber.fullName,
      barbershopId: widget.barbershop.id,
      barbershopName: widget.barbershop.name,
      appointmentDate: _selectedDate,
      appointmentTime: _selectedTime!,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      conversationTopics: _topicsController.text.trim().isEmpty ? null : _topicsController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cita agendada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appointmentProvider.errorMessage ?? 'Error al crear cita'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Cita'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: widget.barber.photoUrl != null ? NetworkImage(widget.barber.photoUrl!) : null,
                      child: widget.barber.photoUrl == null
                          ? Icon(Icons.person, size: 24, color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.barber.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(widget.barbershop.name, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(widget.barbershop.address, style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text('Selecciona la Fecha',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fecha', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text('Selecciona la Hora',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            if (_isLoadingSlots)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_cachedAvailableSlots == null || _cachedAvailableSlots!.isEmpty)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 36, color: Colors.orange[700]),
                      const SizedBox(height: 12),
                      Text(
                        'No hay horarios disponibles para esta fecha',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange[900], fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Intenta con otro día',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange[700], fontSize: 10),
                      ),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _cachedAvailableSlots!.map((time) {
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

            Text('Notas Adicionales (opcional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            TextFormField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Ej: Quiero un corte degradado...',
                hintStyle: const TextStyle(fontSize: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),

            const SizedBox(height: 12),

            Text('Temas para Conversar (opcional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            TextFormField(
              controller: _topicsController,
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Ej: Fútbol, música, etc...',
                hintStyle: const TextStyle(fontSize: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),

            const SizedBox(height: 24),

            Consumer<AppointmentProvider>(
              builder: (context, provider, _) {
                return SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: provider.isLoading ? null : _handleCreateAppointment,
                    child: provider.isLoading
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Confirmar Cita', style: TextStyle(fontSize: 10)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _getAvailableTimeSlots() async {
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
    final isWorkingDay = _isWorkingDay();

    if (!isWorkingDay) {
      return [];
    }

    final timeSlots = _generateTimeSlots();

    try {
      final firestoreService = FirestoreService();
      final existingAppointments = await firestoreService.getBarberAppointmentsByDateFuture(
        widget.barber.uid,
        _selectedDate,
      );

      final occupiedSlots = existingAppointments
          .where((apt) => apt.status != AppointmentStatus.cancelled)
          .map((apt) => apt.appointmentTime)
          .toList();

      final availableSlots = timeSlots.where((slot) {
        return !occupiedSlots.contains(slot);
      }).toList();

      return availableSlots;
    } catch (e) {
      return timeSlots;
    }
  }
}