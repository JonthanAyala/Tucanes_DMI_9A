import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // COMENTADO: Para usar en el futuro con Firebase Storage
import '../models/paquete_model.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import 'local_storage_service.dart'; // Servicio de almacenamiento local
import 'notificacion_backend_service.dart'; // JonthanAyala - Backend de notificaciones
import 'error_logging_service.dart';

// Servicio de gestión de paquetes - BojitaNoir
// NOTA: Actualmente usa almacenamiento LOCAL para fotos
// Para migrar a Firebase Storage, descomentar imports y cambiar método _guardarFoto()
class PaqueteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance; // COMENTADO: Para Firebase Storage
  final LocalStorageService _localStorage =
      LocalStorageService(); // Almacenamiento local
  final NotificacionBackendService _backendService =
      NotificacionBackendService(); // JonthanAyala - Backend
  final ErrorLoggingService _errorLogger = ErrorLoggingService();

  // Obtener todos los paquetes
  Stream<List<Paquete>> obtenerPaquetes() {
    return _firestore
        .collection('paquetes')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Paquete.fromJson({'id': doc.id, ...doc.data()});
          }).toList();
        });
  }

  // Obtener paquetes por cliente
  // NOTA: Ordenamiento en memoria para evitar índices compuestos en Firestore
  Stream<List<Paquete>> obtenerPaquetesPorCliente(String clienteId) {
    return _firestore
        .collection('paquetes')
        .where('clienteId', isEqualTo: clienteId)
        .snapshots()
        .map((snapshot) {
          final paquetes = snapshot.docs.map((doc) {
            return Paquete.fromJson({'id': doc.id, ...doc.data()});
          }).toList();

          // Ordenar por fecha de creación en memoria
          paquetes.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
          return paquetes;
        });
  }

  // Obtener paquetes por repartidor
  // NOTA: Ordenamiento en memoria para evitar índices compuestos en Firestore
  Stream<List<Paquete>> obtenerPaquetesPorRepartidor(String repartidorId) {
    return _firestore
        .collection('paquetes')
        .where('repartidorId', isEqualTo: repartidorId)
        .snapshots()
        .map((snapshot) {
          final paquetes = snapshot.docs.map((doc) {
            return Paquete.fromJson({'id': doc.id, ...doc.data()});
          }).toList();

          // Ordenar por fecha de creación en memoria
          paquetes.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
          return paquetes;
        });
  }

  // Obtener paquete por ID
  Future<Paquete?> obtenerPaquetePorId(String id) async {
    try {
      final doc = await _firestore.collection('paquetes').doc(id).get();
      if (doc.exists) {
        return Paquete.fromJson({'id': doc.id, ...doc.data()!});
      }
      return null;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PaqueteService.obtenerPaquetePorId',
      );
      if (appError.requiresAdminNotification) {
        await _errorLogger.logError(
          appError,
          context: 'Obtener paquete por ID: $id',
        );
      }
      throw appError;
    }
  }

  // Crear paquete con foto (usa almacenamiento LOCAL)
  Future<void> crearPaquete(Paquete paquete, File? foto) async {
    try {
      String? fotoRuta;

      if (foto != null) {
        // ALMACENAMIENTO AWS S3 (Backend)
        fotoRuta = await _subirFotoBackend(foto);

        // ALMACENAMIENTO LOCAL (Legacy/Backup)
        // fotoRuta = await _guardarFotoLocal(foto, paquete.id);
      }

      // Generar código QR único - JonthanAyala
      final codigoQR =
          'PKG-${paquete.id}-${DateTime.now().millisecondsSinceEpoch}';

      final paqueteConFoto = paquete.copyWith(
        fotoUrl: fotoRuta,
        codigoQR: codigoQR,
      );

      // 1. Guardar en Firestore
      await _firestore
          .collection('paquetes')
          .doc(paquete.id)
          .set(paqueteConFoto.toJson());

      // 2. Notificar a repartidores (backend)
      // No esperar respuesta para no bloquear
      _backendService
          .notificarNuevoPaquete(
            paqueteId: paquete.id,
            // destinatario y direccion ya no son necesarios, el backend los busca
          )
          .catchError((e) {
            print('Error al notificar nuevo paquete al backend: $e');
            return false;
          });
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PaqueteService.crearPaquete',
      );
      if (appError.requiresAdminNotification) {
        await _errorLogger.logError(appError, context: 'Crear paquete');
      }
      throw appError;
    }
  }

  // Actualizar paquete (usa almacenamiento LOCAL)
  Future<void> actualizarPaquete(Paquete paquete, File? nuevaFoto) async {
    try {
      String? fotoRuta = paquete.fotoUrl;

      if (nuevaFoto != null) {
        // ALMACENAMIENTO AWS S3 (Backend)
        fotoRuta = await _subirFotoBackend(nuevaFoto);

        // ALMACENAMIENTO LOCAL (Legacy)
        // fotoRuta = await _guardarFotoLocal(nuevaFoto, paquete.id);
      }

      final paqueteActualizado = paquete.copyWith(fotoUrl: fotoRuta);

      await _firestore
          .collection('paquetes')
          .doc(paquete.id)
          .update(paqueteActualizado.toJson());
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PaqueteService.actualizarPaquete',
      );
      if (appError.requiresAdminNotification) {
        await _errorLogger.logError(
          appError,
          context: 'Actualizar paquete ID: ${paquete.id}',
        );
      }
      throw appError;
    }
  }

  // Eliminar paquete (solo admin)
  Future<void> eliminarPaquete(String id) async {
    try {
      // Obtener paquete para eliminar foto si existe
      final paquete = await obtenerPaquetePorId(id);

      if (paquete?.fotoUrl != null) {
        // ALMACENAMIENTO LOCAL (actual)
        await _localStorage.eliminarFoto(paquete!.fotoUrl!);

        // FIREBASE STORAGE (comentado para futuro uso)
        // await _eliminarFotoFirebase(paquete!.fotoUrl!);
      }

      await _firestore.collection('paquetes').doc(id).delete();
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PaqueteService.eliminarPaquete',
      );
      if (appError.requiresAdminNotification) {
        await _errorLogger.logError(
          appError,
          context: 'Eliminar paquete ID: $id',
        );
      }
      throw appError;
    }
  }

  // Actualizar estado del paquete con ubicación opcional
  Future<void> actualizarEstado(
    String id,
    String nuevoEstado, {
    Map<String, dynamic>? ubicacion,
  }) async {
    try {
      final Map<String, dynamic> updateData = {'estado': nuevoEstado};

      if (nuevoEstado == 'entregado' && ubicacion != null) {
        updateData['ubicacionEntrega'] = ubicacion;
      }

      // 1. Actualizar Firestore
      await _firestore.collection('paquetes').doc(id).update(updateData);

      // 2. Si el estado es "entregado", notificar al cliente
      if (nuevoEstado == 'entregado') {
        final paqueteDoc = await _firestore
            .collection('paquetes')
            .doc(id)
            .get();

        if (paqueteDoc.exists) {
          final paqueteData = paqueteDoc.data()!;

          // Notificar al backend (no esperar respuesta)
          _backendService
              .notificarPaqueteEntregado(
                paqueteId: id,
                clienteId: paqueteData['clienteId'],
              )
              .catchError((e) {
                print('Error al notificar paquete entregado al backend: $e');
                return false;
              });
        }
      }
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PaqueteService.actualizarEstado',
      );
      if (appError.requiresAdminNotification) {
        await _errorLogger.logError(
          appError,
          context: 'Actualizar estado paquete ID: $id',
        );
      }
      throw appError;
    }
  }

  // ============================================
  // MÉTODOS PARA PAQUETES CERCANOS - JonthanAyala
  // ============================================

  // Obtener paquetes disponibles (sin repartidor asignado)
  Future<List<Paquete>> obtenerPaquetesDisponibles() async {
    try {
      final snapshot = await _firestore
          .collection('paquetes')
          .where('repartidorId', isNull: true)
          .where('estado', isEqualTo: 'pendiente')
          .get();

      return snapshot.docs
          .map((doc) => Paquete.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PaqueteService.obtenerPaquetesDisponibles',
      );
      if (appError.requiresAdminNotification) {
        await _errorLogger.logError(
          appError,
          context: 'Obtener paquetes disponibles',
        );
      }
      throw appError;
    }
  }

  // Tomar paquete (auto-asignarse) con ubicación
  Future<bool> tomarPaquete(
    String paqueteId,
    String repartidorId, {
    Map<String, dynamic>? ubicacion,
  }) async {
    try {
      // 1. Obtener datos del paquete y repartidor para la notificación
      final paqueteDoc = await _firestore
          .collection('paquetes')
          .doc(paqueteId)
          .get();
      // Ya no necesitamos buscar al repartidor explícitamente para el nombre
      // El backend lo hará

      if (!paqueteDoc.exists) {
        return false;
      }

      final paqueteData = paqueteDoc.data()!;

      final Map<String, dynamic> updateData = {
        'repartidorId': repartidorId,
        'estado': 'en_transito',
      };

      if (ubicacion != null) {
        updateData['ubicacionRecoleccion'] = ubicacion;
      }

      // 2. Actualizar Firestore
      await _firestore.collection('paquetes').doc(paqueteId).update(updateData);

      // 3. Notificar al cliente (backend)
      // No esperar respuesta para no bloquear
      _backendService
          .notificarPaqueteTomado(
            paqueteId: paqueteId,
            clienteId: paqueteData['clienteId'],
            repartidorId: repartidorId,
            // repartidorNombre ya no es necesario, el backend lo busca
          )
          .catchError((e) {
            print('Error al notificar paquete tomado al backend: $e');
            return false;
          });

      return true;
    } catch (e) {
      print('Error en tomarPaquete: $e');
      return false;
    }
  }

  // ============================================
  // MÉTODOS DE ALMACENAMIENTO LOCAL (ACTUAL)
  // ============================================

  // Guardar foto localmente en el dispositivo
  Future<String> _guardarFotoLocal(File foto, String paqueteId) async {
    try {
      return await _localStorage.guardarFoto(foto, paqueteId);
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PaqueteService._guardarFotoLocal',
      );
      if (appError.requiresAdminNotification) {
        await _errorLogger.logError(
          appError,
          context: 'Guardar foto localmente',
        );
      }
      throw appError;
    }
  }

  // ============================================
  // MÉTODOS DE ALMACENAMIENTO EN AWS S3 (BACKEND)
  // ============================================

  // Subir foto al backend (S3)
  Future<String> _subirFotoBackend(File foto) async {
    try {
      String fileName = foto.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(foto.path, filename: fileName),
      });

      // URL del backend (Elastic Beanstalk)
      // Usamos la misma base que NotificacionBackendService
      String baseUrl = AppConstants.backendUrl;
      String endpoint = '$baseUrl/api/storage/upload';

      print('📸 Intentando subir foto a: $endpoint');

      Dio dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      Response response = await dio.post(endpoint, data: formData);

      if (response.statusCode == 200) {
        return response.data['url'];
      } else {
        throw Exception('Error en backend: ${response.statusMessage}');
      }
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PaqueteService._subirFotoBackend',
      );
      print('⚠️ Error al subir foto al backend: ${appError.userMessage}');
      if (appError.requiresAdminNotification) {
        await _errorLogger.logError(
          appError,
          context: 'Subir foto al servidor AWS S3',
        );
      }
      // Por ahora lanzamos error para que el usuario sepa
      throw appError;
    }
  }
}
