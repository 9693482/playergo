class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email requerido';
    final regex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Email inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Contraseña requerida';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Debe tener una mayúscula';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Debe tener una minúscula';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Debe tener un número';
    return null;
  }

  static String? required(String? value, [String field = 'Campo']) {
    if (value == null || value.trim().isEmpty) return '$field requerido';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Teléfono requerido';
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (cleaned.length < 8 || cleaned.length > 15) return 'Teléfono inválido';
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) return 'Solo números';
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return 'Precio requerido';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Precio inválido';
    if (parsed <= 0) return 'Debe ser mayor a 0';
    if (parsed > 10000) return 'Precio demasiado alto';
    return null;
  }

  static String? maxLength(String? value, int max, [String field = 'Campo']) {
    if (value != null && value.length > max) return '$field máximo $max caracteres';
    return null;
  }

  static String? minLength(String? value, int min, [String field = 'Campo']) {
    if (value != null && value.length < min) return '$field mínimo $min caracteres';
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nombre requerido';
    if (value.trim().length < 2) return 'Nombre muy corto';
    if (value.trim().length > 100) return 'Nombre muy largo';
    return null;
  }

  static String? teamName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nombre del equipo requerido';
    if (value.trim().length < 3) return 'Mínimo 3 caracteres';
    if (value.trim().length > 50) return 'Máximo 50 caracteres';
    return null;
  }

  static String? description(String? value) {
    if (value != null && value.length > 500) return 'Máximo 500 caracteres';
    return null;
  }

  static String? sanitize(String? value) {
    if (value == null) return null;
    return value
        .replaceAll('<script', '')
        .replaceAll('</script', '')
        .replaceAll('javascript:', '')
        .trim();
  }
}
