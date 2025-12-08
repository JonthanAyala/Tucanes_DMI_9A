import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';

// ViewModel de autenticación - JaimeCAST69
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final LocationService _locationService = LocationService();

  Usuario? _usuario;
  bool _isLoading = false;
  String? _errorMessage;

  Usuario? get usuario => _usuario;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _usuario != null;

  // Inicializar y verificar sesión guardada
  Future<void> inicializar() async {
    _isLoading = true;
    notifyListeners();

    try {
      final sesion = await _storageService.obtenerSesion();
      if (sesion != null && _authService.isLoggedIn()) {
        _usuario = await _authService.obtenerUsuarioActual();
        // Inicializar notificaciones si hay sesión activa
        if (_usuario != null) {
          await _notificationService.inicializar(userId: _usuario!.id);
          // Solicitar permiso de ubicación al iniciar
          await _locationService.checkPermissions();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _usuario = await _authService.login(email, password);

      if (_usuario != null) {
        await _storageService.guardarSesion(_usuario!);
        // Inicializar notificaciones después del login
        await _notificationService.inicializar(userId: _usuario!.id);
        // Solicitar permiso de ubicación al login
        await _locationService.checkPermissions();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Credenciales inválidas';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Registro
  Future<bool> registro({
    required String nombre,
    required String email,
    required String password,
    required String rol,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final usuario = await _authService.registro(
        nombre: nombre,
        email: email,
        password: password,
        rol: rol,
      );

      if (usuario != null) {
        // NO guardar sesión automáticamente
        // El usuario debe iniciar sesión manualmente después del registro
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Error al registrar usuario';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Guardar userId antes de limpiar
      final userId = _usuario?.id;

      // Intentar logout de Firebase (puede fallar por red, pero no debe bloquear)
      try {
        await _authService.logout();
      } catch (e) {
        print('Error en logout remoto: $e');
      }

      // SIEMPRE limpiar sesión local
      await _storageService.limpiarSesion();

      // Limpiar notificaciones en segundo plano (sin esperar)
      if (userId != null) {
        _notificationService.cerrarSesion(userId).catchError((e) {
          print('Error al limpiar notificaciones: $e');
        });
      }

      _usuario = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Limpiar mensaje de error
  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }
}
