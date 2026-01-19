import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class EditAppointmentScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const EditAppointmentScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  late DateTime _selectedDate;
  String? _selectedTime;
  bool _isLoadingSlots = false;
  List<String> _availableTimeSlots = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.appointment.appointmentDate;
    _selectedTime = widget.appointment.appointmentTime;
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() {
      _isLoadingSlots = true;
    });

    try {
      final firestoreService = FirestoreService();

      final barber = await firestoreService.getUserById(widget.appointment.barberId);
      if (barber == null) {
        setState(() {
          _isLoadingSlots = false;
          _availableTimeSlots = [];
        });
        return;
      }

      final barbershop = await firestoreService.getBarbershopById(barber.barbershopId!);
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
      final duration = barber.appointmentDuration ?? 30;

      List<String> allSlots = [];
      while (currentMinutes <= endMinutes) {
        final hour = (currentMinutes ~/ 60).toString().padLeft(2, '0');
        final minute = (currentMinutes % 60).toString().padLeft(2, '0');
        allSlots.add('$hour:$minute');
        currentMinutes += duration;
      }

      final existingAppointments = await firestoreService.getBarberAppointmentsByDateFuture(
        widget.appointment.barberId,
        _selectedDate,
      );

      final occupiedSlots = existingAppointments
          .where((apt) =>
      apt.id != widget.appointment.id && apt.status != AppointmentStatus.cancelled)
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

  Future<void> _updateAppointment() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una hora'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final dateChanged = _selectedDate != widget.appointment.appointmentDate;
    final timeChanged = _selectedTime != widget.appointment.appointmentTime;

    if (!dateChanged && !timeChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No has realizado ningún cambio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        title: const Text('Confirmar cambios', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Deseas reagendar esta cita?', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            if (dateChanged || timeChanged) ...[
              Text('De:', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              Text(
                '${DateFormat('d MMM yyyy').format(widget.appointment.appointmentDate)} - ${widget.appointment.appointmentTime}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text('A:', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              Text(
                '${DateFormat('d MMM yyyy').format(_selectedDate)} - $_selectedTime',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            child: const Text('Confirmar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final firestoreService = FirestoreService();

      await firestoreService.updateAppointment(
        widget.appointment.id,
        {
          'appointmentDate': _selectedDate,
          'appointmentTime': _selectedTime,
        },
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cita reagendada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
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
        title: const Text('Editar Cita'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                        'Puedes cambiar la fecha y hora de tu cita',
                        style: TextStyle(color: Colors.blue[900], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Barbero', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    const SizedBox(height: 3),
                    Text(
                      widget.appointment.barberName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(widget.appointment.barbershopName,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text('Nueva Fecha',
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
                        child: Text(
                          DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text('Nueva Hora',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                  label: Text(time, style: TextStyle(fontSize: 11)),
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

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 45,
              child: FilledButton.icon(
                onPressed: _updateAppointment,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Guardar Cambios', style: TextStyle(fontSize: 10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}