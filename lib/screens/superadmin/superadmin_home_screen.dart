import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/barbershop_provider.dart';
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';
import 'create_barbershop_screen.dart';
import 'create_barber_screen.dart';
import '../shared/appointment_detail_screen.dart';
import 'manage_barbershops_screen.dart';
import 'manage_barbers_screen.dart';

class SuperAdminHomeScreen extends StatefulWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  State<SuperAdminHomeScreen> createState() => _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends State<SuperAdminHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await context.read<AuthProvider>().signOut();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (mounted) {
            context.read<AppointmentProvider>().loadAllAppointments();
            context.read<BarbershopProvider>().loadBarbershops();
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                '¡Hola, Admin!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Resumen general del sistema',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),

              // Estadísticas principales
              _buildStatsSection(),

              const SizedBox(height: 12),

              // Acciones rápidas
              Text(
                'Acciones Rápidas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildQuickActions(),

              const SizedBox(height: 12),

              // Gráfico de citas por estado
              Text(
                'Citas por Estado',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildAppointmentStatusChart(),

              const SizedBox(height: 12),

              // Últimas citas
              Text(
                'Últimas Citas Creadas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              _buildRecentAppointments(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Consumer2<BarbershopProvider, AppointmentProvider>(
      builder: (context, barbershopProvider, appointmentProvider, _) {
        final totalBarbershops = barbershopProvider.barbershops.length;
        final totalAppointments = appointmentProvider.appointments.length;

        return Row(
          children: [
            // 🆕 CARD DE BARBERÍAS - AHORA CON NAVEGACIÓN
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageBarbershopsScreen(),
                    ),
                  );
                },
                child: _StatCard(
                  icon: Icons.store,
                  title: 'Barberías',
                  value: totalBarbershops.toString(),
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 🆕 CARD DE BARBEROS - AHORA CON NAVEGACIÓN
            Expanded(
              child: StreamBuilder<List>(
                stream: _firestoreService.getBarbers(),
                builder: (context, snapshot) {
                  final totalBarbers = snapshot.hasData ? snapshot.data!.length : 0;
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageBarbersScreen(),
                        ),
                      );
                    },
                    child: _StatCard(
                      icon: Icons.content_cut,
                      title: 'Barberos',
                      value: totalBarbers.toString(),
                      color: Colors.orange,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),

            // Card de citas (sin cambios)
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today,
                title: 'Citas',
                value: totalAppointments.toString(),
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateBarbershopScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_business, color: Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nueva\nBarbería',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateBarberScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add, color: Colors.orange),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nuevo\nBarbero',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentStatusChart() {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, _) {
        final appointments = provider.appointments;

        // Contar citas por estado
        int pending = 0;
        int confirmed = 0;
        int completed = 0;
        int cancelled = 0;

        for (var appointment in appointments) {
          switch (appointment.status) {
            case AppointmentStatus.pending:
              pending++;
              break;
            case AppointmentStatus.confirmed:
              confirmed++;
              break;
            case AppointmentStatus.completed:
              completed++;
              break;
            case AppointmentStatus.cancelled:
              cancelled++;
              break;
          }
        }

        final total = appointments.length;

        if (total == 0) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'No hay citas registradas',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _StatusRow(
                  label: 'Pendientes',
                  count: pending,
                  total: total,
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  label: 'Confirmadas',
                  count: confirmed,
                  total: total,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  label: 'Completadas',
                  count: completed,
                  total: total,
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  label: 'Canceladas',
                  count: cancelled,
                  total: total,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentAppointments() {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, _) {
        final recentAppointments = provider.appointments.take(5).toList();

        if (recentAppointments.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'No hay citas recientes',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        }

        return Card(
          child: Column(
            children: recentAppointments.map((appointment) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(appointment.status).withOpacity(0.2),
                  child: Icon(
                    Icons.calendar_today,
                    color: _getStatusColor(appointment.status),
                    size: 1,
                  ),
                ),
                title: Text(
                  '${appointment.clientName} → ${appointment.barberName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                ),
                subtitle: Text(
                  '${DateFormat('dd/MM/yyyy').format(appointment.appointmentDate)} - ${appointment.appointmentTime}',
                  style: const TextStyle(fontSize: 8),
                ),
                trailing: Chip(
                  label: Text(
                    _getStatusText(appointment.status),
                    style: const TextStyle(fontSize: 8),
                  ),
                  backgroundColor: _getStatusColor(appointment.status).withOpacity(0.2),
                  side: BorderSide(color: _getStatusColor(appointment.status)),
                  padding: EdgeInsets.zero,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentDetailScreen(
                        appointment: appointment,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pendiente';
      case AppointmentStatus.confirmed:
        return 'Confirmada';
      case AppointmentStatus.completed:
        return 'Completada';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
    }
  }
}

// Widget de tarjeta de estadística
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget de fila de estado con barra de progreso
class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '$count ($percentage%)',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? count / total : 0,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}