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

  // Mensajes
  static const String msgLoginExitoso = 'Inicio de sesión exitoso';
  static const String msgLoginError = 'Error al iniciar sesión';
  static const String msgRegistroExitoso = 'Registro exitoso';
  static const String msgRegistroError = 'Error al registrar usuario';
  static const String msgCamposRequeridos = 'Todos los campos son requeridos';
  static const String msgEmailInvalido = 'Email inválido';
  static const String msgPasswordCorta =
      'La contraseña debe tener al menos 6 caracteres';

  // Configuración del Backend
  static const String backendUrl =
      'http://paqueteria.us-east-1.elasticbeanstalk.com';
}
