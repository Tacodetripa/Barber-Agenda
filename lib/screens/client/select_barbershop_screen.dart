import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/barbershop_provider.dart';
import '../../models/barbershop_model.dart';
import 'select_barber_screen.dart';
import '../common/barbershop_location_screen.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/empty_state_widget.dart';

class SelectBarbershopScreen extends StatefulWidget {
  const SelectBarbershopScreen({super.key});

  @override
  State<SelectBarbershopScreen> createState() => _SelectBarbershopScreenState();
}

class _SelectBarbershopScreenState extends State<SelectBarbershopScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BarbershopProvider>().loadBarbershops();
      context.read<BarbershopProvider>().loadBarbers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final barbershopProvider = context.watch<BarbershopProvider>();
    final barbershops = barbershopProvider.barbershops;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona una Barbería'),
      ),
      body: barbershopProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : barbershops.isEmpty
          ? const EmptyStateWidget(
        icon: Icons.store_outlined,
        title: 'No hay barberías disponibles',
        subtitle: 'Por favor intenta más tarde',
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: barbershops.length,
        itemBuilder: (context, index) {
          final barbershop = barbershops[index];
          return _BarbershopCard(barbershop: barbershop);
        },
      ),
    );
  }
}

class _BarbershopCard extends StatelessWidget {
  final BarbershopModel barbershop;

  const _BarbershopCard({required this.barbershop});

  String _getWorkingDaysText() {
    final days = barbershop.workingDays;
    if (days.length == 7) return 'Todos los días';
    if (days.length == 6) {
      if (!days.contains('sunday')) return 'Lun-Sáb';
      if (!days.contains('monday')) return 'Mar-Dom';
    }
    return '${days.length} días';
  }

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
              SelectBarberScreen(
                barbershopId: barbershop.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icono de barbería compacto
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.store,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      barbershop.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            barbershop.address,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Chips de información compactos
                    Wrap(
                      spacing: 6,
                      runSpacing: 3,
                      children: [
                        // Horario
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 10,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${barbershop.openingTime} - ${barbershop.closingTime}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Días
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 10,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _getWorkingDaysText(),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Columna con botón de mapa y flecha
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón de mapa compacto
                  IconButton(
                    icon: const Icon(Icons.map),
                    color: const Color(0xFFC5A572),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageTransitions.fadeSlideFromRight(
                          BarbershopLocationScreen(
                            barbershop: barbershop,
                          ),
                        ),
                      );
                    },
                    tooltip: 'Ver ubicación',
                  ),
                  const SizedBox(height: 6),
                  // Flecha
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}