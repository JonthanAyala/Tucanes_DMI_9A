import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/paquete_viewmodel.dart';
import '../widgets/paquete_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as custom;
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'detalle_paquete_view.dart';
import 'crear_paquete_view.dart';

// Vista de lista de paquetes - BojitaNoir
class ListaPaquetesView extends StatefulWidget {
  const ListaPaquetesView({super.key});

  @override
  State<ListaPaquetesView> createState() => _ListaPaquetesViewState();
}

class _ListaPaquetesViewState extends State<ListaPaquetesView> {
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPaquetes();
    });
  }

  void _cargarPaquetes() {
    final authViewModel = context.read<AuthViewModel>();
    final paqueteViewModel = context.read<PaqueteViewModel>();
    final usuario = authViewModel.usuario;

    if (usuario != null) {
      if (usuario.rol == AppConstants.rolCliente) {
        paqueteViewModel.cargarPaquetesPorCliente(usuario.id);
      } else if (usuario.rol == AppConstants.rolRepartidor) {
        paqueteViewModel.cargarPaquetesPorRepartidor(usuario.id);
      } else {
        paqueteViewModel.cargarPaquetes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final paqueteViewModel = context.watch<PaqueteViewModel>();
    final usuario = authViewModel.usuario;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mis Paquetes'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _mostrarFiltros(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _cargarPaquetes();
        },
        child: paqueteViewModel.isLoading
            ? const LoadingWidget(message: 'Cargando paquetes...')
            : paqueteViewModel.errorMessage != null
            ? custom.ErrorWidget(
                message: paqueteViewModel.errorMessage!,
                onRetry: _cargarPaquetes,
              )
            : _buildListaPaquetes(paqueteViewModel),
      ),
      floatingActionButton:
          (usuario?.rol == AppConstants.rolCliente ||
              usuario?.rol == AppConstants.rolAdmin)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CrearPaqueteView()),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Paquete'),
            )
          : null,
    );
  }

  Widget _buildListaPaquetes(PaqueteViewModel viewModel) {
    final authViewModel = context.read<AuthViewModel>();
    final usuario = authViewModel.usuario;
    var paquetes = viewModel.paquetes;

    if (_filtroEstado != 'todos') {
      paquetes = viewModel.filtrarPorEstado(_filtroEstado);
    }

    if (paquetes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'No hay paquetes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Crea un nuevo paquete para comenzar',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: paquetes.length,
      itemBuilder: (context, index) {
        final paquete = paquetes[index];
        return PaqueteCard(
          paquete: paquete,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DetallePaqueteView(paquete: paquete),
              ),
            );
          },
          // Parámetros para repartidores
          mostrarBotonEstado: usuario?.rol == AppConstants.rolRepartidor,
          repartidorActualId: usuario?.id,
          onEstadoChange: usuario?.rol == AppConstants.rolRepartidor
              ? (nuevoEstado) =>
                    _cambiarEstadoPaquete(paquete.id, nuevoEstado, usuario!.id)
              : null,
        );
      },
    );
  }

  void _mostrarFiltros(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtrar por estado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildFiltroOption('todos', 'Todos'),
              _buildFiltroOption(AppConstants.estadoPendiente, 'Pendientes'),
              _buildFiltroOption(AppConstants.estadoAsignado, 'Asignados'),
              _buildFiltroOption(AppConstants.estadoEnTransito, 'En Tránsito'),
              _buildFiltroOption(AppConstants.estadoEntregado, 'Entregados'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiltroOption(String value, String label) {
    return ListTile(
      title: Text(label),
      leading: Radio<String>(
        value: value,
        groupValue: _filtroEstado,
        onChanged: (newValue) {
          setState(() {
            _filtroEstado = newValue!;
          });
          Navigator.pop(context);
        },
      ),
      onTap: () {
        setState(() {
          _filtroEstado = value;
        });
        Navigator.pop(context);
      },
    );
  }

  // Método para cambiar estado del paquete (repartidores)
  Future<void> _cambiarEstadoPaquete(
    String paqueteId,
    String nuevoEstado,
    String repartidorId,
  ) async {
    final paqueteViewModel = context.read<PaqueteViewModel>();

    bool success = false;
    String? mensajeExito;

    // Si es asignado, necesita asignar repartidor
    if (nuevoEstado == AppConstants.estadoAsignado) {
      success = await paqueteViewModel.actualizarEstado(paqueteId, nuevoEstado);
      mensajeExito = '✅ Paquete agregado a tu ruta';
    }
    // Si es devolver a pendiente, quitar repartidor
    else if (nuevoEstado == AppConstants.estadoPendiente) {
      success = await paqueteViewModel.actualizarEstado(paqueteId, nuevoEstado);
      mensajeExito = 'Paquete devuelto a disponibles';
    }
    // Para en_transito
    else if (nuevoEstado == AppConstants.estadoEnTransito) {
      success = await paqueteViewModel.actualizarEstado(paqueteId, nuevoEstado);
      mensajeExito = '📦 Paquete marcado como recogido';
    } else {
      // Para otros cambios de estado
      success = await paqueteViewModel.actualizarEstado(paqueteId, nuevoEstado);
      mensajeExito = 'Estado actualizado';
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeExito ?? 'Estado actualizado'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (paqueteViewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paqueteViewModel.errorMessage!),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
