import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../shared/edit_appointment_screen.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
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

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser!;
    final isBarber = currentUser.role == UserRole.barber;
    final isClient = currentUser.role == UserRole.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la Cita'),
        actions: [
          if (appointment.status != AppointmentStatus.cancelled &&
              appointment.status != AppointmentStatus.completed)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: () => _cancelAppointment(context),
              tooltip: 'Cancelar cita',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header compacto
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(appointment.status).withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: _getStatusColor(appointment.status).withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(appointment.status),
                    size: 48,
                    color: _getStatusColor(appointment.status),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusText(appointment.status),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _getStatusColor(appointment.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fecha y hora
                  _SectionCard(
                    icon: Icons.event,
                    title: 'Fecha y Hora',
                    children: [
                      _InfoRow(
                        icon: Icons.calendar_today,
                        label: 'Fecha',
                        value: DateFormat('EEEE, d MMMM yyyy').format(appointment.appointmentDate),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.access_time,
                        label: 'Hora',
                        value: appointment.appointmentTime,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Información del barbero
                  if (isClient)
                    _SectionCard(
                      icon: Icons.person,
                      title: 'Barbero',
                      children: [
                        _InfoRow(
                          icon: Icons.badge,
                          label: 'Nombre',
                          value: appointment.barberName,
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.store,
                          label: 'Barbería',
                          value: appointment.barbershopName,
                        ),
                      ],
                    ),

                  // Información del cliente
                  if (isBarber)
                    _SectionCard(
                      icon: Icons.person_outline,
                      title: 'Cliente',
                      children: [
                        _InfoRow(
                          icon: Icons.badge,
                          label: 'Nombre',
                          value: appointment.clientNickname ?? appointment.clientName,
                        ),
                        if (appointment.clientNickname != null) ...[
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.person,
                            label: 'Nombre completo',
                            value: appointment.clientName,
                          ),
                        ],
                      ],
                    ),

                  const SizedBox(height: 12),

                  // Notas
                  if (appointment.notes != null) ...[
                    _SectionCard(
                      icon: Icons.note,
                      title: 'Notas',
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            appointment.notes!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Temas de conversación
                  if (appointment.conversationTopics != null) ...[
                    _SectionCard(
                      icon: Icons.chat,
                      title: 'Temas de Conversación',
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            appointment.conversationTopics!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Información adicional
                  _SectionCard(
                    icon: Icons.info_outline,
                    title: 'Información',
                    children: [
                      _InfoRow(
                        icon: Icons.tag,
                        label: 'ID de cita',
                        value: appointment.id.substring(0, 8),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.calendar_month,
                        label: 'Creada',
                        value: DateFormat('d MMM yyyy, HH:mm').format(appointment.createdAt),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Botón de editar
                  if ((isClient || isBarber) &&
                      (appointment.status == AppointmentStatus.pending ||
                          appointment.status == AppointmentStatus.confirmed)) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditAppointmentScreen(
                                appointment: appointment,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Editar Cita' , style: TextStyle(fontSize: 10),),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Botones adicionales - SOLO PARA BARBERO
                  if (isBarber &&
                      (appointment.status == AppointmentStatus.pending ||
                          appointment.status == AppointmentStatus.confirmed))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (appointment.status == AppointmentStatus.pending)
                          SizedBox(
                            height: 45,
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmAppointment(context),
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text('Confirmar Cita', style: TextStyle(fontSize: 10),),
                            ),
                          ),
                        if (appointment.status == AppointmentStatus.pending) const SizedBox(height: 10),
                        SizedBox(
                          height: 45,
                          child: FilledButton.icon(
                            onPressed: () => _completeAppointment(context),
                            icon: const Icon(Icons.done, size: 18),
                            label: const Text('Marcar como Completada', style: TextStyle(fontSize: 10),),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAppointment(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        title: const Text('Confirmar cita', style: TextStyle(fontSize: 16)),
        content: const Text('¿Deseas confirmar esta cita?', style: TextStyle(fontSize: 13)),
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
      final appointmentProvider = context.read<AppointmentProvider>();
      final success = await appointmentProvider.confirmAppointment(appointment.id);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita confirmada'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al confirmar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeAppointment(BuildContext context) async {
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
      final appointmentProvider = context.read<AppointmentProvider>();
      final success = await appointmentProvider.completeAppointment(appointment.id);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cita completada!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al completar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelAppointment(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        title: const Text('Cancelar cita', style: TextStyle(fontSize: 16)),
        content: const Text(
          '¿Estás seguro de que quieres cancelar esta cita? Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 10),
        ),
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
            child: const Text('Sí, cancelar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final appointmentProvider = context.read<AppointmentProvider>();
      final success = await appointmentProvider.cancelAppointment(appointment.id);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita cancelada'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al cancelar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// Widget para las secciones con tarjeta (COMPACTO)
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

// Widget para filas de información (COMPACTO)
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}