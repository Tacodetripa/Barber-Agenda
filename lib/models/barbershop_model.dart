import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa una barbería en el sistema.
///
/// Una barbería es gestionada por un superadministrador y
/// contiene información sobre su ubicación, horarios de trabajo
/// y los días que opera.
///
/// Los barberos se asignan a una barbería específica mediante
/// el campo barbershopId en [UserModel].
class BarbershopModel {
  /// Identificador único de la barbería en Firestore
  final String id;

  /// Nombre comercial de la barbería
  final String name;

  /// Dirección física completa de la barbería
  final String address;

  /// Número de teléfono de contacto de la barbería (opcional)
  final String? phoneNumber;

  /// Latitud de la ubicación geográfica de la barbería
  ///
  /// Utilizada para mostrar la barbería en mapas y calcular rutas
  final double? latitude;

  /// Longitud de la ubicación geográfica de la barbería
  ///
  /// Utilizada para mostrar la barbería en mapas y calcular rutas
  final double? longitude;

  /// UID del usuario superadministrador que creó la barbería
  final String ownerId;

  /// Lista de días en que la barbería opera
  ///
  /// Debe contener nombres de días en inglés en minúsculas:
  /// monday, tuesday, wednesday, thursday, friday, saturday, sunday
  ///
  /// Ejemplo: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']
  final List<String> workingDays;

  /// Hora de apertura de la barbería en formato 24 horas
  ///
  /// Formato: 'HH:mm' (ejemplo: '09:00', '10:30')
  final String openingTime;

  /// Hora de cierre de la barbería en formato 24 horas
  ///
  /// Formato: 'HH:mm' (ejemplo: '18:00', '20:30')
  final String closingTime;

  /// Fecha y hora de creación de la barbería en el sistema
  final DateTime createdAt;

  /// Fecha y hora de la última actualización de la barbería
  final DateTime? updatedAt;

  /// Crea una nueva instancia de [BarbershopModel].
  ///
  /// Parámetros requeridos:
  /// - [id]: Identificador único
  /// - [name]: Nombre de la barbería
  /// - [address]: Dirección física
  /// - [ownerId]: UID del administrador
  /// - [workingDays]: Días de operación
  /// - [openingTime]: Hora de apertura
  /// - [closingTime]: Hora de cierre
  /// - [createdAt]: Fecha de creación
  ///
  /// Parámetros opcionales:
  /// - [phoneNumber]: Teléfono de contacto
  /// - [latitude]: Coordenada de latitud
  /// - [longitude]: Coordenada de longitud
  /// - [updatedAt]: Fecha de última actualización
  BarbershopModel({
    required this.id,
    required this.name,
    required this.address,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    required this.ownerId,
    required this.workingDays,
    required this.openingTime,
    required this.closingTime,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convierte el modelo a un Map para guardarlo en Firestore.
  ///
  /// Todos los campos se convierten a tipos compatibles con Firestore:
  /// - DateTime se convierte a Timestamp
  /// - double? mantiene el valor o null
  ///
  /// Retorna un Map<String, dynamic> listo para guardar.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
      'ownerId': ownerId,
      'workingDays': workingDays,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Crea una instancia de [BarbershopModel] desde un Map de Firestore.
  ///
  /// [map] debe contener los campos del documento de Firestore.
  /// Los campos faltantes se reemplazan con valores por defecto.
  ///
  /// Conversiones especiales:
  /// - Timestamp se convierte a DateTime
  /// - workingDays se convierte de lista dinámica a List<String>
  /// - latitude y longitude se convierten a double
  ///
  /// Retorna un nuevo [BarbershopModel] con los datos del Map.
  factory BarbershopModel.fromMap(Map<String, dynamic> map) {
    return BarbershopModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phoneNumber: map['phoneNumber'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      ownerId: map['ownerId'] ?? '',
      workingDays: List<String>.from(map['workingDays'] ?? []),
      openingTime: map['openingTime'] ?? '09:00',
      closingTime: map['closingTime'] ?? '18:00',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Crea una copia del modelo con algunos campos modificados.
  ///
  /// Útil para actualizar información de la barbería sin crear
  /// una nueva instancia desde cero.
  ///
  /// Solo los parámetros proporcionados serán actualizados,
  /// el resto mantendrá sus valores originales.
  ///
  /// Ejemplo:
  /// ```dart
  /// final updatedBarbershop = barbershop.copyWith(
  ///   openingTime: '08:00',
  ///   closingTime: '20:00',
  ///   updatedAt: DateTime.now(),
  /// );
  /// ```
  BarbershopModel copyWith({
    String? id,
    String? name,
    String? address,
    String? phoneNumber,
    double? latitude,
    double? longitude,
    String? ownerId,
    List<String>? workingDays,
    String? openingTime,
    String? closingTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BarbershopModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ownerId: ownerId ?? this.ownerId,
      workingDays: workingDays ?? this.workingDays,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}