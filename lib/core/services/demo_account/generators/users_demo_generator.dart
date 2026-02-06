import 'package:sellweb/core/services/demo_account/data/demo_config.dart';
import 'package:sellweb/features/auth/domain/entities/admin_profile.dart';
import 'package:sellweb/features/auth/domain/entities/account_profile.dart';

/// Generador de datos demo para usuarios y cuentas
///
/// **Responsabilidad:**
/// - Generar usuarios administradores demo con diferentes roles
/// - Generar cuenta demo (AccountProfile)
/// - Generar perfil admin demo para sesión de invitado
/// - Mantener coherencia de permisos y configuración
class UsersDemoGenerator {
  UsersDemoGenerator._();

  // ==========================================
  // USUARIOS ADMINISTRADORES
  // ==========================================

  /// Genera lista de usuarios demo específicos para modo invitado
  ///
  /// **Retorna:** Lista de 2 usuarios (1 superusuario + 1 empleado)
  static List<AdminProfile> generateDemoAdminUsers() {
    final now = DateTime.now();

    return [
      // 1. Superusuario - Admin completo con todos los permisos
      AdminProfile(
        id: 'demo_user_superadmin',
        email: 'superusuario@demo.com',
        name: 'Superusuario',
        account: kDemoAccountId,
        admin: true,
        superAdmin: true,
        personalized: false,
        creation: now.subtract(const Duration(days: 365)),
        lastUpdate: now,
        permissions: AdminPermission.values.map((e) => e.name).toList(),
        inactivate: false,
      ),

      // 2. Empleado - Cajero con permisos limitados
      AdminProfile(
        id: 'demo_user_empleado',
        email: 'empleado@demo.com',
        name: 'Empleado',
        account: kDemoAccountId,
        admin: false,
        superAdmin: false,
        personalized: true,
        creation: now.subtract(const Duration(days: 90)),
        lastUpdate: now,
        permissions: [
          AdminPermission.createCashCount.name,
          AdminPermission.viewCashCountHistory.name,
        ],
        inactivate: false,
        // Horario: 8am - 6pm
        startTime: {'hour': 8, 'minute': 0},
        endTime: {'hour': 18, 'minute': 0},
        daysOfWeek: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
      ),
    ];
  }

  // ==========================================
  // CUENTA DEMO
  // ==========================================

  /// Genera AccountProfile demo para modo invitado
  ///
  /// **Retorna:** AccountProfile con datos del negocio demo
  static AccountProfile generateDemoAccount() {
    final now = DateTime.now();
    
    return AccountProfile(
      id: kDemoAccountId,
      name: kDemoAccountName,
      country: kDemoAccountCountry,
      province: kDemoAccountProvince,
      town: kDemoAccountCity,
      image: 'https://cdn-icons-png.flaticon.com/512/869/869636.png',
      currencySign: kDemoCurrencySymbol,
      creation: now,
      trialStart: now,
      trialEnd: now.add(Duration(days: kDemoTrialDuration)),
    );
  }

  // ==========================================
  // PERFIL ADMIN DEMO (SESIÓN INVITADO)
  // ==========================================

  /// Genera AdminProfile demo para la sesión de invitado actual
  ///
  /// Este perfil se usa cuando un usuario entra como invitado.
  /// Tiene todos los permisos habilitados para permitir exploración completa.
  ///
  /// **Retorna:** AdminProfile con todos los permisos
  static AdminProfile generateDemoAdminProfile() {
    final now = DateTime.now();
    
    return AdminProfile(
      email: 'invitado@demo.com',
      account: kDemoAccountId,
      admin: true,
      superAdmin: true,
      personalized: true,
      creation: now,
      lastUpdate: now,
      permissions: AdminPermission.values.map((e) => e.name).toList(),
      inactivate: false,
    );
  }
}
