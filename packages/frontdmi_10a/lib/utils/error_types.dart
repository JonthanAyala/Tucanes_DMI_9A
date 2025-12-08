// Tipos de errores categorizados por severidad - JonthanAyala
enum ErrorType {
  // Errores de usuario (UX) - No críticos
  invalidCredentials, // Credenciales incorrectas
  emptyFields, // Campos vacíos o incompletos
  invalidEmail, // Email no válido
  weakPassword, // Contraseña débil
  permissionDenied, // Permisos denegados por el usuario
  permissionDeniedPermanently, // Permisos denegados permanentemente
  // Errores de red (Recuperables)
  noConnection, // Sin conexión a internet
  connectionTimeout, // Tiempo de espera agotado
  serverUnavailable, // Servidor no disponible
  // Errores de negocio (Validación)
  packageAlreadyAssigned, // Paquete ya asignado
  operationNotAllowed, // Operación no permitida
  duplicateEmail, // Email ya registrado
  userNotFound, // Usuario no encontrado
  resourceNotFound, // Recurso no encontrado
  // Errores graves (Críticos) - Requieren notificación al admin
  firebaseError, // Error de Firebase
  databaseError, // Error de base de datos
  storageError, // Error de almacenamiento
  unexpectedError, // Error inesperado
  backendError, // Error del backend
}

// Severidad del error
enum ErrorSeverity {
  low, // Usuario puede continuar, no afecta funcionalidad crítica
  medium, // Usuario puede reintentar, funcionalidad parcialmente afectada
  high, // Funcionalidad crítica afectada, requiere notificación al admin
}

// Extensión para obtener severidad de un tipo de error
extension ErrorTypeExtension on ErrorType {
  ErrorSeverity get severity {
    switch (this) {
      // Errores de usuario - Severidad baja
      case ErrorType.invalidCredentials:
      case ErrorType.emptyFields:
      case ErrorType.invalidEmail:
      case ErrorType.weakPassword:
      case ErrorType.permissionDenied:
      case ErrorType.permissionDeniedPermanently:
        return ErrorSeverity.low;

      // Errores de red - Severidad media
      case ErrorType.noConnection:
      case ErrorType.connectionTimeout:
      case ErrorType.serverUnavailable:
        return ErrorSeverity.medium;

      // Errores de negocio - Severidad media
      case ErrorType.packageAlreadyAssigned:
      case ErrorType.operationNotAllowed:
      case ErrorType.duplicateEmail:
      case ErrorType.userNotFound:
      case ErrorType.resourceNotFound:
        return ErrorSeverity.medium;

      // Errores graves - Severidad alta
      case ErrorType.firebaseError:
      case ErrorType.databaseError:
      case ErrorType.storageError:
      case ErrorType.unexpectedError:
      case ErrorType.backendError:
        return ErrorSeverity.high;
    }
  }

  bool get requiresAdminNotification {
    return severity == ErrorSeverity.high;
  }
}
