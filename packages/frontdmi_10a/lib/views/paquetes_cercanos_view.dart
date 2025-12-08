import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/paquete_model.dart';
import '../models/ubicacion_model.dart';
import '../services/paquete_service.dart';
import '../services/location_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/app_theme.dart';
import 'detalle_paquete_view.dart';

// Vista de paquetes cercanos - JonthanAyala
// Permite a repartidores auto-asignarse paquetes disponibles cerca de su ubicación
class PaquetesCercanosView extends StatefulWidget {
  const PaquetesCercanosView({super.key});

  @override
  State<PaquetesCercanosView> createState() => _PaquetesCercanosViewState();
}

class _PaquetesCercanosViewState extends State<PaquetesCercanosView> {
  final PaqueteService _paqueteService = PaqueteService();
  final LocationService _locationService = LocationService();

  Ubicacion? _ubicacionActual;
  List<_PaqueteConDistancia> _paquetesCercanos = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _radioKm = 10.0; // Radio de búsqueda en km

  @override
  void initState() {
    super.initState();
    _cargarPaquetesCercanos();
  }

  Future<void> _cargarPaquetesCercanos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Obtener ubicación actual
      _ubicacionActual = await _locationService.getCurrentLocation();

      // 2. Obtener paquetes disponibles
      final disponibles = await _paqueteService.obtenerPaquetesDisponibles();

      // 3. Calcular distancias (simuladas por ahora)
      // NOTA: En producción, los paquetes deberían tener coordenadas reales
      _paquetesCercanos = disponibles
          .map((paquete) {
            // Simular distancia aleatoria entre 0.5 y 15 km
            // En producción, usar coordenadas reales del paquete
            final distancia = 0.5 + Random().nextDouble() * 14.5;
            return _PaqueteConDistancia(paquete, distancia);
          })
          .where((p) => p.distancia <= _radioKm)
          .toList();

      // 4. Ordenar por distancia
      _paquetesCercanos.sort((a, b) => a.distancia.compareTo(b.distancia));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _tomarPaquete(_PaqueteConDistancia paqueteConDist) async {
    final authViewModel = context.read<AuthViewModel>();
    final usuario = authViewModel.usuario;

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no autenticado'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tomar Paquete'),
        content: Text(
          '¿Deseas tomar este paquete?\n\n'
          'Destinatario: ${paqueteConDist.paquete.destinatario}\n'
          'Distancia: ${paqueteConDist.distancia.toStringAsFixed(1)} km',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Tomar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Mostrar loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Intentar tomar el paquete
    final success = await _paqueteService.tomarPaquete(
      paqueteConDist.paquete.id,
      usuario.id,
    );

    // Cerrar loading
    if (mounted) Navigator.pop(context);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Paquete asignado correctamente'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );

      // Recargar lista
      await _cargarPaquetesCercanos();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ Error al tomar el paquete. Puede que ya esté asignado.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Paquetes Cercanos'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPaquetesCercanos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Buscando paquetes cercanos...',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error al cargar paquetes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _cargarPaquetesCercanos,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : _paquetesCercanos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 80,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay paquetes disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dentro de $_radioKm km de tu ubicación',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _cargarPaquetesCercanos,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Buscar nuevamente'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header con información
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_paquetesCercanos.length} paquetes disponibles',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Dentro de $_radioKm km',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de paquetes
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _cargarPaquetesCercanos,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _paquetesCercanos.length,
                      itemBuilder: (context, index) {
                        final item = _paquetesCercanos[index];
                        return _buildPaqueteCard(item);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPaqueteCard(_PaqueteConDistancia item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetallePaqueteView(paquete: item.paquete),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con distancia
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.near_me,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.distancia.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Disponible',
                      style: TextStyle(
                        color: AppTheme.warningColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Información del paquete
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.paquete.destinatario,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.paquete.destino['calle']} ${item.paquete.destino['numero']}, ${item.paquete.destino['colonia']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.scale,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.paquete.peso} kg',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Botón de tomar paquete
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _tomarPaquete(item),
                  icon: const Icon(Icons.add_task),
                  label: const Text('Tomar Paquete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Clase auxiliar para paquete con distancia
class _PaqueteConDistancia {
  final Paquete paquete;
  final double distancia; // en km

  _PaqueteConDistancia(this.paquete, this.distancia);
}
