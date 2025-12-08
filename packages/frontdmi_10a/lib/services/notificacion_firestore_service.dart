import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notificacion_model.dart';

// Servicio de gestión de notificaciones en Firestore - JonthanAyala
class NotificacionFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Referencia a la colección de notificaciones de un usuario
  CollectionReference _getNotificacionesRef(String userId) {
    return _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('notificaciones');
  }

  // Crear notificación
  Future<void> crearNotificacion(Notificacion notificacion) async {
    try {
      await _getNotificacionesRef(
        notificacion.userId,
      ).doc(notificacion.id).set(notificacion.toJson());
    } catch (e) {
      throw Exception('Error al crear notificación: ${e.toString()}');
    }
  }

  // Obtener notificaciones de un usuario (Stream)
  Stream<List<Notificacion>> obtenerNotificacionesUsuario(String userId) {
    print('Escuchando notificaciones para usuario: $userId');
    return _getNotificacionesRef(userId)
        .snapshots()
        .map((snapshot) {
          print(
            'Recibidos ${snapshot.docs.length} documentos de notificaciones',
          );
          final notificaciones = snapshot.docs.map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              data['userId'] = userId;
              return Notificacion.fromJson({'id': doc.id, ...data});
            } catch (e) {
              print('Error al parsear notificación ${doc.id}: $e');
              // Retornar una notificación de error o filtrar después
              return Notificacion(
                id: doc.id,
                userId: userId,
                titulo: 'Error',
                mensaje: 'Error de formato',
                tipo: 'sistema',
                fechaCreacion: DateTime.now(),
              );
            }
          }).toList();

          // Ordenar por fecha en memoria (más reciente primero)
          notificaciones.sort(
            (a, b) => b.fechaCreacion.compareTo(a.fechaCreacion),
          );

          return notificaciones;
        })
        .handleError((error) {
          print('ERROR EN STREAM DE NOTIFICACIONES: $error');
          return <Notificacion>[];
        });
  }

  // Obtener solo notificaciones no leídas
  Stream<List<Notificacion>> obtenerNotificacionesNoLeidas(String userId) {
    return _getNotificacionesRef(userId)
        .where('leida', isEqualTo: false)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['userId'] = userId;
            return Notificacion.fromJson({'id': doc.id, ...data});
          }).toList();
        });
  }

  // Marcar notificación como leída
  Future<void> marcarComoLeida(String userId, String notificacionId) async {
    try {
      await _getNotificacionesRef(
        userId,
      ).doc(notificacionId).update({'leida': true});
    } catch (e) {
      throw Exception('Error al marcar como leída: ${e.toString()}');
    }
  }

  // Marcar todas como leídas
  Future<void> marcarTodasComoLeidas(String userId) async {
    try {
      final snapshot = await _getNotificacionesRef(
        userId,
      ).where('leida', isEqualTo: false).get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'leida': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Error al marcar todas como leídas: ${e.toString()}');
    }
  }

  // Eliminar notificación
  Future<void> eliminarNotificacion(
    String userId,
    String notificacionId,
  ) async {
    try {
      await _getNotificacionesRef(userId).doc(notificacionId).delete();
    } catch (e) {
      throw Exception('Error al eliminar notificación: ${e.toString()}');
    }
  }

  // Eliminar todas las notificaciones de un usuario
  Future<void> eliminarTodasNotificaciones(String userId) async {
    try {
      final snapshot = await _getNotificacionesRef(userId).get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception(
        'Error al eliminar todas las notificaciones: ${e.toString()}',
      );
    }
  }

  // Contar notificaciones no leídas
  Future<int> contarNoLeidas(String userId) async {
    try {
      final snapshot = await _getNotificacionesRef(
        userId,
      ).where('leida', isEqualTo: false).count().get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Limpiar notificaciones antiguas (más de 30 días)
  Future<void> limpiarNotificacionesAntiguas(String userId) async {
    try {
      final fechaLimite = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _getNotificacionesRef(
        userId,
      ).where('fecha', isLessThan: Timestamp.fromDate(fechaLimite)).get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception(
        'Error al limpiar notificaciones antiguas: ${e.toString()}',
      );
    }
  }
}
