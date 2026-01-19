import 'dart:async';
import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

/// Provider para gestionar el estado de las citas en la aplicación.
///
/// Utiliza [ChangeNotifier] para notificar cambios a los widgets que escuchan.
/// Maneja operaciones CRUD de citas y proporciona filtros para diferentes vistas
/// (cliente, barbero, superadmin).
///
/// Implementa suscripciones en tiempo real a Firestore para mantener
/// los datos actualizados automáticamente.
class AppointmentProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  /// Lista de citas cargadas actualmente
  List<AppointmentModel> _appointments = [];

  /// Indica si se está realizando una operación asíncrona
  bool _isLoading = false;

  /// Mensaje de error actual, null si no hay errores
  String? _errorMessage;

  /// Suscripción activa al stream de citas de Firestore
  StreamSubscription<List<AppointmentModel>>? _appointmentsSubscription;

  /// ID del usuario para el cual se están cargando las citas actualmente
  String? _currentUserId;

  /// Obtiene la lista de citas actual
  List<AppointmentModel> get appointments => _appointments;

  /// Indica si hay una operación en progreso
  bool get isLoading => _isLoading;

  /// Obtiene el mensaje de error actual
  String? get errorMessage => _errorMessage;

  /// Carga las citas de un cliente específico en tiempo real.
  ///
  /// [clientId] es el UID del cliente.
  ///
  /// Establece una suscripción a Firestore que se actualiza automáticamente
  /// cuando hay cambios en las citas del cliente.
  /// Si ya existe una suscripción para este cliente, no hace nada.
  void loadClientAppointments(String clientId) {
    // Si ya estamos escuchando a este usuario, no hacer nada
    if (_currentUserId == clientId && _appointmentsSubscription != null) {
      return;
    }

    // Cancelar suscripción anterior
    _appointmentsSubscription?.cancel();
    _currentUserId = clientId;

    // Nueva suscripción
    _appointmentsSubscription = _firestoreService.getClientAppointments(clientId).listen(
          (appointments) {
        print('Cliente: Citas actualizadas: ${appointments.length}');
        _appointments = appointments;
        notifyListeners();
      },
      onError: (error) {
        print('Error al cargar citas del cliente: $error');
        _errorMessage = 'Error al cargar citas';
        notifyListeners();
      },
    );
  }

  /// Carga las citas de un barbero específico en tiempo real.
  ///
  /// [barberId] es el UID del barbero.
  ///
  /// Establece una suscripción a Firestore que se actualiza automáticamente
  /// cuando hay cambios en las citas del barbero.
  /// Si ya existe una suscripción para este barbero, no hace nada.
  void loadBarberAppointments(String barberId) {
    // Si ya estamos escuchando a este usuario, no hacer nada
    if (_currentUserId == barberId && _appointmentsSubscription != null) {
      return;
    }

    // Cancelar suscripción anterior
    _appointmentsSubscription?.cancel();
    _currentUserId = barberId;

    // Nueva suscripción
    _appointmentsSubscription = _firestoreService.getBarberAppointments(barberId).listen(
          (appointments) {
        print('Barbero: Citas actualizadas: ${appointments.length}');
        _appointments = appointments;
        notifyListeners();
      },
      onError: (error) {
        print('Error al cargar citas del barbero: $error');
        _errorMessage = 'Error al cargar citas';
        notifyListeners();
      },
    );
  }

  /// Carga las citas de un barbero para una fecha específica en tiempo real.
  ///
  /// [barberId] es el UID del barbero.
  /// [date] es la fecha para la cual se cargarán las citas.
  ///
  /// Útil para vistas de calendario donde solo se muestran citas de un día.
  void loadBarberAppointmentsByDate(String barberId, DateTime date) {
    // Cancelar suscripción anterior
    _appointmentsSubscription?.cancel();
    _currentUserId = '$barberId-$date';

    _appointmentsSubscription = _firestoreService.getBarberAppointmentsByDate(barberId, date).listen(
          (appointments) {
        print('Barbero (fecha): Citas actualizadas: ${appointments.length}');
        _appointments = appointments;
        notifyListeners();
      },
      onError: (error) {
        print('Error al cargar citas del barbero por fecha: $error');
        _errorMessage = 'Error al cargar citas';
        notifyListeners();
      },
    );
  }

  /// Carga todas las citas del sistema en tiempo real (solo SuperAdmin).
  ///
  /// Establece una suscripción a Firestore que obtiene todas las citas
  /// sin filtros, permitiendo al superadministrador ver todas las citas.
  /// Si ya existe una suscripción a todas las citas, no hace nada.
  void loadAllAppointments() {
    // Si ya estamos escuchando todas, no hacer nada
    if (_currentUserId == 'all' && _appointmentsSubscription != null) {
      return;
    }

    // Cancelar suscripción anterior
    _appointmentsSubscription?.cancel();
    _currentUserId = 'all';

    _appointmentsSubscription = _firestoreService.getAllAppointments().listen(
          (appointments) {
        print('SuperAdmin: Citas actualizadas: ${appointments.length}');
        _appointments = appointments;
        notifyListeners();
      },
      onError: (error) {
        print('Error al cargar todas las citas: $error');
        _errorMessage = 'Error al cargar citas';
        notifyListeners();
      },
    );
  }

  /// Limpia todas las citas y cancela suscripciones activas.
  ///
  /// Se debe llamar al cerrar sesión para liberar recursos y
  /// evitar que se sigan escuchando actualizaciones de Firestore.
  void clearAppointments() {
    _appointmentsSubscription?.cancel();
    _appointmentsSubscription = null;
    _currentUserId = null;
    _appointments = [];
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    super.dispose();
  }

  /// Crea una nueva cita en el sistema.
  ///
  /// Verifica automáticamente la disponibilidad del horario antes de crear la cita.
  /// Si el horario no está disponible, retorna false y establece un mensaje de error.
  ///
  /// Parámetros requeridos:
  /// - [clientId]: UID del cliente
  /// - [clientName]: Nombre completo del cliente
  /// - [barberId]: UID del barbero
  /// - [barberName]: Nombre completo del barbero
  /// - [barbershopId]: ID de la barbería
  /// - [barbershopName]: Nombre de la barbería
  /// - [appointmentDate]: Fecha de la cita
  /// - [appointmentTime]: Hora de la cita en formato texto
  ///
  /// Parámetros opcionales:
  /// - [clientNickname]: Apodo del cliente
  /// - [notes]: Notas sobre el servicio deseado
  /// - [conversationTopics]: Temas de conversación sugeridos
  ///
  /// Retorna true si la cita se creó exitosamente, false en caso contrario.
  Future<bool> createAppointment({
    required String clientId,
    required String clientName,
    String? clientNickname,
    required String barberId,
    required String barberName,
    required String barbershopId,
    required String barbershopName,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? notes,
    String? conversationTopics,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Verificar disponibilidad del horario
      final isAvailable = await _firestoreService.isTimeSlotAvailable(
        barberId: barberId,
        date: appointmentDate,
        time: appointmentTime,
      );

      if (!isAvailable) {
        _errorMessage = 'Este horario ya no está disponible';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final appointment = AppointmentModel(
        id: '',
        clientId: clientId,
        clientName: clientName,
        clientNickname: clientNickname,
        barberId: barberId,
        barberName: barberName,
        barbershopId: barbershopId,
        barbershopName: barbershopName,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        status: AppointmentStatus.pending,
        notes: notes,
        conversationTopics: conversationTopics,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createAppointment(appointment);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Actualiza el estado de una cita.
  ///
  /// [appointmentId] es el ID de la cita a actualizar.
  /// [status] es el nuevo estado de la cita.
  ///
  /// Retorna true si se actualizó correctamente, false en caso contrario.
  Future<bool> updateAppointmentStatus(
      String appointmentId,
      AppointmentStatus status,
      ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.updateAppointmentStatus(appointmentId, status);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cancela una cita cambiando su estado a cancelada.
  ///
  /// [appointmentId] es el ID de la cita a cancelar.
  ///
  /// Retorna true si se canceló correctamente, false en caso contrario.
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.cancelAppointment(appointmentId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Obtiene las citas de hoy de un barbero específico.
  ///
  /// [barberId] es el UID del barbero.
  ///
  /// Filtra las citas por fecha actual y excluye las canceladas.
  /// Retorna una lista ordenada por hora de la cita.
  List<AppointmentModel> getTodayAppointments(String barberId) {
    final today = DateTime.now();
    return _appointments.where((appointment) {
      return appointment.barberId == barberId &&
          appointment.appointmentDate.year == today.year &&
          appointment.appointmentDate.month == today.month &&
          appointment.appointmentDate.day == today.day &&
          appointment.status != AppointmentStatus.cancelled;
    }).toList()
      ..sort((a, b) => a.appointmentTime.compareTo(b.appointmentTime));
  }

  /// Obtiene las próximas citas de un cliente.
  ///
  /// [clientId] es el UID del cliente.
  ///
  /// Filtra las citas que:
  /// - Pertenecen al cliente
  /// - Están en estado pending o confirmed
  /// - Son en el futuro o están ocurriendo ahora
  ///
  /// Retorna una lista ordenada cronológicamente.
  List<AppointmentModel> getUpcomingAppointments(String clientId) {
    final now = DateTime.now();

    return _appointments.where((appointment) {
      // Verificar que pertenezca al cliente
      final isMyAppointment = appointment.clientId == clientId;

      // Solo mostrar citas activas
      final isActiveStatus = appointment.status == AppointmentStatus.pending ||
          appointment.status == AppointmentStatus.confirmed;

      // Verificar que sea a futuro (incluyendo HOY)
      try {
        final appointmentDateTime = appointment.fullDateTime;

        // Comparar si la cita es después o en el mismo momento
        final isFuture = appointmentDateTime.isAfter(now) ||
            appointmentDateTime.isAtSameMomentAs(now);

        // Logs de depuración
        if (isMyAppointment && isActiveStatus) {
          print('   Cita: ${appointment.appointmentTime} del ${DateFormat('dd/MM').format(appointment.appointmentDate)}');
          print('   fullDateTime: $appointmentDateTime');
          print('   now: $now');
          print('   Diferencia: ${appointmentDateTime.difference(now).inMinutes} minutos');
          print('   ¿Es futuro?: $isFuture');
        }

        return isMyAppointment && isActiveStatus && isFuture;
      } catch (e) {
        print('Error al parsear fecha de cita: $e');
        return false;
      }
    }).toList()
      ..sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime));
  }

  /// Limpia el mensaje de error actual.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Obtiene las citas de un barbero para una fecha específica.
  ///
  /// [barberId] es el UID del barbero.
  /// [date] es la fecha para la cual se filtrarán las citas.
  ///
  /// Retorna una lista de citas del día, excluyendo las canceladas,
  /// ordenadas cronológicamente.
  List<AppointmentModel> getBarberAppointmentsByDate(String barberId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _appointments.where((appointment) {
      return appointment.barberId == barberId &&
          appointment.appointmentDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          appointment.appointmentDate.isBefore(endOfDay.add(const Duration(seconds: 1))) &&
          appointment.status != AppointmentStatus.cancelled;
    }).toList()
      ..sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime));
  }

  /// Obtiene las citas del día actual de un barbero.
  ///
  /// [barberId] es el UID del barbero.
  ///
  /// Es un atajo para [getBarberAppointmentsByDate] con la fecha actual.
  List<AppointmentModel> getBarberTodayAppointments(String barberId) {
    return getBarberAppointmentsByDate(barberId, DateTime.now());
  }

  /// Obtiene las citas futuras de un barbero (excluyendo el día de hoy).
  ///
  /// [barberId] es el UID del barbero.
  ///
  /// Retorna una lista de citas posteriores al día actual,
  /// excluyendo las canceladas, ordenadas cronológicamente.
  List<AppointmentModel> getBarberUpcomingAppointments(String barberId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _appointments.where((appointment) {
      final appointmentDay = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
      );

      return appointment.barberId == barberId &&
          appointmentDay.isAfter(today) &&
          appointment.status != AppointmentStatus.cancelled;
    }).toList()
      ..sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime));
  }

  /// Marca una cita como completada.
  ///
  /// [appointmentId] es el ID de la cita a marcar como completada.
  ///
  /// Retorna true si se actualizó correctamente, false en caso contrario.
  Future<bool> completeAppointment(String appointmentId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestoreService.updateAppointmentStatus(
        appointmentId,
        AppointmentStatus.completed,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Confirma una cita cambiando su estado a confirmed.
  ///
  /// [appointmentId] es el ID de la cita a confirmar.
  ///
  /// Retorna true si se actualizó correctamente, false en caso contrario.
  Future<bool> confirmAppointment(String appointmentId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestoreService.updateAppointmentStatus(
        appointmentId,
        AppointmentStatus.confirmed,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtiene el historial de citas de un cliente (completadas y canceladas).
  ///
  /// [clientId] es el UID del cliente.
  ///
  /// Retorna una lista de citas finalizadas (completadas o canceladas),
  /// ordenadas de más reciente a más antigua.
  List<AppointmentModel> getClientHistory(String clientId) {
    return _appointments.where((appointment) {
      return appointment.clientId == clientId &&
          (appointment.status == AppointmentStatus.completed ||
              appointment.status == AppointmentStatus.cancelled);
    }).toList()
      ..sort((a, b) => b.fullDateTime.compareTo(a.fullDateTime));
  }

  /// Obtiene el historial de citas de un barbero (completadas y canceladas).
  ///
  /// [barberId] es el UID del barbero.
  ///
  /// Retorna una lista de citas finalizadas (completadas o canceladas),
  /// ordenadas de más reciente a más antigua.
  List<AppointmentModel> getBarberHistory(String barberId) {
    return _appointments.where((appointment) {
      return appointment.barberId == barberId &&
          (appointment.status == AppointmentStatus.completed ||
              appointment.status == AppointmentStatus.cancelled);
    }).toList()
      ..sort((a, b) => b.fullDateTime.compareTo(a.fullDateTime));
  }
}