/// Cada validador devuelve null si todo está bien, o el mensaje de error.
/// Se validan en la app para dar buena experiencia; el SERVIDOR siempre vuelve a validar.

String? validarNombre(String v) {
  final t = v.trim();
  if (t.length < 2) return 'Escribe tu nombre completo.';
  if (t.length > 60) return 'El nombre es demasiado largo.';
  return null;
}

String? validarCorreo(String v) {
  final t = v.trim();
  if (t.length > 254 || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(t)) {
    return 'Escribe un correo válido.';
  }
  return null;
}

String? validarPassword(String v) {
  if (v.length < 8) return 'La contraseña debe tener al menos 8 caracteres.';
  if (v.length > 72) return 'La contraseña es demasiado larga.';
  if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
    return 'La contraseña debe combinar letras y números.';
  }
  return null;
}

String? validarCodigoPostal(String v) =>
    RegExp(r'^\d{5}$').hasMatch(v.trim()) ? null : 'El código postal debe tener 5 dígitos.';

String? validarTelefono(String v) {
  final digitos = v.replaceAll(RegExp(r'[\s\-()]'), '');
  return RegExp(r'^\d{10}$').hasMatch(digitos) ? null : 'El teléfono debe tener 10 dígitos.';
}

String? validarTextoObligatorio(String v, String campo, {int max = 80}) {
  final t = v.trim();
  if (t.length < 3) return 'Escribe $campo.';
  if (t.length > max) return '$campo es demasiado largo.';
  return null;
}