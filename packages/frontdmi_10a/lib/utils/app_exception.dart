import 'error_types.dart';

// Excepción personalizada de la aplicación - JonthanAyala
class AppException implements Exception {
  final ErrorType type;
  final String userMessage; // Mensaje amigable para el usuario
  final String technicalMessage; // Mensaje técnico para logs/debugging
  final String? errorCode; // Código de error opcional
  final dynamic originalError; // Error original para debugging

  AppException({
    required this.type,
    required this.userMessage,
    required this.technicalMessage,
    this.errorCode,
    this.originalError,
  });

  // Constructor para crear desde un error desconocido
  factory AppException.fromError(
    dynamic error, {
    ErrorType? type,
    String? userMessage,
  }) {
    final String technicalMsg = error.toString();

    return AppException(
      type: type ?? ErrorType.unexpectedError,
      userMessage: userMessage ?? 'Ocurrió un error inesperado',
      technicalMessage: technicalMsg,
      originalError: error,
    );
  }

  @override
  String toString() {
    return 'AppException(type: $type, userMessage: $userMessage, '
        'technicalMessage: $technicalMessage, errorCode: $errorCode)';
  }

  // Obtener severidad del error
  ErrorSeverity get severity => type.severity;

  // Verificar si requiere notificación al admin
  bool get requiresAdminNotification => type.requiresAdminNotification;
}
