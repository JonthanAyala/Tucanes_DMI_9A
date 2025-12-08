import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ubicacion_model.dart';
import '../utils/error_handler.dart';
import 'error_logging_service.dart';

// Servicio de geolocalización - BojitaNoir
class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ErrorLoggingService _errorLogger = ErrorLoggingService();

  // Verificar y solicitar permisos de ubicación
  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Obtener ubicación actual
  Future<Ubicacion?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return Ubicacion(
        latitud: position.latitude,
        longitud: position.longitude,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'LocationService.getCurrentLocation',
      );
      if (appError.requiresAdminNotification) {
        await _errorLogger.logError(
          appError,
          context: 'Obtener ubicación actual',
        );
      }
      throw appError;
    }
  }

  // Escuchar cambios de ubicación
  Stream<Ubicacion> watchLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualizar cada 10 metros
      ),
    ).map((position) {
      return Ubicacion(
        latitud: position.latitude,
        longitud: position.longitude,
        timestamp: DateTime.now(),
      );
    });
  }

  // Actualizar ubicación del repartidor en Firestore
  Future<void> updateRepartidorLocation(
    String repartidorId,
    Ubicacion ubicacion,
  ) async {
    try {
      await _firestore
          .collection('ubicaciones_repartidores')
          .doc(repartidorId)
          .set(ubicacion.toJson());
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'LocationService.updateRepartidorLocation',
      );
      if (appError.requiresAdminNotification) {
        await _errorLogger.logError(
          appError,
          userId: repartidorId,
          context: 'Actualizar ubicación repartidor',
        );
      }
      throw appError;
    }
  }

  // Obtener ubicación de un repartidor
  Future<Ubicacion?> getRepartidorLocation(String repartidorId) async {
    try {
      final doc = await _firestore
          .collection('ubicaciones_repartidores')
          .doc(repartidorId)
          .get();

      if (doc.exists) {
        return Ubicacion.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'LocationService.getRepartidorLocation',
      );
      if (appError.requiresAdminNotification) {
        await _errorLogger.logError(
          appError,
          userId: repartidorId,
          context: 'Obtener ubicación repartidor',
        );
      }
      throw appError;
    }
  }

  // Escuchar ubicación de un repartidor en tiempo real
  Stream<Ubicacion?> watchRepartidorLocation(String repartidorId) {
    return _firestore
        .collection('ubicaciones_repartidores')
        .doc(repartidorId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return Ubicacion.fromJson(snapshot.data()!);
          }
          return null;
        });
  }

  // Calcular distancia entre dos puntos (en metros)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
