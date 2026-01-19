import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Provider para gestionar la autenticación y el estado del usuario actual.
///
/// Utiliza [ChangeNotifier] para notificar cambios a los widgets que escuchan.
/// Maneja el registro, inicio de sesión, cierre de sesión y actualización
/// de perfil de usuarios.
///
/// Soporta autenticación por:
/// - Email y contraseña
/// - Google Sign-In (web y móvil)
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Usuario actualmente autenticado, null si no hay sesión
  UserModel? _currentUser;

  /// Indica si se está realizando una operación asíncrona
  bool _isLoading = false;

  /// Mensaje de error actual, null si no hay errores
  String? _errorMessage;

  /// Obtiene el usuario actual
  UserModel? get currentUser => _currentUser;

  /// Indica si hay una operación en progreso
  bool get isLoading => _isLoading;

  /// Obtiene el mensaje de error actual
  String? get errorMessage => _errorMessage;

  /// Indica si hay un usuario autenticado
  bool get isAuthenticated => _currentUser != null;

  /// Constructor que establece un listener para cambios en el estado de autenticación.
  ///
  /// Cada vez que Firebase detecta un cambio (login, logout, token refresh),
  /// se llama a [_onAuthStateChanged] para actualizar el estado local.
  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  /// Maneja los cambios en el estado de autenticación de Firebase.
  ///
  /// [firebaseUser] es el usuario de Firebase Auth, null si no hay sesión.
  ///
  /// Si el usuario existe, carga sus datos desde Firestore.
  /// Si no existe, limpia el usuario actual.
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    // Cargar datos completos del usuario desde Firestore
    _currentUser = await _authService.getUserData(firebaseUser.uid);
    notifyListeners();
  }

  /// Registra un nuevo usuario con email y contraseña.
  ///
  /// Crea la cuenta en Firebase Auth y guarda los datos del usuario en Firestore.
  /// El nuevo usuario se crea con rol [UserRole.client] por defecto.
  ///
  /// Parámetros requeridos:
  /// - [email]: Correo electrónico
  /// - [password]: Contraseña (mínimo 6 caracteres)
  /// - [firstName]: Nombre
  /// - [lastName]: Apellido
  ///
  /// Parámetros opcionales:
  /// - [nickname]: Apodo del usuario
  ///
  /// Retorna true si el registro fue exitoso, false en caso contrario.
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? nickname,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _authService.registerWithEmail(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
      );

      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Inicia sesión con email y contraseña.
  ///
  /// Valida las credenciales en Firebase Auth y carga los datos
  /// del usuario desde Firestore.
  ///
  /// [email] es el correo electrónico del usuario.
  /// [password] es la contraseña del usuario.
  ///
  /// Retorna true si el inicio de sesión fue exitoso, false en caso contrario.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Inicia sesión con Google.
  ///
  /// Maneja diferentes flujos para web y móvil:
  /// - En web: usa popup o redirect
  /// - En móvil: usa el flujo nativo de Google Sign-In
  ///
  /// Si el usuario ya existe en Firestore, carga sus datos.
  /// Si es un usuario nuevo, crea un perfil con rol [UserRole.client].
  ///
  /// Retorna true si el inicio de sesión fue exitoso, false en caso contrario.
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      UserCredential? userCredential;

      // Diferentes flujos para web y móvil
      if (kIsWeb) {
        // Flujo para WEB
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();

        try {
          userCredential = await _auth.signInWithPopup(googleProvider);
        } catch (e) {
          print('Error en popup: $e');
          // Si falla el popup, intentar con redirect
          await _auth.signInWithRedirect(googleProvider);
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // Flujo para MÓVIL
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          _isLoading = false;
          _errorMessage = 'Inicio de sesión cancelado';
          notifyListeners();
          return false;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      // Verificar el userCredential
      if (userCredential == null || userCredential.user == null) {
        throw Exception('No se pudo obtener las credenciales del usuario');
      }

      final user = userCredential.user!;

      // Verificar si el usuario existe en Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Usuario nuevo - crear perfil
        final newUser = UserModel(
          uid: user.uid,
          email: user.email!,
          firstName: user.displayName?.split(' ').first ?? 'Usuario',
          lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
          role: UserRole.client,
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        _currentUser = newUser;
      } else {
        // Usuario existente - cargar datos
        _currentUser = UserModel.fromMap(userDoc.data()!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error signing in with Google: $e');
      _isLoading = false;
      _errorMessage = 'Error al iniciar sesión con Google: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión del usuario actual.
  ///
  /// Cierra sesión en Firebase Auth y en Google Sign-In si aplica.
  /// Limpia el estado local del usuario.
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();

      // También cerrar sesión de Google según la plataforma
      if (kIsWeb) {
        await _auth.signOut();
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      }

      _currentUser = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza el perfil del usuario actual.
  ///
  /// Solo actualiza los campos proporcionados, el resto permanece igual.
  /// Actualiza tanto en Firestore como en el estado local.
  ///
  /// Parámetros opcionales:
  /// - [firstName]: Nuevo nombre
  /// - [lastName]: Nuevo apellido
  /// - [nickname]: Nuevo apodo
  /// - [photoUrl]: Nueva URL de foto de perfil
  ///
  /// Retorna true si la actualización fue exitosa, false en caso contrario.
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? nickname,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await _authService.updateUserProfile(
        uid: _currentUser!.uid,
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        photoUrl: photoUrl,
      );

      // Actualizar usuario local
      _currentUser = _currentUser!.copyWith(
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        photoUrl: photoUrl,
        updatedAt: DateTime.now(),
      );

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

  /// Envía un correo para restablecer la contraseña.
  ///
  /// [email] es el correo electrónico al cual se enviará el link de recuperación.
  ///
  /// Firebase Auth maneja el envío del correo automáticamente.
  /// Retorna true si el correo se envió correctamente, false en caso contrario.
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(email);

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

  /// Limpia el mensaje de error actual.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Verifica si el usuario actual es SuperAdmin.
  bool get isSuperAdmin => _currentUser?.role == UserRole.superadmin;

  /// Verifica si el usuario actual es Barbero.
  bool get isBarber => _currentUser?.role == UserRole.barber;

  /// Verifica si el usuario actual es Cliente.
  bool get isClient => _currentUser?.role == UserRole.client;
}