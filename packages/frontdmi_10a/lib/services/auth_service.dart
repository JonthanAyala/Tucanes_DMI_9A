import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';

// Servicio de autenticación con Firebase - JaimeCAST69
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login con email y contraseña
  Future<Usuario?> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final doc = await _firestore
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .get();

        if (doc.exists) {
          return Usuario.fromJson({'id': doc.id, ...doc.data()!});
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }

  // Registro de nuevo usuario
  Future<Usuario?> registro({
    required String nombre,
    required String email,
    required String password,
    required String rol,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final usuario = Usuario(
          id: userCredential.user!.uid,
          nombre: nombre,
          email: email,
          rol: rol,
        );

        await _firestore
            .collection('usuarios')
            .doc(usuario.id)
            .set(usuario.toJson());

        // Cerrar la sesión automática de Firebase Auth
        // Para forzar al usuario a iniciar sesión manualmente
        await _auth.signOut();

        return usuario;
      }
      return null;
    } catch (e) {
      throw Exception('Error al registrar usuario: ${e.toString()}');
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Intentar eliminar FCM Token con timeout para no bloquear el logout
        try {
          await _firestore
              .collection('usuarios')
              .doc(user.uid)
              .update({'fcmToken': FieldValue.delete()})
              .timeout(const Duration(seconds: 3));
        } catch (e) {
          // Si falla o tarda mucho, continuamos con el logout local
          print('No se pudo eliminar el token FCM (timeout o error): $e');
        }
      }
      // Siempre cerrar sesión en Firebase Auth
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: ${e.toString()}');
    }
  }

  // Obtener datos del usuario actual
  Future<Usuario?> obtenerUsuarioActual() async {
    try {
      final user = currentUser;
      if (user != null) {
        final doc = await _firestore.collection('usuarios').doc(user.uid).get();
        if (doc.exists) {
          return Usuario.fromJson({'id': doc.id, ...doc.data()!});
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener usuario: ${e.toString()}');
    }
  }

  // Verificar si hay sesión activa
  bool isLoggedIn() {
    return currentUser != null;
  }
}
