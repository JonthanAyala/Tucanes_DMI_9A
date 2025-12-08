// Validadores de formularios
class Validators {
  // Validar email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }

    return null;
  }

  // Validar contraseña
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    // Verificar mayúscula
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe incluir al menos una mayúscula';
    }

    // Verificar minúscula
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'La contraseña debe incluir al menos una minúscula';
    }

    // Verificar número
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe incluir al menos un número';
    }

    return null;
  }

  // Validar campo requerido
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  // Validar número
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }

    if (double.tryParse(value) == null) {
      return '$fieldName debe ser un número válido';
    }

    return null;
  }

  // Validar peso
  static String? validatePeso(String? value) {
    if (value == null || value.isEmpty) {
      return 'El peso es requerido';
    }

    final peso = double.tryParse(value);
    if (peso == null || peso <= 0) {
      return 'El peso debe ser mayor a 0';
    }

    return null;
  }
}
