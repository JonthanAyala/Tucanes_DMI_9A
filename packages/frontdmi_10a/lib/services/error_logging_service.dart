import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_exception.dart';

// Servicio para registrar y notificar errores graves al administrador - JonthanAyala
class ErrorLoggingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Rate limiting: evitar spam de errores (máximo 1 error del mismo tipo cada 5 segundos)
  final Map<String, DateTime> _lastErrorLog = {};
  static const Duration _rateLimitDuration = Duration(seconds: 5);

  // Singleton
  static final ErrorLoggingService _instance = ErrorLoggingService._internal();
  factory ErrorLoggingService() => _instance;
  ErrorLoggingService._internal();

  // Registrar error crítico en Firestore
  Future<void> logError(
    AppException error, {
    String? userId,
    String? context,
    StackTrace? stackTrace,
  }) async {
    // Solo registrar errores que requieren notificación al admin
    if (!error.requiresAdminNotification) {
      return;
    }

    try {
      // Rate limiting
      final errorKey = '${error.type}_${context ?? ""}';
      if (_isRateLimited(errorKey)) {
        print('⏱️ Error logging rate limited: $errorKey');
        return;
      }

      // Actualizar timestamp del último error
      _lastErrorLog[errorKey] = DateTime.now();

      // Crear documento de error
      final errorDoc = {
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId ?? 'unknown',
        'errorType': error.type.toString(),
        'severity': error.severity.toString(),
        'userMessage': error.userMessage,
        'technicalMessage': error.technicalMessage,
        'errorCode': error.errorCode,
        'context': context,
        'stackTrace': stackTrace?.toString(),
        'platform': 'Flutter',
        'leido': false, // Para que admin pueda marcar como leído
      };

      // Guardar en Firestore
      await _firestore.collection('errores_sistema').add(errorDoc);

      print(
        '🚨 Error crítico registrado: ${error.type} - ${error.technicalMessage}',
      );
      print('📧 Notificación enviada al administrador');
    } catch (e) {
      // Si falla el logging, solo imprimir en consola para no causar más errores
      print('❌ Error al registrar error en Firestore: $e');
    }
  }

  // Verificar si el error está limitado por rate limiting
  bool _isRateLimited(String errorKey) {
    if (!_lastErrorLog.containsKey(errorKey)) {
      return false;
    }

    final lastLog = _lastErrorLog[errorKey]!;
    final now = DateTime.now();
    return now.difference(lastLog) < _rateLimitDuration;
  }

  // Marcar error como leído (para admin)
  Future<void> markAsRead(String errorId) async {
    try {
      await _firestore.collection('errores_sistema').doc(errorId).update({
        'leido': true,
        'fechaLectura': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al marcar error como leído: $e');
    }
  }

  // Obtener errores no leídos (para admin)
  Stream<List<Map<String, dynamic>>> getUnreadErrors() {
    return _firestore
        .collection('errores_sistema')
        .where('leido', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  // Limpiar errores antiguos (más de 30 días)
  Future<void> cleanOldErrors() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _firestore
          .collection('errores_sistema')
          .where('timestamp', isLessThan: thirtyDaysAgo)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print(
        '🧹 Limpieza de errores antiguos: ${snapshot.docs.length} eliminados',
      );
    } catch (e) {
      print('Error al limpiar errores antiguos: $e');
    }
  }
}
