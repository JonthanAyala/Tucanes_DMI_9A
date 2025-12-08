import 'package:flutter/material.dart';
import '../models/paquete_model.dart';
import '../utils/app_theme.dart';
import 'package:intl/intl.dart';

// Card de paquete para lista - BojitaNoir + JonthanAyala (botón repartidor)
class PaqueteCard extends StatelessWidget {
  final Paquete paquete;
  final VoidCallback onTap;
  final Function(String nuevoEstado)? onEstadoChange;
  final bool mostrarBotonEstado;
  final String? repartidorActualId;

  const PaqueteCard({
    super.key,
    required this.paquete,
    required this.onTap,
    this.onEstadoChange,
    this.mostrarBotonEstado = false,
    this.repartidorActualId,
  });

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

  // Obtener siguiente estado según flujo del repartidor
  String? _getSiguienteEstado() {
    switch (paquete.estado) {
      case 'pendiente':
        return 'asignado'; // Tomar paquete
      case 'asignado':
        return 'en_transito'; // Ten go el paquete
      case 'en_transito':
        return null; // Requiere escaneo QR
      default:
        return null;
    }
  }

  String _getTextoBoton() {
    switch (paquete.estado) {
      case 'pendiente':
        return 'Tomar';
      case 'asignado':
        return 'Recoger';
      case 'en_transito':
        return 'Entregar';
      default:
        return '';
    }
  }

  IconData _getIconoBoton() {
    switch (paquete.estado) {
      case 'pendiente':
        return Icons.add_task;
      case 'asignado':
        return Icons.local_shipping;
      case 'en_transito':
        return Icons.qr_code_scanner;
      default:
        return Icons.check;
    }
  }

  bool _puedeModificar() {
    // Para pendientes, cualquiera puede tomar
    if (paquete.estado == 'pendiente') return true;
    // Para asignados o en tránsito, solo el repartidor asignado
    if (paquete.repartidorId != null && repartidorActualId != null) {
      return paquete.repartidorId == repartidorActualId;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          paquete.destinatario,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getEstadoColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            if (paquete.codigoQR != null)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.qr_code,
                                  size: 14,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            Text(
                              _getEstadoTexto(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getEstadoColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${paquete.destino['calle']} ${paquete.destino['numero']}, ${paquete.destino['colonia']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.scale,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${paquete.peso} kg',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(paquete.fechaCreacion),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Espacio extra si hay botón
                  if (mostrarBotonEstado &&
                      _puedeModificar() &&
                      _getSiguienteEstado() != null)
                    const SizedBox(height: 48),
                ],
              ),
            ),
            // Botón de cambio de estado (solo repartidores)
            if (mostrarBotonEstado &&
                _puedeModificar() &&
                _getSiguienteEstado() != null)
              Positioned(
                bottom: 12,
                right: 12,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final siguiente = _getSiguienteEstado();
                    if (siguiente != null) {
                      onEstadoChange?.call(siguiente);
                    }
                  },
                  icon: Icon(_getIconoBoton(), size: 18),
                  label: Text(_getTextoBoton()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            // Menú para devolver paquete (solo si está asignado al repartidor)
            if (mostrarBotonEstado &&
                paquete.estado == 'asignado' &&
                paquete.repartidorId == repartidorActualId)
              Positioned(
                top: 8,
                right: 8,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'devolver',
                      child: Row(
                        children: [
                          Icon(Icons.undo, size: 18),
                          SizedBox(width: 8),
                          Text('Devolver paquete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'devolver') {
                      onEstadoChange?.call('pendiente');
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
