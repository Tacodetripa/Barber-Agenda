import 'package:cloud_firestore/cloud_firestore.dart';
import 'working_hours.dart';

/// Roles disponibles en el sistema Barber Agenda.
enum UserRole {
  /// Usuario administrador con acceso total al sistema para gestionar
  /// barberías, barberos y todas las citas
  superadmin,

  /// Usuario barbero que atiende citas y tiene horarios configurables
  barber,

  /// Usuario cliente que puede agendar citas con los barberos
  client,
}

/// Modelo que representa un usuario del sistema Barber Agenda.
///
/// Un usuario puede tener uno de tres roles: superadmin, barber o client.
/// Cada rol tiene diferentes permisos y funcionalidades en la aplicación.
///
/// Este modelo incluye toda la información del usuario y métodos
/// para convertir entre objetos Dart y documentos de Firestore.
class UserModel {
  /// Identificador único del usuario en Firebase Authentication
  final String uid;

  /// Correo electrónico del usuario
  final String email;

  /// Nombre(s) del usuario
  final String firstName;

  /// Apellido(s) del usuario
  final String lastName;

  /// Apodo o nickname opcional del usuario
  ///
  /// Si está configurado, se mostrará en lugar del nombre completo
  final String? nickname;

  /// URL de la foto de perfil del usuario
  ///
  /// Puede ser de Google Sign-In o subida por el usuario
  final String? photoUrl;

  /// Rol del usuario en el sistema
  final UserRole role;

  /// ID de la barbería a la que pertenece el barbero
  ///
  /// Solo aplica para usuarios con rol [UserRole.barber]
  final String? barbershopId;

  /// Duración de cada cita en minutos
  ///
  /// Define cuánto tiempo toma atender a un cliente.
  /// Solo aplica para usuarios con rol [UserRole.barber].
  /// Valores comunes: 30, 45, 60, 90
  final int? appointmentDuration;

  /// Horario personalizado por día de la semana
  ///
  /// Mapa donde la clave es el nombre del día en inglés (monday, tuesday, etc.)
  /// y el valor es un objeto [WorkingHours] con el horario de ese día.
  /// Permite que cada barbero tenga horarios diferentes por día.
  final Map<String, WorkingHours>? customSchedule;

  /// Lista de días en que el barbero trabaja
  ///
  /// Debe contener nombres de días en inglés en minúsculas:
  /// monday, tuesday, wednesday, thursday, friday, saturday, sunday
  final List<String>? workingDays;

  /// Fecha y hora de creación del usuario en el sistema
  final DateTime createdAt;

  /// Fecha y hora de la última actualización del perfil del usuario
  final DateTime? updatedAt;

