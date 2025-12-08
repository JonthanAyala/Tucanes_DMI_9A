import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notificacion_viewmodel.dart'; // JonthanAyala - Bandeja
import 'lista_paquetes_view.dart';
// import 'mapa_view.dart'; // Eliminado
import 'gestion_usuarios_view.dart';
// import 'estadisticas_view.dart'; // Eliminado
import 'paquetes_cercanos_view.dart'; // JonthanAyala - Paquetes Cercanos
import 'bandeja_notificaciones_view.dart'; // JonthanAyala - Bandeja
import 'perfil_view.dart';

// Vista principal con navegación
// Estructura base y navegación: Aserejex22 (líneas 1-40)
// Pestaña de usuarios para admin: JonthanAyala (líneas 25-75)
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final isAdmin = authViewModel.usuario?.rol == AppConstants.rolAdmin;

    // Páginas según el rol
    final List<Widget> pages = [
      const ListaPaquetesView(),
      // const MapaView(), // Eliminado
      // if (isAdmin) const EstadisticasView(), // Eliminado
      if (isAdmin) const GestionUsuariosView(),
      const PerfilView(),
    ];

    // Items del BottomNavigationBar según el rol
    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2_outlined),
        activeIcon: Icon(Icons.inventory_2),
        label: 'Paquetes',
      ),
      /* Eliminado Mapa
      const BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        activeIcon: Icon(Icons.map),
        label: 'Mapa',
      ),
      */
      /* Eliminado Estadísticas
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'Estadísticas',
        ),
      */
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outlined),
          activeIcon: Icon(Icons.people),
          label: 'Usuarios',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outlined),
        activeIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitulo(_currentIndex, isAdmin)),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Botón de notificaciones con badge
          Consumer<NotificacionViewModel>(
            builder: (context, notifViewModel, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BandejaNotificacionesView(),
                        ),
                      );
                    },
                  ),
                  if (notifViewModel.noLeidasCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notifViewModel.noLeidasCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        elevation: 8,
        items: navItems,
      ),
      // Botón flotante para repartidores - JonthanAyala
      floatingActionButton:
          authViewModel.usuario?.rol == AppConstants.rolRepartidor
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaquetesCercanosView(),
                  ),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.near_me),
              label: const Text('Cercanos'),
            )
          : null,
    );
  }

  // Obtener título según la página actual
  String _getTitulo(int index, bool isAdmin) {
    if (index == 0) return 'Paquetes';
    // if (index == 1) return 'Mapa'; // Eliminado
    if (isAdmin) {
      // if (index == 1) return 'Estadísticas'; // Eliminado
      if (index == 1) return 'Usuarios'; // Ajustado índice
      if (index == 2) return 'Perfil'; // Ajustado índice
    } else {
      if (index == 1) return 'Perfil'; // Ajustado índice
    }
    return 'Home';
  }
}
