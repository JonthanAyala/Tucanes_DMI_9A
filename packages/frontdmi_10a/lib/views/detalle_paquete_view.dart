import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart'; // JonthanAyala - QR
import '../models/paquete_model.dart';
import '../models/usuario_model.dart'; // JonthanAyala - Usuario
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/paquete_viewmodel.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';
import 'editar_paquete_view.dart';
import 'qr_scanner_view.dart';

// Vista de detalle de paquete - BojitaNoir
class DetallePaqueteView extends StatelessWidget {
  final Paquete paquete;

  const DetallePaqueteView({super.key, required this.paquete});

  Color _getEstadoColor() {
    switch (paquete.estado) {
      case 'pendiente':
        return AppTheme.warningColor;
      case 'asignado':
        return Colors.blue;
      case 'en_transito':
        return AppTheme.secondaryColor;
      case 'entregado':
        return AppTheme.successColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getEstadoTexto() {
    switch (paquete.estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'asignado':
        return 'Asignado';
      case 'en_transito':
        return 'En Tránsito';
      case 'entregado':
        return 'Entregado';
      default:
        return paquete.estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final usuario = authViewModel.usuario;
    final puedeEditar =
        usuario?.rol == AppConstants.rolAdmin ||
        usuario?.rol == AppConstants.rolRepartidor;
    final puedeEliminar = usuario?.rol == AppConstants.rolAdmin;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Detalle del Paquete'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          if (puedeEditar)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditarPaqueteView(paquete: paquete),
                  ),
                );
              },
            ),
          if (puedeEliminar)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmarEliminar(context),
            ),
          // Botón de escanear QR para repartidores (en AppBar)
          if (usuario?.rol == AppConstants.rolRepartidor &&
              paquete.repartidorId == usuario?.id && // Solo su paquete
              paquete.estado == 'en_transito' && // Solo en tránsito
              paquete.codigoQR != null)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Escanear QR para entregar',
              onPressed: () => _escanearQR(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto del paquete (LOCAL o URL)
            if (paquete.fotoUrl != null)
              Container(
                width: double.infinity,
                height: 250,
                color: AppTheme.textSecondary.withOpacity(0.1),
                child: _buildImagen(paquete.fotoUrl!),
              )
            else
              Container(
                width: double.infinity,
                height: 250,
                color: AppTheme.textSecondary.withOpacity(0.1),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: AppTheme.textSecondary,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _getEstadoColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getEstadoTexto(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getEstadoColor(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Información del remitente (Origen)
                  _buildInfoCard('Información del Remitente', [
                    _buildInfoRow(
                      Icons.home,
                      'Dirección de Recolección',
                      '${paquete.origen['calle']} ${paquete.origen['numero']}, ${paquete.origen['colonia']}, ${paquete.origen['municipio']}',
                      onTap: () => _abrirGoogleMaps(
                        context,
                        '${paquete.origen['calle']} ${paquete.origen['numero']}, ${paquete.origen['colonia']}, ${paquete.origen['municipio']}',
                      ),
                    ),
                    if (paquete.origen['telefono'] != null &&
                        paquete.origen['telefono'].toString().isNotEmpty)
                      _buildInfoRow(
                        Icons.phone,
                        'Teléfono de Contacto',
                        paquete.origen['telefono'].toString(),
                        onTap: () => _llamarTelefono(
                          context,
                          paquete.origen['telefono'].toString(),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 16),

                  // Información del destinatario
                  _buildInfoCard('Información del Destinatario', [
                    _buildInfoRow(
                      Icons.person,
                      'Destinatario',
                      paquete.destinatario,
                    ),
                    _buildInfoRow(
                      Icons.location_on,
                      'Dirección de Entrega',
                      '${paquete.destino['calle']} ${paquete.destino['numero']}, ${paquete.destino['colonia']}, ${paquete.destino['municipio']}',
                      onTap: () => _abrirGoogleMaps(
                        context,
                        '${paquete.destino['calle']} ${paquete.destino['numero']}, ${paquete.destino['colonia']}, ${paquete.destino['municipio']}',
                      ),
                    ),
                    if (paquete.destino['telefono'] != null &&
                        paquete.destino['telefono'].toString().isNotEmpty)
                      _buildInfoRow(
                        Icons.phone,
                        'Teléfono de Contacto',
                        paquete.destino['telefono'].toString(),
                        onTap: () => _llamarTelefono(
                          context,
                          paquete.destino['telefono'].toString(),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 16),

                  _buildInfoCard('Detalles del Paquete', [
                    _buildInfoRow(Icons.scale, 'Peso', '${paquete.peso} kg'),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Fecha de Creación',
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(paquete.fechaCreacion),
                    ),
                    if (paquete.codigoQR != null)
                      _buildInfoRow(
                        Icons.qr_code,
                        'Código QR',
                        paquete.codigoQR!,
                      ),
                  ]),

                  // Sección QR para el cliente (dueño del paquete)
                  if (paquete.codigoQR != null &&
                      usuario?.id == paquete.clienteId)
                    _buildSeccionQR(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildBotonEntrega(context, usuario),
    );
  }

  // Botón flotante para entregar paquete (Solo repartidor asignado)
  Widget? _buildBotonEntrega(BuildContext context, Usuario? usuario) {
    // Solo mostrar si es repartidor, es su paquete y está en tránsito
    if (usuario?.rol != AppConstants.rolRepartidor) return null;
    if (paquete.repartidorId != usuario?.id) return null;
    if (paquete.estado != 'en_transito') return null;
    if (paquete.codigoQR == null) return null;

    return FloatingActionButton.extended(
      onPressed: () => _escanearQR(context),
      backgroundColor: AppTheme.successColor,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Entregar Paquete'),
    );
  }

  // Sección visual del código QR para el cliente
  Widget _buildSeccionQR() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '📱 Código QR para Entrega',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Muestra este código al repartidor para confirmar la entrega',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor, width: 2),
            ),
            child: QrImageView(
              data: paquete.codigoQR!,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            paquete.codigoQR!,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: onTap != null
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimary,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(Icons.open_in_new, size: 18, color: AppTheme.primaryColor),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(padding: const EdgeInsets.all(8), child: content),
            )
          : content,
    );
  }

  // Método helper para mostrar imagen local o de red
  // NOTA: Actualmente muestra imágenes LOCALES (File)
  // Para URLs de Firebase Storage, descomentar Image.network
  Widget _buildImagen(String ruta) {
    // Si la ruta empieza con http, es una URL (Firebase Storage futuro)
    if (ruta.startsWith('http')) {
      // FIREBASE STORAGE (futuro)
      return Image.network(
        ruta,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.image_not_supported,
          size: 80,
          color: AppTheme.textSecondary,
        ),
      );
    } else {
      // ALMACENAMIENTO LOCAL (actual)
      final file = File(ruta);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      } else {
        return const Icon(
          Icons.image_not_supported,
          size: 80,
          color: AppTheme.textSecondary,
        );
      }
    }
  }

  // Método para escanear QR y confirmar entrega
  void _escanearQR(BuildContext context) async {
    if (paquete.codigoQR == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QRScannerView(
          paqueteId: paquete.id,
          codigoQREsperado: paquete.codigoQR!,
        ),
      ),
    );

    if (result == true && context.mounted) {
      Navigator.pop(context); // Volver a la lista después de confirmar entrega
    }
  }

  // Abrir Google Maps con la dirección del paquete
  Future<void> _abrirGoogleMaps(BuildContext context, String direccion) async {
    final query = Uri.encodeComponent(direccion);
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir Google Maps'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir mapa: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Paquete'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este paquete?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final paqueteViewModel = context.read<PaqueteViewModel>();
              final success = await paqueteViewModel.eliminarPaquete(
                paquete.id,
              );

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Paquete eliminado correctamente'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  // Método para realizar llamadas telefónicas
  Future<void> _llamarTelefono(BuildContext context, String telefono) async {
    // Limpiar el número de teléfono
    final numLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:$numLimpio');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo realizar la llamada'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al llamar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
