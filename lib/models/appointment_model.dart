import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados posibles de una cita en el sistema.
enum AppointmentStatus {
  /// Cita creada pero aún no confirmada por el barbero
  pending,

  /// Cita confirmada por el barbero y lista para atender
  confirmed,

  /// Cita completada exitosamente
  completed,

  /// Cita cancelada por el cliente o el barbero
  cancelled,
}

/// Modelo que representa una cita agendada en el sistema.
///
/// Una cita conecta a un cliente con un barbero en una fecha y hora específicas.
/// Incluye información completa de ambas partes, la barbería donde se realizará,
/// y campos opcionales para notas y temas de conversación.
class AppointmentModel {
  /// Identificador único de la cita en Firestore
  final String id;

  /// UID del cliente que agendó la cita
  final String clientId;

  /// Nombre completo del cliente
  final String clientName;

  /// Apodo del cliente (si tiene configurado)
  ///
  /// Se muestra en lugar del nombre si está disponible
  final String? clientNickname;

  /// UID del barbero que atenderá la cita
  final String barberId;

  /// Nombre completo del barbero
  final String barberName;

  /// ID de la barbería donde se realizará la cita
  final String barbershopId;

  /// Nombre de la barbería donde se realizará la cita
  final String barbershopName;

  /// Fecha de la cita (solo fecha, sin hora)
  final DateTime appointmentDate;

  /// Hora de la cita en formato de texto
  ///
  /// Puede estar en formato 12h ('10:00 AM') o 24h ('10:00')
  final String appointmentTime;

  /// Estado actual de la cita
  final AppointmentStatus status;

  /// Notas opcionales del cliente sobre el servicio deseado
  ///
  /// Ejemplo: "Corte degradado, barba recortada"
  final String? notes;

  /// Temas opcionales de conversación sugeridos por el cliente
  ///
  /// Ejemplo: "Fútbol, música, películas"
  final String? conversationTopics;

  /// Fecha y hora de creación de la cita
  final DateTime createdAt;

  /// Fecha y hora de la última actualización de la cita
  final DateTime? updatedAt;

