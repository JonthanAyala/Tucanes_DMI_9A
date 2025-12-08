// Modelo de Usuario - JaimeCAST69
class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String rol; // cliente, repartidor, admin
  final String? token;
  final String? fcmToken; // Token de Firebase Cloud Messaging
  // direccones del usuario

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.token,
    this.fcmToken,
  });

  // Serialización desde JSON
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? 'cliente',
      token: json['token'],
      fcmToken: json['fcmToken'],
    );
  }

  // Serialización a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'token': token,
      'fcmToken': fcmToken,
    };
  }

  // Copia con modificaciones
  Usuario copyWith({
    String? id,
    String? nombre,
    String? email,
    String? rol,
    String? token,
    String? fcmToken,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      token: token ?? this.token,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
