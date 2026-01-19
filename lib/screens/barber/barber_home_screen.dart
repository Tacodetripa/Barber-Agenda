import 'package:barber_agenda/screens/barber/barber_calendar_screen.dart';

import '../shared/appointment_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/appointment_model.dart';
import 'create_walkin_appointment_screen.dart';
import 'barber_calendar_screen.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/empty_state_widget.dart';

class BarberHomeScreen extends StatefulWidget {
  const BarberHomeScreen({super.key});

  @override
  State<BarberHomeScreen> createState() => _BarberHomeScreenState();
}

class _BarberHomeScreenState extends State<BarberHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser!;

    final screens = [
      _TodayAppointmentsTab(barberId: user.uid),
      _UpcomingAppointmentsTab(barberId: user.uid),
      const BarberCalendarScreen(),
      _HistoryAppointmentsTab(barberId: user.uid),
      _BarberProfileTab(user: user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                PageTransitions.slideFromBottom(
                  const CreateWalkinAppointmentScreen(),
                ),
              );
            },
            tooltip: 'Crear cita',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  title: const Text('Cerrar sesión', style: TextStyle(fontSize: 16)),
                  content: const Text('¿Estás seguro de que quieres cerrar sesión?', style: TextStyle(fontSize: 10)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      child: const Text('Cerrar sesión', style: TextStyle(fontSize: 12)),
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
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Hoy',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Próximas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_month),
            selectedIcon: Icon(Icons.calendar_view_month),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// Tab de citas de hoy
class _TodayAppointmentsTab extends StatelessWidget {
  final String barberId;

  const _TodayAppointmentsTab({required this.barberId});

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = context.watch<AppointmentProvider>();
    final todayAppointments = appointmentProvider.getBarberTodayAppointments(barberId);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: todayAppointments.isEmpty
          ? EmptyStateWidget(
        icon: Icons.event_available,
        title: 'No hay citas para hoy',
        subtitle: 'Disfruta tu día libre',
        iconColor: const Color(0xFFC5A572),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header compacto
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${todayAppointments.length} cita(s) programadas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Lista de citas
          ...todayAppointments.map((appointment) {
            return _AppointmentCard(
              appointment: appointment,
              showDate: false,
            );
          }),
        ],
      ),
    );
  }
}

// Tab de citas próximas
class _UpcomingAppointmentsTab extends StatelessWidget {
  final String barberId;

  const _UpcomingAppointmentsTab({required this.barberId});

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = context.watch<AppointmentProvider>();
    final upcomingAppointments = appointmentProvider.getBarberUpcomingAppointments(barberId);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: upcomingAppointments.isEmpty
          ? EmptyStateWidget(
        icon: Icons.calendar_today,
        title: 'No hay citas próximas',
        subtitle: 'Las citas futuras aparecerán aquí',
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: upcomingAppointments.map((appointment) {
          return _AppointmentCard(
            appointment: appointment,
            showDate: true,
          );
        }).toList(),
      ),
    );
  }
}

// Tab de historial
class _HistoryAppointmentsTab extends StatelessWidget {
  final String barberId;

  const _HistoryAppointmentsTab({required this.barberId});

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = context.watch<AppointmentProvider>();
    final historyAppointments = appointmentProvider.getBarberHistory(barberId);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: historyAppointments.isEmpty
          ? EmptyStateWidget(
        icon: Icons.history,
        title: 'Sin historial de citas',
        subtitle: 'Las citas completadas y canceladas aparecerán aquí',
        iconColor: Colors.grey,
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: historyAppointments.map((appointment) {
          return _AppointmentCard(
            appointment: appointment,
            showDate: true,
          );
        }).toList(),
      ),
    );
  }
}

// Card de cita OPTIMIZADA
class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool showDate;

  const _AppointmentCard({
    required this.appointment,
    required this.showDate,
  });

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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageTransitions.scaleIn(
              AppointmentDetailScreen(
                appointment: appointment,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header compacto
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    appointment.appointmentTime,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _getStatusColor(appointment.status)),
                    ),
                    child: Text(
                      _getStatusText(appointment.status),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(appointment.status),
                      ),
                    ),
                  ),
                ],
              ),

              if (showDate) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('EEEE, d MMMM').format(appointment.appointmentDate),
                      style: TextStyle(color: Colors.grey[600], fontSize: 9),
                    ),
                  ],
                ),
              ],

              const Divider(height: 10),

              // Cliente compacto
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      appointment.clientName[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.clientNickname ?? appointment.clientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (appointment.clientNickname != null)
                          Text(
                            appointment.clientName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Notas compactas
              if (appointment.notes != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          appointment.notes!,
                          style: TextStyle(color: Colors.grey[800], fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Temas de conversación compactos
              if (appointment.conversationTopics != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.chat_outlined, size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          appointment.conversationTopics!,
                          style: TextStyle(color: Colors.blue[900], fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Botones compactos
              if (appointment.status == AppointmentStatus.pending ||
                  appointment.status == AppointmentStatus.confirmed) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (appointment.status == AppointmentStatus.pending) ...[
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmAppointment(context),
                            icon: const Icon(Icons.check_circle_outline, size: 14),
                            label: const Text('Confirmar', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: FilledButton.icon(
                          onPressed: () => _completeAppointment(context),
                          icon: const Icon(Icons.done, size: 14),
                          label: const Text('Completar', style: TextStyle(fontSize: 11)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAppointment(BuildContext context) async {
    final appointmentProvider = context.read<AppointmentProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        title: const Text('Confirmar cita', style: TextStyle(fontSize: 16)),
        content: const Text('¿Deseas confirmar esta cita?', style: TextStyle(fontSize: 10)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
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

    if (confirmed == true && context.mounted) {
      final success = await appointmentProvider.confirmAppointment(appointment.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Cita confirmada' : 'Error al confirmar'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeAppointment(BuildContext context) async {
    final appointmentProvider = context.read<AppointmentProvider>();

    final completed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        title: const Text('Completar cita', style: TextStyle(fontSize: 16)),
        content: const Text('¿El servicio ha sido completado?', style: TextStyle(fontSize: 10)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            child: const Text('No', style: TextStyle(fontSize: 12)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            child: const Text('Sí, completar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );

    if (completed == true && context.mounted) {
      final success = await appointmentProvider.completeAppointment(appointment.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '¡Cita completada!' : 'Error al completar'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

// Tab de perfil del barbero
class _BarberProfileTab extends StatelessWidget {
  final dynamic user;

  const _BarberProfileTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null
                      ? Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.nickname != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '"${user.nickname}"',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Chip(
                  label: Text('Duración de cita: ${user.appointmentDuration ?? 30} min'),
                  avatar: const Icon(Icons.access_time, size: 20),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Configuración'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Próximamente: Configuración')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Ayuda'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Próximamente: Ayuda')),
            );
          },
        ),
      ],
    );
  }
}