import 'package:flutter/material.dart';
import '../models/barbershop_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

/// Provider para gestionar el estado de barberías y barberos.
///
/// Utiliza [ChangeNotifier] para notificar cambios a los widgets que escuchan.
/// Maneja operaciones CRUD de barberías y proporciona filtros para
/// obtener barberos por barbería.
///
/// Implementa suscripciones en tiempo real a Firestore para mantener
/// los datos actualizados automáticamente.
class BarbershopProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  /// Lista de barberías cargadas actualmente
  List<BarbershopModel> _barbershops = [];

  /// Lista de barberos cargados actualmente
  List<UserModel> _barbers = [];

  /// Indica si se está realizando una operación asíncrona
  bool _isLoading = false;

  /// Mensaje de error actual, null si no hay errores
  String? _errorMessage;

  /// Obtiene la lista de barberías actual
  List<BarbershopModel> get barbershops => _barbershops;

  /// Obtiene la lista de barberos actual
  List<UserModel> get barbers => _barbers;

  /// Indica si hay una operación en progreso
  bool get isLoading => _isLoading;

  /// Obtiene el mensaje de error actual
  String? get errorMessage => _errorMessage;

  /// Carga todas las barberías en tiempo real desde Firestore.
  ///
  /// Establece una suscripción que actualiza automáticamente
  /// la lista cuando hay cambios en Firestore.
  void loadBarbershops() {
    _firestoreService.getBarbershops().listen(
          (barbershops) {
        _barbershops = barbershops;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Error al cargar barberías';
        notifyListeners();
      },
    );
  }

  /// Carga todos los barberos en tiempo real desde Firestore.
  ///
  /// Establece una suscripción que actualiza automáticamente
  /// la lista cuando hay cambios en Firestore.
  ///
  /// Solo incluye usuarios con rol [UserRole.barber].
  void loadBarbers() {
    _firestoreService.getBarbers().listen(
          (barbers) {
        _barbers = barbers;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Error al cargar barberos';
        notifyListeners();
      },
    );
  }

  /// Crea una nueva barbería en el sistema.
  ///
  /// Parámetros requeridos:
  /// - [name]: Nombre de la barbería
  /// - [address]: Dirección física
  /// - [ownerId]: UID del superadmin que la crea
  /// - [workingDays]: Lista de días que opera (ej: ['monday', 'tuesday'])
  /// - [openingTime]: Hora de apertura en formato 'HH:mm'
  /// - [closingTime]: Hora de cierre en formato 'HH:mm'
  ///
  /// Parámetros opcionales:
  /// - [phoneNumber]: Teléfono de contacto
  /// - [latitude]: Coordenada de ubicación
  /// - [longitude]: Coordenada de ubicación
  ///
  /// Retorna el ID de la barbería creada, o null si falla.
  Future<String?> createBarbershop({
    required String name,
    required String address,
    String? phoneNumber,
    double? latitude,
    double? longitude,
    required String ownerId,
    required List<String> workingDays,
    required String openingTime,
    required String closingTime,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final barbershop = BarbershopModel(
        id: '',
        name: name,
        address: address,
        phoneNumber: phoneNumber,
        latitude: latitude,
        longitude: longitude,
        ownerId: ownerId,
        workingDays: workingDays,
        openingTime: openingTime,
        closingTime: closingTime,
        createdAt: DateTime.now(),
      );

      final id = await _firestoreService.createBarbershop(barbershop);

      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Actualiza los datos de una barbería existente.
  ///
  /// [id] es el identificador de la barbería.
  /// [updates] es un Map con los campos a actualizar.
  ///
  /// Automáticamente actualiza el campo updatedAt.
  /// Retorna true si se actualizó correctamente, false en caso contrario.
  Future<bool> updateBarbershop(
      String id,
      Map<String, dynamic> updates,
      ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.updateBarbershop(id, updates);

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

  /// Elimina una barbería del sistema.
  ///
  /// [id] es el identificador de la barbería a eliminar.
  ///
  /// PRECAUCIÓN: Verifica que no haya barberos o citas asociadas
  /// antes de eliminar una barbería.
  ///
  /// Retorna true si se eliminó correctamente, false en caso contrario.
  Future<bool> deleteBarbershop(String id) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.deleteBarbershop(id);

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

  /// Obtiene los datos de una barbería específica.
  ///
  /// [id] es el identificador de la barbería.
  ///
  /// Retorna [BarbershopModel] con los datos de la barbería,
  /// o null si no existe o hay un error.
  Future<BarbershopModel?> getBarbershop(String id) async {
    try {
      return await _firestoreService.getBarbershop(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Obtiene la lista de barberos que trabajan en una barbería específica.
  ///
  /// [barbershopId] es el ID de la barbería.
  ///
  /// Filtra la lista de barberos cargados y retorna solo aquellos
  /// cuyo campo barbershopId coincide con el ID proporcionado.
  ///
  /// NOTA: Requiere que [loadBarbers] se haya llamado previamente.
  List<UserModel> getBarbersByBarbershop(String barbershopId) {
    return _barbers
        .where((barber) => barber.barbershopId == barbershopId)
        .toList();
  }

  /// Limpia el mensaje de error actual.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}