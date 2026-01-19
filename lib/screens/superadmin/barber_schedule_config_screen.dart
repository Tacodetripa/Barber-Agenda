import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/working_hours.dart';

class BarberScheduleConfigScreen extends StatefulWidget {
  final UserModel barber;

  const BarberScheduleConfigScreen({
    Key? key,
    required this.barber,
  }) : super(key: key);

  @override
  State<BarberScheduleConfigScreen> createState() => _BarberScheduleConfigScreenState();
}

class _BarberScheduleConfigScreenState extends State<BarberScheduleConfigScreen> {
  final Map<String, WorkingHours> _schedule = {};
  final List<String> _workingDays = [];
  bool _isLoading = false;

  final List<Map<String, String>> _daysOfWeek = [
    {'key': 'monday', 'label': 'Lunes'},
    {'key': 'tuesday', 'label': 'Martes'},
    {'key': 'wednesday', 'label': 'Miércoles'},
    {'key': 'thursday', 'label': 'Jueves'},
    {'key': 'friday', 'label': 'Viernes'},
    {'key': 'saturday', 'label': 'Sábado'},
    {'key': 'sunday', 'label': 'Domingo'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentSchedule();
  }

  void _loadCurrentSchedule() {
    if (widget.barber.customSchedule != null) {
      _schedule.addAll(widget.barber.customSchedule!);
    }

    if (widget.barber.workingDays != null) {
      _workingDays.addAll(widget.barber.workingDays!);
    }

    // Horario por defecto si no tiene
    if (_schedule.isEmpty) {
      for (var day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']) {
        _schedule[day] = WorkingHours(
          openingTime: '09:00',
          closingTime: '18:00',
          isWorking: true,
        );
        _workingDays.add(day);
      }
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.barber.uid)
          .update({
        'customSchedule': _schedule.map((day, hours) => MapEntry(day, hours.toMap())),
        'workingDays': _workingDays,
        'updatedAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horarios guardados'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (_workingDays.contains(day)) {
        _workingDays.remove(day);
        _schedule[day] = _schedule[day]!.copyWith(isWorking: false);
      } else {
        _workingDays.add(day);
        if (!_schedule.containsKey(day)) {
          _schedule[day] = WorkingHours(
            openingTime: '09:00',
            closingTime: '18:00',
            isWorking: true,
          );
        } else {
          _schedule[day] = _schedule[day]!.copyWith(isWorking: true);
        }
      }
    });
  }

  Future<void> _selectTime(String day, bool isOpening) async {
    final currentSchedule = _schedule[day];
    if (currentSchedule == null) return;

    final currentTime = isOpening ? currentSchedule.openingTime : currentSchedule.closingTime;
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      final timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

      setState(() {
        if (isOpening) {
          _schedule[day] = _schedule[day]!.copyWith(openingTime: timeString);
        } else {
          _schedule[day] = _schedule[day]!.copyWith(closingTime: timeString);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Horarios - ${widget.barber.displayName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveSchedule,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _daysOfWeek.length,
        itemBuilder: (context, index) {
          final day = _daysOfWeek[index];
          final dayKey = day['key']!;
          final dayLabel = day['label']!;
          final isWorking = _workingDays.contains(dayKey);
          final schedule = _schedule[dayKey];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isWorking ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ),
                      Switch(
                        value: isWorking,
                        onChanged: (value) => _toggleDay(dayKey),
                      ),
                    ],
                  ),

                  if (isWorking && schedule != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(dayKey, true),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Apertura',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    schedule.openingTime,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(dayKey, false),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cierre',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    schedule.closingTime,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${schedule.getDurationInHours().toStringAsFixed(1)} horas',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}