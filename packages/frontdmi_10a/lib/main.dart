import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/paquete_viewmodel.dart';
import 'viewmodels/usuario_viewmodel.dart'; // JonthanAyala
import 'viewmodels/notificacion_viewmodel.dart'; // JonthanAyala - Bandeja
// import 'viewmodels/estadistica_viewmodel.dart'; // Eliminado
import 'services/auth_service.dart';
import 'services/api_service.dart'; // JonthanAyala - Dio
import 'services/notification_service.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'utils/app_theme.dart';

// Aplicación principal de gestión de paquetería
// Configuración base: JaimeCAST69 (líneas 1-129)
// Provider de UsuarioViewModel: JonthanAyala (línea 30)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  // NOTA: Debes configurar Firebase en tu proyecto antes de ejecutar
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Servicios
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => NotificationService()),
        ProxyProvider<AuthService, ApiService>(
          update: (_, authService, __) => ApiService(authService),
        ),

        // ViewModels
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => PaqueteViewModel()),
        ChangeNotifierProvider(create: (_) => UsuarioViewModel()),
        ChangeNotifierProvider(create: (_) => NotificacionViewModel()),
        /* Eliminado EstadisticaViewModel
        ChangeNotifierProxyProvider<ApiService, EstadisticaViewModel>(
          create: (context) => EstadisticaViewModel(context.read<ApiService>()),
          update: (_, apiService, viewModel) =>
              viewModel ?? EstadisticaViewModel(apiService),
        ),
        */
      ],
      child: MaterialApp(
        title: 'Gestión de Paquetería',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

// Pantalla de carga inicial
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializar();
    });
  }

  Future<void> _inicializar() async {
    final authViewModel = context.read<AuthViewModel>();

    try {
      // Intentamos inicializar. Si falla por internet, saltará al 'catch'
      await authViewModel.inicializar().timeout(
        const Duration(
          seconds: 5,
        ), // Límite de 5 segundos para no congelar la app
        onTimeout: () {
          throw Exception("Tiempo de espera agotado");
        },
      );
    } catch (e) {
      print("Error al inicializar o sin internet: $e");
      // Aquí puedes decidir qué hacer si falla.
      // Por lo general, si falla, mandamos al Login para que reintente manual.
    }

    if (mounted) {
      // Verificamos el estado (si falló el inicializar, isLoggedIn será false)
      if (authViewModel.isLoggedIn) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeView()));
      } else {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginView()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: AppTheme.textLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.local_shipping,
                size: 70,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gestión de Paquetería',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}