  /// Crea una nueva instancia de [UserModel].
  ///
  /// Parámetros requeridos:
  /// - [uid]: ID único de Firebase Authentication
  /// - [email]: Correo electrónico del usuario
  /// - [firstName]: Nombre del usuario
  /// - [lastName]: Apellido del usuario
  /// - [role]: Rol asignado al usuario
  /// - [createdAt]: Fecha de creación
  ///
  /// Los demás campos son opcionales y dependen del rol del usuario.
  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.nickname,
    this.photoUrl,
    required this.role,
    this.barbershopId,
    this.appointmentDuration,
    this.customSchedule,
    this.workingDays,
    required this.createdAt,
    this.updatedAt,
  });

  /// Retorna el nombre completo del usuario.
  ///
  /// Concatena [firstName] y [lastName] con un espacio.
  ///
  /// Ejemplo:
  /// ```dart
  /// final user = UserModel(firstName: 'Juan', lastName: 'Pérez', ...);
  /// print(user.fullName); // "Juan Pérez"
  /// ```
  String get fullName => '$firstName $lastName';

  /// Retorna el nombre a mostrar en la interfaz de usuario.
  ///
  /// Si el usuario tiene un [nickname] configurado, lo retorna.
  /// De lo contrario, retorna el [fullName].
  String get displayName => nickname ?? fullName;

  /// Verifica si el barbero trabaja en un día específico.
  ///
  /// [day] debe ser el nombre del día en inglés en minúsculas:
  /// monday, tuesday, wednesday, thursday, friday, saturday, sunday
  ///
  /// Retorna `true` si:
  /// - El día está en la lista [workingDays], o
  /// - [workingDays] es null o está vacía (trabaja todos los días por defecto)
  ///
  /// Ejemplo:
  /// ```dart
  /// if (barber.worksOnDay('monday')) {
  ///   print('El barbero trabaja los lunes');
  /// }
  /// ```
  bool worksOnDay(String day) {
    if (workingDays == null || workingDays!.isEmpty) return true;
    return workingDays!.contains(day.toLowerCase());
  }

  /// Obtiene el horario de trabajo configurado para un día específico.
  ///
  /// [day] debe ser el nombre del día en inglés en minúsculas.
  ///
  /// Retorna el objeto [WorkingHours] con el horario del día,
  /// o null si no hay horario personalizado configurado.
  WorkingHours? getScheduleForDay(String day) {
    if (customSchedule == null) return null;
    return customSchedule![day.toLowerCase()];
  }

  /// Verifica si el barbero está disponible en una fecha y hora específica.
  ///
  /// [dateTime] es la fecha y hora a verificar.
  ///
  /// Realiza las siguientes validaciones:
  /// 1. Verifica que el barbero trabaje ese día de la semana
  /// 2. Obtiene el horario configurado para ese día
  /// 3. Valida que la hora esté dentro del rango de trabajo
  ///
  /// Retorna `true` solo si todas las validaciones pasan.
  bool isAvailableAt(DateTime dateTime) {
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayOfWeek = dateTime.weekday - 1;
    final dayName = dayNames[dayOfWeek];

    if (!worksOnDay(dayName)) return false;

    final schedule = getScheduleForDay(dayName);
    if (schedule == null || !schedule.isWorking) return false;

    final timeString = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return schedule.isTimeAvailable(timeString);
  }

  /// Convierte el modelo a un Map para guardarlo en Firestore.
  ///
  /// Todos los campos se convierten a tipos compatibles con Firestore:
  /// - Objetos DateTime se convierten a Timestamp
  /// - Enums se convierten a String mediante .name
  /// - Maps anidados se convierten recursivamente
  ///
  /// Retorna un Map<String, dynamic> listo para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'nickname': nickname,
      'photoUrl': photoUrl,
      'role': role.name,
      'barbershopId': barbershopId,
      'appointmentDuration': appointmentDuration,
      'customSchedule': customSchedule?.map((day, hours) => MapEntry(day, hours.toMap())),
      'workingDays': workingDays,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Crea una instancia de [UserModel] desde un Map de Firestore.
  ///
  /// [map] debe contener los campos del documento de Firestore.
  /// Los campos faltantes se reemplazan con valores por defecto.
  ///
  /// Conversiones especiales:
  /// - Timestamp se convierte a DateTime
  /// - String de role se convierte a enum UserRole
  /// - Map de customSchedule se convierte a Map<String, WorkingHours>
  /// - Lista de workingDays se convierte a List<String>
  ///
  /// Retorna un nuevo [UserModel] con los datos del Map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Convertir customSchedule de Map a objetos WorkingHours
    Map<String, WorkingHours>? schedule;
    if (map['customSchedule'] != null) {
      final scheduleMap = map['customSchedule'] as Map<String, dynamic>;
      schedule = scheduleMap.map(
            (day, hoursMap) => MapEntry(
          day,
          WorkingHours.fromMap(hoursMap as Map<String, dynamic>),
        ),
      );
    }

    // Convertir workingDays de lista dinámica a List<String>
    List<String>? workingDays;
    if (map['workingDays'] != null) {
      workingDays = List<String>.from(map['workingDays']);
    }

    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      nickname: map['nickname'],
      photoUrl: map['photoUrl'],
      role: UserRole.values.firstWhere(
            (e) => e.name == map['role'],
        orElse: () => UserRole.client,
      ),
      barbershopId: map['barbershopId'],
      appointmentDuration: map['appointmentDuration'],
      customSchedule: schedule,
      workingDays: workingDays,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Crea una copia del modelo con algunos campos modificados.
  ///
  /// Útil para actualizar parcialmente un usuario sin crear
  /// una nueva instancia desde cero.
  ///
  /// Solo los parámetros proporcionados serán actualizados,
  /// el resto mantendrá sus valores originales.
  ///
  /// Ejemplo:
  /// ```dart
  /// final updatedUser = user.copyWith(
  ///   firstName: 'Pedro',
  ///   updatedAt: DateTime.now(),
  /// );
  /// ```
  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? nickname,
    String? photoUrl,
    UserRole? role,
    String? barbershopId,
    int? appointmentDuration,
    Map<String, WorkingHours>? customSchedule,
    List<String>? workingDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nickname: nickname ?? this.nickname,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      barbershopId: barbershopId ?? this.barbershopId,
      appointmentDuration: appointmentDuration ?? this.appointmentDuration,
      customSchedule: customSchedule ?? this.customSchedule,
      workingDays: workingDays ?? this.workingDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}