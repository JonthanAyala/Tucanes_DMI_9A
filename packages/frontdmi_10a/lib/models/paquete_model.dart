import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo de Paquete - BojitaNoir
class Paquete {
  final String id;
  final String destinatario;
  // final String direccion; // ELIMINADO: Reemplazado por origen y destino
  final Map<String, dynamic> origen;
  final Map<String, dynamic> destino;
  final double peso;
  final String estado; // pendiente, asignado, en_transito, entregado.
  final String? fotoUrl;
  final DateTime fechaCreacion;
  final String? repartidorId;
  final String? clienteId;
  final String? codigoQR;
  final Map<String, dynamic>? ubicacionRecoleccion; // {lat, lng, timestamp}
  final Map<String, dynamic>? ubicacionEntrega; // {lat, lng, timestamp}

  Paquete({
    required this.id,
    required this.destinatario,
    required this.origen,
    required this.destino,
    required this.peso,
    required this.estado,
    this.fotoUrl,
    required this.fechaCreacion,
    this.repartidorId,
    this.clienteId,
    this.codigoQR,
    this.ubicacionRecoleccion,
    this.ubicacionEntrega,
  });

  // Serialización desde JSON
  factory Paquete.fromJson(Map<String, dynamic> json) {
    return Paquete(
      id: json['id'] ?? '',
      destinatario: json['destinatario'] ?? '',
      origen: json['origen'] != null
          ? Map<String, dynamic>.from(json['origen'])
          : {
              'direccion': json['direccion'] ?? '',
            }, // Fallback para datos viejos
      destino: json['destino'] != null
          ? Map<String, dynamic>.from(json['destino'])
          : {
              'direccion': json['direccion'] ?? '',
            }, // Fallback para datos viejos
      peso: (json['peso'] ?? 0).toDouble(),
      estado: json['estado'] ?? 'pendiente',
      fotoUrl: json['fotoUrl'],
      fechaCreacion: json['fechaCreacion'] != null
          ? (json['fechaCreacion'] as Timestamp).toDate()
          : DateTime.now(),
      repartidorId: json['repartidorId'],
      clienteId: json['clienteId'],
      codigoQR: json['codigoQR'],
      ubicacionRecoleccion: json['ubicacionRecoleccion'] != null
          ? Map<String, dynamic>.from(json['ubicacionRecoleccion'])
          : null,
      ubicacionEntrega: json['ubicacionEntrega'] != null
          ? Map<String, dynamic>.from(json['ubicacionEntrega'])
          : null,
    );
  }

  // Serialización a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destinatario': destinatario,
      'origen': origen,
      'destino': destino,
      'peso': peso,
      'estado': estado,
      'fotoUrl': fotoUrl,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'repartidorId': repartidorId,
      'clienteId': clienteId,
      'codigoQR': codigoQR,
      'ubicacionRecoleccion': ubicacionRecoleccion,
      'ubicacionEntrega': ubicacionEntrega,
    };
  }

  // Copia con modificaciones
  Paquete copyWith({
    String? id,
    String? destinatario,
    Map<String, dynamic>? origen,
    Map<String, dynamic>? destino,
    double? peso,
    String? estado,
    String? fotoUrl,
    DateTime? fechaCreacion,
    String? repartidorId,
    String? clienteId,
    String? codigoQR,
    Map<String, dynamic>? ubicacionRecoleccion,
    Map<String, dynamic>? ubicacionEntrega,
  }) {
    return Paquete(
      id: id ?? this.id,
      destinatario: destinatario ?? this.destinatario,
      origen: origen ?? this.origen,
      destino: destino ?? this.destino,
      peso: peso ?? this.peso,
      estado: estado ?? this.estado,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      repartidorId: repartidorId ?? this.repartidorId,
      clienteId: clienteId ?? this.clienteId,
      codigoQR: codigoQR ?? this.codigoQR,
      ubicacionRecoleccion: ubicacionRecoleccion ?? this.ubicacionRecoleccion,
      ubicacionEntrega: ubicacionEntrega ?? this.ubicacionEntrega,
    );
  }
}
