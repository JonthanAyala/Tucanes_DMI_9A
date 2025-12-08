// Constantes globales de la aplicación
class AppConstants {
  // Rutas de navegación
  static const String loginRoute = '/login';
  static const String registroRoute = '/registro';
  static const String homeRoute = '/home';
  static const String listaPaquetesRoute = '/paquetes';
  static const String detallePaqueteRoute = '/paquete-detalle';
  static const String crearPaqueteRoute = '/paquete-crear';
  static const String editarPaqueteRoute = '/paquete-editar';
  static const String perfilRoute = '/perfil';
  static const String mapaRoute = '/mapa';

  // Roles de usuario
  static const String rolCliente = 'cliente';
  static const String rolRepartidor = 'repartidor';
  static const String rolAdmin = 'admin';

  // Estados de paquete
  static const String estadoPendiente = 'pendiente';
  static const String estadoAsignado = 'asignado';
  static const String estadoEnTransito = 'en_transito';
  static const String estadoEntregado = 'entregado';

  // Colecciones de Firebase
  static const String usuariosCollection = 'usuarios';
  static const String paquetesCollection = 'paquetes';

  // SharedPreferences keys
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserNombre = 'user_nombre';
  static const String keyUserRol = 'user_rol';
  static const String keyIsLoggedIn = 'is_logged_in';

  // Mensajes de éxito
  static const String msgLoginExitoso = 'Inicio de sesión exitoso';
  static const String msgRegistroExitoso = 'Registro exitoso';

  // Mensajes de validación
  static const String msgCamposRequeridos = 'Todos los campos son requeridos';
  static const String msgEmailInvalido = 'Email inválido';
  static const String msgPasswordCorta =
      'La contraseña debe tener al menos 6 caracteres';

  // Mensajes de error - Autenticación
  static const String msgCredencialesInvalidas =
      'Email o contraseña incorrectos';
  static const String msgEmailDuplicado =
      'Este email ya está registrado. Intenta iniciar sesión';
  static const String msgLoginError = 'Error al iniciar sesión';
  static const String msgRegistroError = 'Error al registrar usuario';

  // Mensajes de error - Red y conectividad
  static const String msgSinConexion =
      'Sin conexión a internet. Verifica tu conexión';
  static const String msgTiempoEsperaAgotado =
      'Tiempo de espera agotado. Intenta nuevamente';
  static const String msgServidorNoDisponible =
      'Servidor no disponible. Intenta más tarde';

  // Mensajes de error - Permisos
  static const String msgPermisosDenegados =
      'Se requieren permisos para continuar';
  static const String msgPermisosDenegadosPermanente =
      'Los permisos han sido denegados. Actívalos en la configuración';

  // Mensajes de error - Operaciones
  static const String msgRecursoNoEncontrado = 'Recurso no encontrado';
  static const String msgOperacionNoPermitida = 'Operación no permitida';
  static const String msgPaqueteYaAsignado = 'Este paquete ya fue asignado';

  // Mensajes de error - Genéricos
  static const String msgErrorGenerico =
      'Ocurrió un error. Por favor intenta nuevamente';
  static const String msgErrorServidor =
      'Error del servidor. Por favor intenta más tarde';

  // Configuración del Backend
  static const String backendUrl =
      'http://paqueteria.us-east-1.elasticbeanstalk.com';
}
