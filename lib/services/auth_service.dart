import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Servicio para gestionar la autenticación de usuarios con Firebase.
///
/// Proporciona métodos para:
/// - Registro e inicio de sesión con email/contraseña
/// - Inicio de sesión con Google
/// - Recuperación de contraseña
/// - Gestión del estado de autenticación
/// - Actualización de perfiles de usuario
///
/// Interactúa directamente con Firebase Auth y Firestore.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream que emite el usuario de Firebase Auth cada vez que cambia el estado.
  ///
  /// Emite:
  /// - [User] cuando hay un usuario autenticado
  /// - null cuando no hay sesión activa
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Obtiene el usuario de Firebase Auth actualmente autenticado.
  ///
  /// Retorna null si no hay sesión activa.
  User? get currentUser => _auth.currentUser;

  /// Obtiene los datos completos del usuario desde Firestore.
  ///
  /// [uid] es el identificador único del usuario en Firebase Auth.
  ///
  /// Retorna [UserModel] con todos los datos del usuario,
  /// o null si el documento no existe o hay un error.
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Registra un nuevo usuario con email y contraseña.
  ///
  /// Crea la cuenta en Firebase Auth y luego guarda los datos
  /// del usuario en Firestore.
  ///
  /// Parámetros requeridos:
  /// - [email]: Correo electrónico (debe ser válido)
  /// - [password]: Contraseña (mínimo 6 caracteres)
  /// - [firstName]: Nombre del usuario
  /// - [lastName]: Apellido del usuario
  ///
  /// Parámetros opcionales:
  /// - [nickname]: Apodo del usuario
  /// - [role]: Rol del usuario (por defecto [UserRole.client])
  ///
  /// Retorna [UserModel] del usuario creado, o null si falla.
  /// Lanza excepciones con mensajes descriptivos en español.
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? nickname,
    UserRole role = UserRole.client,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      // Crear documento en Firestore
      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(user.toMap());

      return user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Error registering user: $e');
      throw 'Error al registrar usuario';
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
  /// Retorna [UserModel] con los datos del usuario, o null si falla.
  /// Lanza excepciones con mensajes descriptivos en español.
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      return await getUserData(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Error signing in: $e');
      throw 'Error al iniciar sesión';
    }
  }

  /// Inicia sesión con Google.
  ///
  /// Abre el diálogo de Google Sign-In, obtiene las credenciales
  /// y las usa para autenticar en Firebase.
  ///
  /// Si es la primera vez que el usuario inicia sesión, crea
  /// un nuevo perfil en Firestore con rol [UserRole.client].
  ///
  /// Retorna [UserModel] del usuario autenticado, o null si:
  /// - El usuario cancela el flujo de Google
  /// - Ocurre un error durante el proceso
  ///
  /// Lanza excepciones si hay errores de red o de Firebase.
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Iniciar flujo de Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Usuario canceló

      // Obtener credenciales de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Autenticar con Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) return null;

      // Verificar si el usuario ya existe en Firestore
      final existingUser = await getUserData(userCredential.user!.uid);

      if (existingUser != null) {
        return existingUser;
      }

      // Usuario nuevo - crear perfil
      final nameParts = googleUser.displayName?.split(' ') ?? ['', ''];
      final user = UserModel(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        firstName: nameParts.isNotEmpty ? nameParts[0] : '',
        lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        photoUrl: googleUser.photoUrl,
        role: UserRole.client,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(user.toMap());

      return user;
    } catch (e) {
      print('Error signing in with Google: $e');
      throw 'Error al iniciar sesión con Google';
    }
  }

  /// Cierra la sesión del usuario actual.
  ///
  /// Cierra sesión tanto en Firebase Auth como en Google Sign-In.
  /// Espera a que ambas operaciones terminen antes de completar.
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Error signing out: $e');
      throw 'Error al cerrar sesión';
    }
  }

  /// Actualiza el perfil de un usuario en Firestore.
  ///
  /// Solo actualiza los campos proporcionados (no null).
  /// Automáticamente actualiza el campo updatedAt.
  ///
  /// [uid] es el identificador único del usuario.
  ///
  /// Parámetros opcionales:
  /// - [firstName]: Nuevo nombre
  /// - [lastName]: Nuevo apellido
  /// - [nickname]: Nuevo apodo
  /// - [photoUrl]: Nueva URL de foto de perfil
  ///
  /// Lanza excepciones si hay errores al actualizar Firestore.
  Future<void> updateUserProfile({
    required String uid,
    String? firstName,
    String? lastName,
    String? nickname,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (firstName != null) updates['firstName'] = firstName;
      if (lastName != null) updates['lastName'] = lastName;
      if (nickname != null) updates['nickname'] = nickname;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      print('Error updating user profile: $e');
      throw 'Error al actualizar perfil';
    }
  }

  /// Envía un correo electrónico para restablecer la contraseña.
  ///
  /// [email] es el correo al cual se enviará el link de recuperación.
  ///
  /// Firebase Auth maneja automáticamente el envío del correo
  /// con un link para restablecer la contraseña.
  ///
  /// Lanza excepciones con mensajes descriptivos en español
  /// si el email no existe o es inválido.
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Error resetting password: $e');
      throw 'Error al enviar email de recuperación';
    }
  }

  /// Convierte excepciones de Firebase Auth a mensajes en español.
  ///
  /// [e] es la excepción de Firebase Auth.
  ///
  /// Retorna un mensaje de error descriptivo en español
  /// basado en el código de error de Firebase.
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Este email ya está registrado';
      case 'invalid-email':
        return 'Email inválido';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}