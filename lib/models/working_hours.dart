import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa el horario de trabajo de un barbero para un día específico.
///
/// Incluye la hora de apertura, cierre, y si trabaja o no ese día.
/// Proporciona métodos para calcular duración y validar disponibilidad.
class WorkingHours {
  /// Hora de inicio del turno en formato 24h (HH:mm).
  ///
  /// Ejemplo: "09:00", "14:30"
  final String openingTime;

  /// Hora de fin del turno en formato 24h (HH:mm).
  ///
  /// Ejemplo: "18:00", "22:30"
  final String closingTime;

  /// Indica si el barbero trabaja este día.
  ///
  /// Si es `false`, [openingTime] y [closingTime] son ignorados.
  final bool isWorking;

  /// Crea una nueva instancia de [WorkingHours].
  ///
  /// [openingTime] y [closingTime] deben estar en formato HH:mm.
  /// [isWorking] es `true` por defecto.
  WorkingHours({
    required this.openingTime,
    required this.closingTime,
    this.isWorking = true,
  });

  /// Convierte el horario a un Map para guardarlo en Firestore.
  ///
  /// Retorna un [Map] con los campos openingTime, closingTime e isWorking.
  Map<String, dynamic> toMap() {
    return {
      'openingTime': openingTime,
      'closingTime': closingTime,
      'isWorking': isWorking,
    };
  }

  /// Crea una instancia de [WorkingHours] desde un Map de Firestore.
  ///
  /// [map] debe contener los campos openingTime, closingTime e isWorking.
  /// Si algún campo falta, se usan valores por defecto.
  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      openingTime: map['openingTime'] ?? '09:00',
      closingTime: map['closingTime'] ?? '18:00',
      isWorking: map['isWorking'] ?? true,
    );
  }

  /// Crea una copia del horario con algunos campos modificados.
  ///
  /// Solo los campos proporcionados serán actualizados.
  WorkingHours copyWith({
    String? openingTime,
    String? closingTime,
    bool? isWorking,
  }) {
    return WorkingHours(
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      isWorking: isWorking ?? this.isWorking,
    );
  }

  /// Calcula la duración del turno en horas.
  ///
  /// Retorna la cantidad de horas entre [openingTime] y [closingTime].
  /// Si [isWorking] es `false`, retorna 0.
  ///
  /// Ejemplo: De 09:00 a 17:00 = 8.0 horas
  double getDurationInHours() {
    if (!isWorking) return 0;

    final opening = _parseTime(openingTime);
    final closing = _parseTime(closingTime);

    return (closing - opening) / 60;
  }

  /// Verifica si una hora específica está dentro del horario laboral.
  ///
  /// [time] debe estar en formato HH:mm (ejemplo: "14:30").
  ///
  /// Retorna `true` si la hora está entre [openingTime] y [closingTime]
  /// (sin incluir la hora de cierre), y [isWorking] es `true`.
  bool isTimeAvailable(String time) {
    if (!isWorking) return false;

    final timeMinutes = _parseTime(time);
    final openMinutes = _parseTime(openingTime);
    final closeMinutes = _parseTime(closingTime);

    return timeMinutes >= openMinutes && timeMinutes < closeMinutes;
  }

  /// Convierte una hora en formato HH:mm a minutos desde medianoche.
  ///
  /// [time] debe estar en formato HH:mm.
  ///
  /// Retorna la cantidad de minutos desde las 00:00.
  /// Ejemplo: "14:30" = 870 minutos
  int _parseTime(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  @override
  String toString() {
    if (!isWorking) return 'No trabaja';
    return '$openingTime - $closingTime';
  }
}