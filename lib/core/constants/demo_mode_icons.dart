import 'package:flutter/material.dart';

/// Constantes de iconografía para modo demo
/// 
/// Proporciona un sistema consistente de iconos para indicar
/// el estado de las funcionalidades en modo demo/invitado
class DemoModeIcons {
  DemoModeIcons._();

  /// Icono para funcionalidades bloqueadas que requieren autenticación
  static const IconData locked = Icons.lock_outline;

  /// Icono para funcionalidades en modo vista previa solamente
  static const IconData preview = Icons.visibility_outlined;

  /// Icono para indicar que los datos no se guardarán
  static const IconData noSave = Icons.save_outlined;

  /// Icono para funcionalidades disponibles en modo demo
  static const IconData available = Icons.check_circle_outline;

  /// Icono para información contextual
  static const IconData info = Icons.info_outline;

  /// Icono identificador del modo demostración
  static const IconData demo = Icons.auto_fix_high;

  /// Icono para llamadas a acción de registro
  static const IconData register = Icons.login_rounded;
}

/// Colores consistentes para modo demo
class DemoModeColors {
  DemoModeColors._();

  /// Color de advertencia (amber/warning)
  static const Color warning = Color(0xFFF59E0B); // Amber 600

  /// Color informativo (blue)
  static const Color info = Color(0xFF3B82F6); // Blue 500

  /// Color de éxito (green)
  static const Color success = Color(0xFF10B981); // Green 500

  /// Color de restricción (amber más oscuro)
  static const Color restriction = Color(0xFFD97706); // Amber 700
}
