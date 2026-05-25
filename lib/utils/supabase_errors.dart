import 'package:supabase_flutter/supabase_flutter.dart';

class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Convierte errores crudos de Supabase/Postgrest en mensajes legibles en español.
AppException parseSupabaseError(Object error) {
  if (error is AppException) return error;

  if (error is AuthException) {
    return AppException(
      _authMessage(error.message),
      code: error.statusCode?.toString(),
    );
  }

  if (error is PostgrestException) {
    return AppException(
      _postgrestMessage(error.message, error.code),
      code: error.code,
    );
  }

  final raw = error.toString().toLowerCase();
  if (raw.contains('network') ||
      raw.contains('socket') ||
      raw.contains('connection refused') ||
      raw.contains('failed host lookup')) {
    return const AppException('Sin conexión. Revisá tu red e intentá de nuevo.');
  }

  return const AppException('Ocurrió un error inesperado. Intentá de nuevo.');
}

String _authMessage(String raw) {
  final msg = raw.toLowerCase();
  if (msg.contains('invalid login credentials') ||
      msg.contains('invalid email or password')) {
    return 'Email o contraseña incorrectos';
  }
  if (msg.contains('email not confirmed')) {
    return 'Confirmá tu email antes de ingresar';
  }
  if (msg.contains('user already registered') ||
      msg.contains('already been registered')) {
    return 'Ya existe una cuenta con ese email';
  }
  if (msg.contains('password should be at least')) {
    return 'La contraseña debe tener al menos 6 caracteres';
  }
  if (msg.contains('jwt expired') || msg.contains('token is expired')) {
    return 'Tu sesión expiró, ingresá de nuevo';
  }
  if (msg.contains('signup disabled')) {
    return 'El registro está desactivado temporalmente';
  }
  if (msg.contains('email rate limit')) {
    return 'Demasiados intentos. Esperá unos minutos';
  }
  return raw;
}

String _postgrestMessage(String raw, String? code) {
  final msg = raw.toLowerCase();

  // Unique violations
  if (code == '23505' || msg.contains('duplicate key')) {
    if (msg.contains('usuarios_figuritas')) return 'Ya tenés esa figurita registrada';
    if (msg.contains('favoritos'))          return 'Ya la tenés en favoritos';
    if (msg.contains('matches'))            return 'Ya existe un match con ese usuario';
    if (msg.contains('usuarios'))           return 'Ya existe una cuenta con ese dato';
    return 'Registro duplicado';
  }

  // FK violations
  if (code == '23503' || msg.contains('foreign key')) {
    return 'Referencia inválida. El dato relacionado no existe';
  }

  // Not null
  if (code == '23502' || msg.contains('not null')) {
    return 'Faltan datos obligatorios';
  }

  // RLS / permissions
  if (code == '42501' || msg.contains('permission denied')) {
    return 'No tenés permiso para esta acción';
  }

  // JWT
  if (msg.contains('jwt expired') || msg.contains('jwt') && msg.contains('invalid')) {
    return 'Tu sesión expiró, ingresá de nuevo';
  }

  // Row not found (single() without result)
  if (msg.contains('rows returned') || msg.contains('no rows')) {
    return 'No se encontraron datos';
  }

  return 'Error en la base de datos. Intentá de nuevo.';
}
