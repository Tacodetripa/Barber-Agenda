import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/barbershop_provider.dart';
import '../../models/barbershop_model.dart';
import '../../models/user_model.dart';
import 'create_appointment_screen.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/empty_state_widget.dart';

class SelectBarberScreen extends StatefulWidget {
  final String barbershopId;

  const SelectBarberScreen({
    super.key,
    required this.barbershopId,
  });

  @override
  State<SelectBarberScreen> createState() => _SelectBarberScreenState();
}

class _SelectBarberScreenState extends State<SelectBarberScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<BarbershopProvider>();
    if (provider.barbers.isEmpty) {
      provider.loadBarbers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona tu Barbero'),
      ),
      body: Consumer<BarbershopProvider>(
        builder: (context, provider, _) {
          final barbershop = provider.barbershops.firstWhere((b) => b.id == widget.barbershopId);
          final barbers = provider.getBarbersByBarbershop(widget.barbershopId);

          return Column(
            children: [
              // Header compacto
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            barbershop.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            barbershop.address,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Horario: ${barbershop.openingTime} - ${barbershop.closingTime}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de barberos
              Expanded(
                child: barbers.isEmpty
                    ? const EmptyStateWidget(
                  icon: Icons.person_off,
                  title: 'No hay barberos disponibles',
                  subtitle: 'Esta barbería no tiene barberos activos',
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: barbers.length,
                  itemBuilder: (context, index) {
                    final barber = barbers[index];
                    return _BarberCard(
                      barber: barber,
                      barbershop: barbershop,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BarberCard extends StatelessWidget {
  final UserModel barber;
  final BarbershopModel barbershop;

  const _BarberCard({
    required this.barber,
    required this.barbershop,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageTransitions.slideFromRight(
              CreateAppointmentScreen(
                barber: barber,
                barbershop: barbershop,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar compacto
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: barber.photoUrl != null ? NetworkImage(barber.photoUrl!) : null,
                child: barber.photoUrl == null
                    ? Text(
                  barber.firstName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      barber.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (barber.nickname != null)
                      Text(
                        '"${barber.nickname}"',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.purple[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${barber.appointmentDuration ?? 30} min por corte',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.purple[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Flecha
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}