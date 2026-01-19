import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/barbershop_model.dart';
import '../models/appointment_model.dart';

/// Servicio para gestionar todas las operaciones con Firestore.
///
/// Proporciona métodos CRUD (Create, Read, Update, Delete) para:
/// - Usuarios (clientes, barberos, superadmins)
/// - Barberías
/// - Citas
///
/// Incluye validaciones y métodos de consulta específicos para
/// diferentes roles y casos de uso.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== USUARIOS ==========

  /// Obtiene un usuario por su ID desde Firestore.
  ///
  /// [uid] es el identificador único del usuario.
  ///
  /// Retorna [UserModel] con los datos del usuario,
  /// o null si el usuario no existe o hay un error.
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Obtiene un stream de todos los barberos en tiempo real.
  ///
  /// Retorna un Stream que emite la lista actualizada de barberos
  /// cada vez que hay cambios en Firestore.
  ///
  /// Solo incluye usuarios con rol [UserRole.barber].
  Stream<List<UserModel>> getBarbers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'barber')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList());
  }

  /// Crea un nuevo barbero en Firestore (solo SuperAdmin).
  ///
  /// Parámetros requeridos:
  /// - [uid]: UID del usuario (debe existir en Firebase Auth)
  /// - [email]: Correo electrónico
  /// - [firstName]: Nombre
  /// - [lastName]: Apellido
  /// - [barbershopId]: ID de la barbería donde trabajará
  /// - [appointmentDuration]: Duración de cada cita en minutos
  ///
  /// Lanza excepciones si hay errores al crear en Firestore.
  Future<void> createBarber({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    required String barbershopId,
    required int appointmentDuration,
  }) async {
    try {
      final barber = UserModel(
        uid: uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: UserRole.barber,
        barbershopId: barbershopId,
        appointmentDuration: appointmentDuration,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(barber.toMap());
    } catch (e) {
      print('Error creating barber: $e');
      throw 'Error al crear barbero';
    }
  }

  // ========== BARBERÍAS ==========

  /// Crea una nueva barbería en Firestore.
  ///
  /// [barbershop] es el modelo de la barbería a crear.
  ///
  /// Genera automáticamente un ID único y lo asigna al documento.
  /// Retorna el ID de la barbería creada.
  ///
  /// Lanza excepciones si hay errores al crear en Firestore.
  Future<String> createBarbershop(BarbershopModel barbershop) async {
    try {
      final docRef = await _firestore.collection('barbershops').add(barbershop.toMap());
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      print('Error creating barbershop: $e');
      throw 'Error al crear barbería';
    }
  }

  /// Obtiene una barbería por su ID.
  ///
  /// [id] es el identificador único de la barbería.
  ///
  /// Retorna [BarbershopModel] con los datos de la barbería,
  /// o null si no existe o hay un error.
  Future<BarbershopModel?> getBarbershop(String id) async {
    try {
      final doc = await _firestore.collection('barbershops').doc(id).get();
      if (doc.exists) {
        return BarbershopModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting barbershop: $e');
      return null;
    }
  }

  /// Obtiene un stream de todas las barberías en tiempo real.
  ///
  /// Retorna un Stream que emite la lista actualizada de barberías
  /// cada vez que hay cambios en Firestore.
  Stream<List<BarbershopModel>> getBarbershops() {
    return _firestore
        .collection('barbershops')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BarbershopModel.fromMap(doc.data()))
        .toList());
  }

  /// Actualiza los datos de una barbería.
  ///
  /// [id] es el identificador de la barbería.
  /// [updates] es un Map con los campos a actualizar.
  ///
  /// Automáticamente agrega el campo updatedAt con la fecha actual.
  ///
  /// Lanza excepciones si hay errores al actualizar.
  Future<void> updateBarbershop(String id, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection('barbershops').doc(id).update(updates);
    } catch (e) {
      print('Error updating barbershop: $e');
      throw 'Error al actualizar barbería';
    }
  }

  /// Elimina una barbería de Firestore.
  ///
  /// [id] es el identificador de la barbería a eliminar.
  ///
  /// PRECAUCIÓN: Esta operación es permanente y no se puede deshacer.
  /// Se debe verificar que no haya barberos o citas asociadas antes de eliminar.
  ///
  /// Lanza excepciones si hay errores al eliminar.
  Future<void> deleteBarbershop(String id) async {
    try {
      await _firestore.collection('barbershops').doc(id).delete();
    } catch (e) {
      print('Error deleting barbershop: $e');
      throw 'Error al eliminar barbería';
    }
  }

  // ========== CITAS ==========

  /// Crea una nueva cita en Firestore.
  ///
  /// [appointment] es el modelo de la cita a crear.
  ///
  /// Genera automáticamente un ID único y lo asigna al documento.
  /// Retorna el ID de la cita creada.
  ///
  /// Lanza excepciones si hay errores al crear en Firestore.
  Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      final docRef = await _firestore.collection('appointments').add(appointment.toMap());
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      print('Error creating appointment: $e');
      throw 'Error al crear cita';
    }
  }

  /// Obtiene un stream de las citas de un cliente en tiempo real.
  ///
  /// [clientId] es el UID del cliente.
  ///
  /// Retorna un Stream que emite la lista actualizada de citas del cliente
  /// ordenadas por fecha (más recientes primero).
  Stream<List<AppointmentModel>> getClientAppointments(String clientId) {
    return _firestore
        .collection('appointments')
        .where('clientId', isEqualTo: clientId)
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => AppointmentModel.fromMap(doc.data()))
        .toList());
  }

  /// Obtiene un stream de las citas de un barbero en tiempo real.
  ///
  /// [barberId] es el UID del barbero.
  ///
  /// Retorna un Stream que emite la lista actualizada de citas del barbero
  /// ordenadas por fecha (más recientes primero).
  Stream<List<AppointmentModel>> getBarberAppointments(String barberId) {
    return _firestore
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => AppointmentModel.fromMap(doc.data()))
        .toList());
  }

  /// Obtiene un stream de las citas de un barbero para una fecha específica.
  ///
  /// [barberId] es el UID del barbero.
  /// [date] es la fecha para la cual se buscarán las citas.
  ///
  /// Retorna un Stream con las citas del barbero para ese día,
  /// ordenadas por fecha y hora.
  Stream<List<AppointmentModel>> getBarberAppointmentsByDate(
      String barberId,
      DateTime date,
      ) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('appointmentDate')
        .orderBy('appointmentTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => AppointmentModel.fromMap(doc.data()))
        .toList());
  }

  /// Obtiene un stream de todas las citas del sistema (SuperAdmin).
  ///
  /// Retorna un Stream con todas las citas del sistema,
  /// ordenadas por fecha (más recientes primero).
  ///
  /// PRECAUCIÓN: Esta consulta puede ser costosa si hay muchas citas.
  Stream<List<AppointmentModel>> getAllAppointments() {
    return _firestore
        .collection('appointments')
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => AppointmentModel.fromMap(doc.data()))
        .toList());
  }

  /// Actualiza el estado de una cita.
  ///
  /// [appointmentId] es el ID de la cita.
  /// [status] es el nuevo estado de la cita.
  ///
  /// Automáticamente actualiza el campo updatedAt.
  ///
  /// Lanza excepciones si hay errores al actualizar.
  Future<void> updateAppointmentStatus(
      String appointmentId,
      AppointmentStatus status,
      ) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating appointment status: $e');
      throw 'Error al actualizar estado de la cita';
    }
  }

  /// Cancela una cita cambiando su estado a cancelled.
  ///
  /// [appointmentId] es el ID de la cita a cancelar.
  ///
  /// Es un atajo para [updateAppointmentStatus] con estado cancelled.
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
    } catch (e) {
      print('Error cancelling appointment: $e');
      throw 'Error al cancelar cita';
    }
  }

  /// Elimina permanentemente una cita de Firestore.
  ///
  /// [appointmentId] es el ID de la cita a eliminar.
  ///
  /// PRECAUCIÓN: Esta operación es permanente y no se puede deshacer.
  /// Se recomienda usar [cancelAppointment] en lugar de eliminar.
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();
    } catch (e) {
      print('Error deleting appointment: $e');
      throw 'Error al eliminar cita';
    }
  }

  /// Verifica si un horario está disponible para agendar una cita.
  ///
  /// [barberId] es el UID del barbero.
  /// [date] es la fecha de la cita.
  /// [time] es la hora de la cita en formato texto (ej: "10:00").
  /// [excludeAppointmentId] es opcional, usado al editar una cita existente.
  ///
  /// Retorna true si el horario está disponible (no hay citas activas en ese horario),
  /// false si ya está ocupado.
  ///
  /// Solo considera citas con estado 'pending' o 'confirmed'.
  Future<bool> isTimeSlotAvailable({
    required String barberId,
    required DateTime date,
    required String time,
    String? excludeAppointmentId,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      var query = _firestore
          .collection('appointments')
          .where('barberId', isEqualTo: barberId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('appointmentTime', isEqualTo: time)
          .where('status', whereIn: ['pending', 'confirmed']);

      final snapshot = await query.get();

      // Si hay que excluir una cita (para edición), filtrarla
      if (excludeAppointmentId != null) {
        return snapshot.docs
            .where((doc) => doc.id != excludeAppointmentId)
            .isEmpty;
      }

      return snapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking availability: $e');
      return false;
    }
  }

  /// Obtiene las citas de un barbero para una fecha específica como Future.
  ///
  /// [barberId] es el UID del barbero.
  /// [date] es la fecha para la cual se buscarán las citas.
  ///
  /// Similar a [getBarberAppointmentsByDate] pero retorna un Future
  /// en lugar de un Stream. Útil cuando solo necesitas los datos una vez.
  ///
  /// Retorna una lista de citas, o lista vacía si hay errores.
  Future<List<AppointmentModel>> getBarberAppointmentsByDateFuture(
      String barberId,
      DateTime date,
      ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('appointments')
          .where('barberId', isEqualTo: barberId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error al obtener citas del barbero por fecha: $e');
      return [];
    }
  }

  /// Obtiene una barbería por su ID (alias de [getBarbershop]).
  ///
  /// [barbershopId] es el identificador de la barbería.
  ///
  /// Retorna [BarbershopModel] o null si no existe.
  Future<BarbershopModel?> getBarbershopById(String barbershopId) async {
    try {
      final doc = await _firestore.collection('barbershops').doc(barbershopId).get();
      if (doc.exists) {
        return BarbershopModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error al obtener barbershop: $e');
      return null;
    }
  }

  /// Obtiene un usuario por su ID (alias de [getUser]).
  ///
  /// [userId] es el identificador del usuario.
  ///
  /// Retorna [UserModel] o null si no existe.
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario: $e');
      return null;
    }
  }

  /// Actualiza los datos de una cita.
  ///
  /// [appointmentId] es el ID de la cita.
  /// [data] es un Map con los campos a actualizar.
  ///
  /// Lanza excepciones si hay errores al actualizar.
  Future<void> updateAppointment(String appointmentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update(data);
    } catch (e) {
      print('Error al actualizar cita: $e');
      throw e;
    }
  }
}