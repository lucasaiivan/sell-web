/// Mensajes reutilizables para modo demo
///
/// Centraliza todos los textos mostrados en modo demo para
/// mantener consistencia en la comunicación con el usuario
class DemoMessages {
  DemoMessages._();

  // ==================== Banner Messages ====================
  
  /// Título del banner de modo demostración
  static const String bannerTitle = 'Modo Demostración';

  /// Subtítulo del banner
  static const String bannerSubtitle = 'Explora sin límites • Los datos no se guardan';

  /// Texto del botón de registro en banner
  static const String bannerCtaText = 'Registrarse Gratis';

  // ==================== Feature Restrictions ====================

  /// Mensajes específicos para cada funcionalidad restringida
  static const Map<String, String> featureRestrictions = {
    'cash_register': 'La gestión de caja requiere una cuenta registrada para mantener un control seguro de tu dinero.',
    'user_management': 'La administración de usuarios requiere una cuenta para proteger la información de tu equipo.',
    'data_persistence': 'Los datos solo se guardan permanentemente con una cuenta registrada.',
    'analytics': 'Los reportes y analíticas completas están disponibles solo para usuarios registrados.',
    'account_settings': 'La configuración de la cuenta requiere autenticación para proteger tu información.',
  };

  /// Obtiene el mensaje de restricción para una funcionalidad
  ///
  /// [feature]: Identificador de la funcionalidad
  /// Retorna el mensaje específico o uno genérico si no existe
  static String getRestrictionMessage(String feature) {
    return featureRestrictions[feature] ??
        'Esta función requiere una cuenta registrada para garantizar la seguridad de tus datos.';
  }

  // ==================== Registration Benefits ====================

  /// Lista de beneficios de registrarse
  static List<String> get registrationBenefits => [
        'Datos guardados permanentemente',
        'Sincronización automática en la nube',
        'Gestión completa de usuarios y permisos',
        'Reportes y analíticas avanzadas',
        'Soporte prioritario',
      ];

  // ==================== Dialog Messages ====================

  /// Título del diálogo de restricción
  static const String restrictionDialogTitle = 'Función Bloqueada';

  /// Subtítulo para diálogos de restricción
  static const String restrictionDialogSubtitle = 'Regístrate para desbloquear todas las funcionalidades';

  /// Texto del botón continuar en demo
  static const String continueInDemoButton = 'Continuar en Demo';

  /// Texto del botón de registro
  static const String registerButton = 'Registrarse Gratis';

  // ==================== Tooltips ====================

  /// Tooltip para ventas en modo demo
  static const String salesTooltip = 'Las ventas se simulan pero no se guardan permanentemente';

  /// Tooltip para catálogo en modo demo
  static const String catalogueTooltip = 'Puedes explorar y crear productos de prueba';

  /// Tooltip para analíticas en modo demo
  static const String analyticsTooltip = 'Vista previa de reportes. Regístrate para ver datos reales';

  /// Tooltip para usuarios en modo demo
  static const String usersTooltip = 'La gestión de usuarios requiere una cuenta registrada';

  // ==================== Snackbar Messages ====================

  /// Mensaje cuando se intenta una acción bloqueada
  static String actionBlockedMessage(String action) =>
      '$action requiere una cuenta. ¡Regístrate gratis!';

  /// Mensaje de información general
  static const String infoMessage = 'Estás en modo demostración. Los cambios no se guardarán.';
}
