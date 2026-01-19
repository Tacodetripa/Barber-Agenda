import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/barbershop_provider.dart';
import '../../models/user_model.dart';
import 'create_barber_screen.dart';
import 'barber_schedule_config_screen.dart';
import 'edit_barber_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageBarbersScreen extends StatefulWidget {
  const ManageBarbersScreen({super.key});

  @override
  State<ManageBarbersScreen> createState() => _ManageBarbersScreenState();
}

class _ManageBarbersScreenState extends State<ManageBarbersScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<BarbershopProvider>();
    provider.loadBarbers();
    provider.loadBarbershops();
  }

  String _getWorkingDaysSummary(UserModel barber) {
    if (barber.workingDays == null || barber.workingDays!.isEmpty) {
      return 'Lun-Vie'; // Por defecto
    }

    final dayLabels = {
      'monday': 'Lun',
      'tuesday': 'Mar',
      'wednesday': 'Mié',
      'thursday': 'Jue',
      'friday': 'Vie',
      'saturday': 'Sáb',
      'sunday': 'Dom',
    };

    final labels = barber.workingDays!
        .map((day) => dayLabels[day] ?? '')
        .where((label) => label.isNotEmpty)
        .toList();

    if (labels.isEmpty) return 'No configurado';
    return labels.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Barberos'),
      ),
      body: Consumer<BarbershopProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.barbers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay barberos registrados',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea el primer barbero',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.barbers.length,
            itemBuilder: (context, index) {
              final barber = provider.barbers[index];
              final barbershop = provider.barbershops.firstWhere(
                    (b) => b.id == barber.barbershopId,
                orElse: () => provider.barbershops.first,
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: barber.photoUrl != null
                        ? NetworkImage(barber.photoUrl!)
                        : null,
                    child: barber.photoUrl == null
                        ? Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                    )
                        : null,
                  ),
                  title: Text(
                    barber.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        barber.email,
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        barbershop.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 🆕 MOSTRAR DÍAS DE TRABAJO
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getWorkingDaysSummary(barber),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón de editar
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        color: Colors.blue,
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditBarberScreen(
                                barber: barber,
                              ),
                            ),
                          );

                          if (result == true) {
                            provider.loadBarbers();
                          }
                        },
                        tooltip: 'Editar barbero',
                      ),
                      // Botón de horarios
                      IconButton(
                        icon: const Icon(Icons.schedule, size: 18),
                        color: Theme.of(context).primaryColor,
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BarberScheduleConfigScreen(
                                barber: barber,
                              ),
                            ),
                          );

                          if (result == true) {
                            provider.loadBarbers();
                          }
                        },
                        tooltip: 'Configurar horarios',
                      ),
                      // 🆕 BOTÓN DE ELIMINAR
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        color: Colors.red,
                        onPressed: () async {
                          // Confirmar eliminación
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Eliminar Barbero'),
                              content: Text(
                                '¿Estás seguro de eliminar a ${barber.fullName}?\n\nEsta acción no se puede deshacer.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            // Eliminar barbero
                            try {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(barber.uid)
                                  .delete();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${barber.fullName} eliminado'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                provider.loadBarbers();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al eliminar: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        tooltip: 'Eliminar barbero',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final provider = context.read<BarbershopProvider>();
          if (provider.barbershops.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Primero debes crear una barbería'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateBarberScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Barbero'),
      ),
    );
  }
}