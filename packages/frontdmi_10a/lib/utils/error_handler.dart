import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'app_exception.dart';
import 'error_types.dart';
import 'constants.dart';

// Manejador centralizado de errores - JonthanAyala
class ErrorHandler {
  // Convertir cualquier error a AppException
  static AppException handleError(dynamic error, {String? context}) {
    // Si ya es AppException, retornarla directamente
    if (error is AppException) {
      return error;
    }

    // Manejar errores de Firebase Auth
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error);
    }

    // Manejar errores de Firestore
    if (error is FirebaseException) {
      return _handleFirebaseError(error);
    }

    // Manejar errores de Dio (HTTP)
    if (error is DioException) {
      return _handleDioError(error);
    }

    // Manejar errores genéricos de Exception
    if (error is Exception) {
      final errorMsg = error.toString();

      // Detectar errores de permisos
      if (errorMsg.contains('Permisos') || errorMsg.contains('permission')) {
        if (errorMsg.contains('permanentemente')) {
          return AppException(
            type: ErrorType.permissionDeniedPermanently,
            userMessage: AppConstants.msgPermisosDenegadosPermanente,
            technicalMessage: errorMsg,
            originalError: error,
          );
        }
        return AppException(
          type: ErrorType.permissionDenied,
          userMessage: AppConstants.msgPermisosDenegados,
          technicalMessage: errorMsg,
          originalError: error,
        );
      }
    }

    // Error desconocido - tratarlo como crítico
    return AppException(
      type: ErrorType.unexpectedError,
      userMessage: AppConstants.msgErrorGenerico,
      technicalMessage: error.toString(),
      originalError: error,
    );
  }

  // Manejar errores de Firebase Auth
  static AppException _handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AppException(
          type: ErrorType.invalidCredentials,
          userMessage: AppConstants.msgCredencialesInvalidas,
          technicalMessage: 'Firebase Auth: ${error.code} - ${error.message}',
          errorCode: error.code,
          originalError: error,
        );

      case 'email-already-in-use':
        return AppException(
          type: ErrorType.duplicateEmail,
          userMessage: AppConstants.msgEmailDuplicado,
          technicalMessage: 'Firebase Auth: ${error.code} - ${error.message}',
          errorCode: error.code,
          originalError: error,
        );

      case 'invalid-email':
        return AppException(
          type: ErrorType.invalidEmail,
          userMessage: AppConstants.msgEmailInvalido,
          technicalMessage: 'Firebase Auth: ${error.code} - ${error.message}',
          errorCode: error.code,
          originalError: error,
        );

      case 'weak-password':
        return AppException(
          type: ErrorType.weakPassword,
          userMessage: AppConstants.msgPasswordCorta,
          technicalMessage: 'Firebase Auth: ${error.code} - ${error.message}',
          errorCode: error.code,
          originalError: error,
        );

      case 'network-request-failed':
        return AppException(
          type: ErrorType.noConnection,
          userMessage: AppConstants.msgSinConexion,
          technicalMessage: 'Firebase Auth: ${error.code} - ${error.message}',
          errorCode: error.code,
          originalError: error,
        );

      default:
        // Error desconocido de Firebase - tratarlo como crítico
        return AppException(
          type: ErrorType.firebaseError,
          userMessage: AppConstants.msgErrorServidor,
          technicalMessage: 'Firebase Auth: ${error.code} - ${error.message}',
          errorCode: error.code,
          originalError: error,
        );
    }
  }

  // Manejar errores de Firestore y Firebase en general
  static AppException _handleFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'unavailable':
      case 'deadline-exceeded':
        return AppException(
          type: ErrorType.serverUnavailable,
          userMessage: AppConstants.msgServidorNoDisponible,
          technicalMessage: 'Firebase: ${error.code} - ${error.message}',
          errorCode: error.code,
          originalError: error,
        );

      case 'not-found':
        return AppException(
          type: ErrorType.resourceNotFound,
          userMessage: AppConstants.msgRecursoNoEncontrado,
          technicalMessage: 'Firebase: ${error.code} - ${error.message}',
          errorCode: error.code,
          originalError: error,
        );

      case 'permission-denied':
        return AppException(
          type: ErrorType.operationNotAllowed,
          userMessage: AppConstants.msgOperacionNoPermitida,
          technicalMessage: 'Firebase: ${error.code} - ${error.message}',
          errorCode: error.code,
          originalError: error,
        );

      default:
        // Error desconocido de Firebase - tratarlo como crítico
        return AppException(
          type: ErrorType.firebaseError,
          userMessage: AppConstants.msgErrorServidor,
          technicalMessage: 'Firebase: ${error.code} - ${error.message}',
          errorCode: error.code,
          originalError: error,
        );
    }
  }

  // Manejar errores de Dio (HTTP/Backend)
  static AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return AppException(
          type: ErrorType.connectionTimeout,
          userMessage: AppConstants.msgTiempoEsperaAgotado,
          technicalMessage: 'Dio: ${error.type} - ${error.message}',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return AppException(
          type: ErrorType.noConnection,
          userMessage: AppConstants.msgSinConexion,
          technicalMessage: 'Dio: ${error.type} - ${error.message}',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return AppException(
            type: ErrorType.resourceNotFound,
            userMessage: AppConstants.msgRecursoNoEncontrado,
            technicalMessage: 'Dio: HTTP $statusCode - ${error.message}',
            errorCode: statusCode.toString(),
            originalError: error,
          );
        } else if (statusCode == 500 || statusCode == 503) {
          return AppException(
            type: ErrorType.serverUnavailable,
            userMessage: AppConstants.msgErrorServidor,
            technicalMessage: 'Dio: HTTP $statusCode - ${error.message}',
            errorCode: statusCode.toString(),
            originalError: error,
          );
        }
        // Otros errores HTTP
        return AppException(
          type: ErrorType.backendError,
          userMessage: AppConstants.msgErrorServidor,
          technicalMessage: 'Dio: HTTP $statusCode - ${error.message}',
          errorCode: statusCode.toString(),
          originalError: error,
        );

      default:
        return AppException(
          type: ErrorType.backendError,
          userMessage: AppConstants.msgErrorServidor,
          technicalMessage: 'Dio: ${error.type} - ${error.message}',
          originalError: error,
        );
    }
  }
}
