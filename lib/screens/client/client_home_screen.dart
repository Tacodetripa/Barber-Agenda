import '../shared/appointment_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/appointment_model.dart';
import 'select_barber_screen.dart';
import 'select_barbershop_screen.dart'; // ← Nueva pantalla
import '../../utils/page_transitions.dart';
import '../../widgets/empty_state_widget.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen>
    with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;

  @override
  bool get wantKeepAlive => true;

  void _navigateToCreateAppointment() async {
    // Navegar a la pantalla de selección de barberías
    await Navigator.push(
      context,
      PageTransitions.slideFromRight(
        const SelectBarbershopScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Importante para AutomaticKeepAliveClientMixin
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barber Agenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  title: const Text('Cerrar Sesión', style: TextStyle(fontSize: 16)),
                  content: const Text('¿Estás seguro que deseas cerrar sesión?', style: TextStyle(fontSize: 13)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      child: const Text('Cerrar Sesión', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await authProvider.signOut();
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(user),
          _buildAppointmentsTab(),
          _buildHistoryTab(user),
          _buildProfileTab(user),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Mis Citas',
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

  Widget _buildHomeTab(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saludo
          Text(
            '¡Hola, ${user?.displayName ?? 'Usuario'}!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '¿Listo para tu próximo corte?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),

          // Card de acción rápida
          Card(
            child: InkWell(
              onTap: _navigateToCreateAppointment,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.content_cut,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Agendar Cita',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Encuentra tu barbero ideal',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 8),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 9),

          // Próximas citas
          Text(
            'Próximas Citas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          // Lista optimizada de citas
          Consumer<AppointmentProvider>(
            builder: (context, provider, _) {
              final upcomingAppointments = provider.getUpcomingAppointments(user?.uid ?? '');

              if (upcomingAppointments.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.event_available,
                  title: 'No tienes citas próximas',
                  subtitle: 'Agenda tu próxima cita con tu barbero favorito',
                  actionText: 'Agendar Cita',
                  onActionPressed: _navigateToCreateAppointment,
                  iconColor: const Color(0xFFC5A572), // Oro
                );
              }

              return Column(
                children: upcomingAppointments.take(3).map((appointment) {
                  return _buildAppointmentCard(appointment);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, _) {
        if (provider.appointments.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.calendar_month,
            title: 'Sin citas agendadas',
            subtitle: 'Comienza agendando tu primera cita',
            actionText: 'Agendar Cita',
            onActionPressed: _navigateToCreateAppointment,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.appointments.length,
          itemBuilder: (context, index) {
            final appointment = provider.appointments[index];
            return _buildAppointmentCard(appointment);
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final now = DateTime.now();

    // ARREGLADO: Verificar si es futuro (incluyendo HOY)
    bool isUpcoming = false;
    try {
      final appointmentDateTime = appointment.fullDateTime;
      isUpcoming = appointmentDateTime.isAfter(now) ||
          appointmentDateTime.isAtSameMomentAs(now);

      // Debug
      /*print('🔍 Card - ${appointment.appointmentTime} del ${DateFormat('dd/MM').format(appointment.appointmentDate)}');
      print('   fullDateTime: $appointmentDateTime');
      print('   now: $now');
      print('   Diferencia: ${appointmentDateTime.difference(now).inMinutes} minutos');
      print('   isUpcoming: $isUpcoming');*/
    } catch (e) {
      print('❌ Error al verificar si es upcoming: $e');
      isUpcoming = false;
    }

    final isPending = appointment.status == AppointmentStatus.pending;

    Color statusColor;
    String statusText;

    switch (appointment.status) {
      case AppointmentStatus.pending:
        statusColor = Colors.orange;
        statusText = 'PENDIENTE';
        break;
      case AppointmentStatus.confirmed:
        statusColor = Colors.blue;
        statusText = 'CONFIRMADA';
        break;
      case AppointmentStatus.completed:
        statusColor = Colors.green;
        statusText = 'COMPLETADA';
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'CANCELADA';
        break;
    }

    return Card(
      key: ValueKey(appointment.id),
      margin: const EdgeInsets.only(bottom: 10),
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
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.content_cut,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.barberName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          appointment.barbershopName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 10, color: Colors.grey[600]),
                            const SizedBox(width: 2),
                            Text(
                              DateFormat('dd/MM/yyyy').format(appointment.appointmentDate),
                              style: const TextStyle(fontSize: 8),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.access_time, size: 11, color: Colors.grey[600]),
                            const SizedBox(width: 2),
                            Text(
                              appointment.appointmentTime,
                              style: const TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (isUpcoming && isPending) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelAppointment(appointment.id),
                    icon: const Icon(Icons.cancel, size: 14),
                    label: const Text('Cancelar', style: TextStyle(fontSize: 10),),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        title: const Text('Cancelar Cita', style: TextStyle(fontSize: 16)),
        content: const Text('¿Estás seguro que deseas cancelar esta cita?', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            child: const Text('No', style: TextStyle(fontSize: 12)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Sí, Cancelar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<AppointmentProvider>().cancelAppointment(appointmentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Cita cancelada' : 'Error al cancelar cita'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfileTab(user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar y nombre
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null
                    ? Icon(
                  Icons.person,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary,
                )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                user?.fullName ?? 'Usuario',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (user?.nickname != null) ...[
                const SizedBox(height: 4),
                Text(
                  '"${user?.nickname}"',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Opciones
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar Perfil'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Próximamente: Editar perfil')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notificaciones'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Próximamente: Notificaciones')),
                  );
                },
              ),
              const Divider(height: 1),
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
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(user) {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, _) {
        final historyAppointments = provider.getClientHistory(user?.uid ?? '');

        if (historyAppointments.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.history,
            title: 'Sin historial',
            subtitle: 'Tus citas completadas y canceladas aparecerán aquí',
            iconColor: Colors.grey,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: historyAppointments.length,
          itemBuilder: (context, index) {
            final appointment = historyAppointments[index];
            return _buildAppointmentCard(appointment);
          },
        );
      },
    );
  }
}