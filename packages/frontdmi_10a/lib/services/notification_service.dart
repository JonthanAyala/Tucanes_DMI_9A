import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/error_handler.dart';
import 'error_logging_service.dart';

// Servicio de notificaciones push - JaimeCAST69
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ErrorLoggingService _errorLogger = ErrorLoggingService();

  // Inicializar servicio de notificaciones
  Future<void> inicializar({String? userId}) async {
    try {
      // Solicitar permisos
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      // Configurar notificaciones locales
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(initSettings);

      // Obtener token FCM
      final token = await _messaging.getToken();
      if (token != null) {
        print('FCM Token obtenido: $token');

        // Guardar token en Firestore si hay usuario logueado
        if (userId != null) {
          await guardarTokenEnFirestore(userId, token);
        }
      }

      // Escuchar mensajes en foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Escuchar mensajes cuando la app se abre desde notificación
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'NotificationService.inicializar',
      );
      print('⚠️ Error al inicializar notificaciones: ${appError.userMessage}');
      if (appError.requiresAdminNotification) {
        await _errorLogger.logError(
          appError,
          userId: userId,
          context: 'Inicialización de notificaciones',
        );
      }
      // No lanzar error para no bloquear el inicio de la app
    }
  }

  // Manejar mensaje en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('Mensaje recibido en foreground: ${message.notification?.title}');

    if (message.notification != null) {
      _mostrarNotificacionLocal(
        message.notification!.title ?? '',
        message.notification!.body ?? '',
      );

      // Guardar notificación en Firestore
      _guardarNotificacionEnFirestore(message);
    }
  }

  // Manejar cuando se abre la app desde notificación
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App abierta desde notificación: ${message.notification?.title}');
    // TODO: Navegar a pantalla específica según el mensaje
  }

  // Guardar notificación en Firestore
  Future<void> _guardarNotificacionEnFirestore(RemoteMessage message) async {
    try {
      // Extraer userId del data payload
      final userId = message.data['userId'] as String?;
      if (userId == null) {
        print('No se puede guardar notificación: userId no encontrado');
        return;
      }

      final notificacionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Guardar en la subcolección del usuario
      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('notificaciones')
          .doc(notificacionId)
          .set({
            'id': notificacionId,
            'userId': userId,
            'titulo': message.notification?.title ?? 'Notificación',
            'mensaje': message.notification?.body ?? '',
            'tipo': message.data['tipo'] ?? 'sistema',
            'fecha': FieldValue.serverTimestamp(),
            'leida': false,
            'data': message.data,
          });

      print('Notificación guardada en Firestore: $notificacionId');
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'NotificationService._guardarNotificacionEnFirestore',
      );
      print('⚠️ Error al guardar notificación: ${appError.userMessage}');
      if (appError.requiresAdminNotification) {
        // Extraer userId del mensaje para el log
        final uid = message.data['userId'] as String?;
        await _errorLogger.logError(
          appError,
          userId: uid,
          context: 'Guardar notificación en Firestore',
        );
      }
    }
  }

  // Mostrar notificación local
  Future<void> _mostrarNotificacionLocal(String titulo, String cuerpo) async {
    const androidDetails = AndroidNotificationDetails(
      'paqueteria_channel',
      'Paquetería',
      channelDescription: 'Notificaciones de paquetes',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecond,
      titulo,
      cuerpo,
      notificationDetails,
    );
  }

  // Obtener token FCM
  Future<String?> obtenerToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'NotificationService.obtenerToken',
      );
      print('⚠️ Error al obtener token FCM: ${appError.userMessage}');
      return null;
    }
  }

  // Guardar token en Firestore
  Future<void> guardarTokenEnFirestore(String userId, String token) async {
    try {
      await _firestore.collection('usuarios').doc(userId).update({
        'fcmToken': token,
        'ultimaActualizacionToken': FieldValue.serverTimestamp(),
      });
      print('Token guardado en Firestore para usuario: $userId');
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'NotificationService.guardarTokenEnFirestore',
      );
      print('⚠️ Error al guardar token: ${appError.userMessage}');
      if (appError.requiresAdminNotification) {
        await _errorLogger.logError(
          appError,
          userId: userId,
          context: 'Guardar FCM token en Firestore',
        );
      }
    }
  }

  // Limpiar token al cerrar sesión
  Future<void> cerrarSesion(String userId) async {
    try {
      // Eliminar token de Firestore
      await _firestore.collection('usuarios').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'ultimaActualizacionToken': FieldValue.delete(),
      });
      print('Token eliminado de Firestore para usuario: $userId');

      // Eliminar token del dispositivo
      await _messaging.deleteToken();
      print('Token FCM eliminado del dispositivo');
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'NotificationService.cerrarSesion',
      );
      print(
        '⚠️ Error al cerrar sesión de notificaciones: ${appError.userMessage}',
      );
      // No registrar como crítico ya que el cierre de sesión puede continuar
    }
  }
}
