import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/app_theme.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

// Vista de registro de usuarios
// Estructura inicial con selector de rol: JaimeCAST69 (versión original)
// Modificado para solo repartidores: Modificación posterior (líneas 1-234)
class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Variables para controlar visibilidad de contraseñas
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();

    // Todos los registros automáticos son CLIENTES
    final success = await authViewModel.registro(
      nombre: _nombreController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      rol: AppConstants.rolCliente, // Siempre cliente
    );

    if (!mounted) return;

    if (success) {
      // Navegar directamente al login
      // No hacemos logout porque puede causar problemas
      // El usuario se registró exitosamente y debe iniciar sesión
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppConstants.loginRoute,
        (route) => false, // Eliminar todas las rutas anteriores
      );

      // Mostrar mensaje de éxito después de navegar
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ Cuenta creada exitosamente\n'
                'Inicia sesión con tu correo y contraseña',
              ),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 4),
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.errorMessage ?? 'Error al registrar'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.person_add,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Crear Cuenta de Cliente',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completa el formulario para registrarte',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Campo de nombre
                CustomTextField(
                  controller: _nombreController,
                  label: 'Nombre Completo',
                  hint: 'Ingresa tu nombre',
                  prefixIcon: Icons.person,
                  validator: (value) =>
                      Validators.validateRequired(value, 'El nombre'),
                ),
                const SizedBox(height: 16),

                // Campo de email
                CustomTextField(
                  controller: _emailController,
                  label: 'Correo Electrónico',
                  hint: 'correo@ejemplo.com',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),

                // Campo de contraseña
                CustomTextField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  hint:
                      'Mínimo 8 caracteres (1 mayúscula, 1 minúscula, 1 número)',
                  prefixIcon: Icons.lock,
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de confirmar contraseña
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar Contraseña',
                  hint: 'Repite tu contraseña',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Información sobre el rol
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.secondaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.secondaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Te registrarás como Cliente. Los repartidores son creados por el administrador.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Botón de registro
                Consumer<AuthViewModel>(
                  builder: (context, authViewModel, _) {
                    return CustomButton(
                      text: 'Registrarse',
                      onPressed: _registrar,
                      isLoading: authViewModel.isLoading,
                      icon: Icons.person_add,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Link para volver al login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Ya tienes cuenta? ',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
