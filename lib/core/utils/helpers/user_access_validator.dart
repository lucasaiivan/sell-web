import 'package:sellweb/features/auth/domain/entities/admin_profile.dart';

/// Helper: Validador de acceso de usuario
///
/// **Responsabilidad:**
/// - Validar si un usuario tiene acceso permitido
/// - Verificar estado de bloqueo (inactivate)
/// - Verificar restricciones de horario y día de la semana
/// - Proporcionar razones claras de denegación de acceso
class UserAccessValidator {
  /// Resultado de la validación de acceso
  static UserAccessResult validateAccess(AdminProfile adminProfile) {
    // 1. Super Admin siempre tiene acceso
    if (adminProfile.superAdmin) {
      return UserAccessResult(
        hasAccess: true,
        reason: UserAccessDeniedReason.none,
      );
    }

    // 2. Usuario inactivado/bloqueado
    if (adminProfile.inactivate) {
      return UserAccessResult(
        hasAccess: false,
        reason: UserAccessDeniedReason.userBlocked,
      );
    }

    // 3. Verificar día de la semana
    if (adminProfile.daysOfWeek.isNotEmpty && !adminProfile.hasAccessDay) {
      return UserAccessResult(
        hasAccess: false,
        reason: UserAccessDeniedReason.dayNotAllowed,
      );
    }

    // 4. Verificar horario de acceso
    if (adminProfile.hasAccessTimeConfiguration && !adminProfile.hasAccessHour) {
      return UserAccessResult(
        hasAccess: false,
        reason: UserAccessDeniedReason.outsideAllowedHours,
      );
    }

    // Usuario tiene acceso
    return UserAccessResult(
      hasAccess: true,
      reason: UserAccessDeniedReason.none,
    );
  }
}

/// Razones de denegación de acceso
enum UserAccessDeniedReason {
  /// Sin restricciones, acceso permitido
  none,
  
  /// Usuario bloqueado por administrador
  userBlocked,
  
  /// Día de la semana no permitido
  dayNotAllowed,
  
  /// Fuera del horario permitido
  outsideAllowedHours,
}

/// Resultado de validación de acceso
class UserAccessResult {
  /// Indica si el usuario tiene acceso
  final bool hasAccess;
  
  /// Razón de denegación (si aplica)
  final UserAccessDeniedReason reason;

  const UserAccessResult({
    required this.hasAccess,
    required this.reason,
  });

  /// Obtiene mensaje legible de la razón de denegación
  String get message {
    switch (reason) {
      case UserAccessDeniedReason.none:
        return '';
      case UserAccessDeniedReason.userBlocked:
        return 'Tu cuenta ha sido bloqueada por el administrador';
      case UserAccessDeniedReason.dayNotAllowed:
        return 'No tienes acceso en este día de la semana';
      case UserAccessDeniedReason.outsideAllowedHours:
        return 'Fuera del horario de acceso permitido';
    }
  }

  /// Obtiene título del mensaje de error
  String get title {
    switch (reason) {
      case UserAccessDeniedReason.none:
        return '';
      case UserAccessDeniedReason.userBlocked:
        return 'Acceso Bloqueado';
      case UserAccessDeniedReason.dayNotAllowed:
        return 'Acceso Restringido';
      case UserAccessDeniedReason.outsideAllowedHours:
        return 'Horario No Permitido';
    }
  }

  /// Obtiene icono apropiado para el tipo de restricción
  String get icon {
    switch (reason) {
      case UserAccessDeniedReason.none:
        return '';
      case UserAccessDeniedReason.userBlocked:
        return '🚫';
      case UserAccessDeniedReason.dayNotAllowed:
        return '📅';
      case UserAccessDeniedReason.outsideAllowedHours:
        return '🕒';
    }
  }
}