  /// Crea una nueva instancia de [AppointmentModel].
  ///
  /// Parámetros requeridos:
  /// - [id]: Identificador único
  /// - [clientId]: UID del cliente
  /// - [clientName]: Nombre del cliente
  /// - [barberId]: UID del barbero
  /// - [barberName]: Nombre del barbero
  /// - [barbershopId]: ID de la barbería
  /// - [barbershopName]: Nombre de la barbería
  /// - [appointmentDate]: Fecha de la cita
  /// - [appointmentTime]: Hora de la cita
  /// - [status]: Estado de la cita
  /// - [createdAt]: Fecha de creación
  ///
  /// Parámetros opcionales:
  /// - [clientNickname]: Apodo del cliente
  /// - [notes]: Notas del servicio
  /// - [conversationTopics]: Temas de conversación
  /// - [updatedAt]: Fecha de actualización
  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientNickname,
    required this.barberId,
    required this.barberName,
    required this.barbershopId,
    required this.barbershopName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.notes,
    this.conversationTopics,
    required this.createdAt,
    this.updatedAt,
  });

  /// Retorna el nombre a mostrar del cliente en la interfaz.
  ///
  /// Si el cliente tiene [clientNickname] configurado, lo retorna.
  /// De lo contrario, retorna el [clientName].
  String get clientDisplayName => clientNickname ?? clientName;

  /// Combina [appointmentDate] y [appointmentTime] en un solo DateTime.
  ///
  /// Maneja automáticamente formatos de 12 y 24 horas:
  /// - Formato 12h: '10:00 AM', '02:30 PM'
  /// - Formato 24h: '10:00', '14:30'
  ///
  /// En caso de error al parsear, retorna la fecha con hora 00:00.
  ///
  /// Retorna un [DateTime] completo con fecha y hora exactas de la cita.
  DateTime get fullDateTime {
    try {
      final cleanTime = appointmentTime.trim();

      // Detectar si el formato es de 12 horas (AM/PM) o 24 horas
      final is12HourFormat = cleanTime.toUpperCase().contains('AM') ||
          cleanTime.toUpperCase().contains('PM');

      int hour;
      int minute;

      if (is12HourFormat) {
        // Formato 12 horas: convertir a 24 horas
        final isPM = cleanTime.toUpperCase().contains('PM');
        final timeOnly = cleanTime
            .toUpperCase()
            .replaceAll('AM', '')
            .replaceAll('PM', '')
            .trim();

        final parts = timeOnly.split(':');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);

        // Ajustar hora para formato 24h
        if (isPM && hour != 12) {
          hour += 12;
        } else if (!isPM && hour == 12) {
          hour = 0;
        }
      } else {
        // Formato 24 horas: usar directamente
        final parts = cleanTime.split(':');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);
      }

      return DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        hour,
        minute,
      );
    } catch (e) {
      print('Error parsing time "$appointmentTime" for date $appointmentDate: $e');
      // En caso de error, retornar solo la fecha sin hora
      return DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
      );
    }
  }

  /// Convierte el modelo a un Map para guardarlo en Firestore.
  ///
  /// Todos los campos se convierten a tipos compatibles con Firestore:
  /// - DateTime se convierte a Timestamp
  /// - Enum se convierte a String mediante .name
  ///
  /// Retorna un Map<String, dynamic> listo para guardar.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'clientNickname': clientNickname,
      'barberId': barberId,
      'barberName': barberName,
      'barbershopId': barbershopId,
      'barbershopName': barbershopName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentTime': appointmentTime,
      'status': status.name,
      'notes': notes,
      'conversationTopics': conversationTopics,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Crea una instancia de [AppointmentModel] desde un Map de Firestore.
  ///
  /// [map] debe contener los campos del documento de Firestore.
  /// Los campos faltantes se reemplazan con valores por defecto.
  ///
  /// Conversiones especiales:
  /// - Timestamp se convierte a DateTime
  /// - String de status se convierte a enum AppointmentStatus
  ///
  /// Retorna un nuevo [AppointmentModel] con los datos del Map.
  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientNickname: map['clientNickname'],
      barberId: map['barberId'] ?? '',
      barberName: map['barberName'] ?? '',
      barbershopId: map['barbershopId'] ?? '',
      barbershopName: map['barbershopName'] ?? '',
      appointmentDate: (map['appointmentDate'] as Timestamp).toDate(),
      appointmentTime: map['appointmentTime'] ?? '',
      status: AppointmentStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      notes: map['notes'],
      conversationTopics: map['conversationTopics'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Crea una copia del modelo con algunos campos modificados.
  ///
  /// Útil para cambiar el estado de la cita o actualizar información
  /// sin crear una nueva instancia desde cero.
  ///
  /// Solo los parámetros proporcionados serán actualizados,
  /// el resto mantendrá sus valores originales.
  ///
  /// Ejemplo:
  /// ```dart
  /// final confirmedAppointment = appointment.copyWith(
  ///   status: AppointmentStatus.confirmed,
  ///   updatedAt: DateTime.now(),
  /// );
  /// ```
  AppointmentModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientNickname,
    String? barberId,
    String? barberName,
    String? barbershopId,
    String? barbershopName,
    DateTime? appointmentDate,
    String? appointmentTime,
    AppointmentStatus? status,
    String? notes,
    String? conversationTopics,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientNickname: clientNickname ?? this.clientNickname,
      barberId: barberId ?? this.barberId,
      barberName: barberName ?? this.barberName,
      barbershopId: barbershopId ?? this.barbershopId,
      barbershopName: barbershopName ?? this.barbershopName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      conversationTopics: conversationTopics ?? this.conversationTopics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}