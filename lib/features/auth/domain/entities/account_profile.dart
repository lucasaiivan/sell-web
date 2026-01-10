/// Entidad de dominio: Perfil de cuenta comercial
///
/// Representa la cuenta de un comercio/negocio con su configuración.
/// Esta es una entidad pura de dominio sin dependencias externas (solo Dart).
///
/// **Propiedades principales:**
/// - `id`: ID único de la cuenta
/// - `name`: Nombre del negocio
/// - `image`: URL de la imagen de perfil
/// - `currencySign`: Símbolo de moneda (\$, €, etc.)
/// - `pin`: PIN de seguridad
///
/// **Estado de la cuenta:**
/// - `blockingAccount`: Indica si la cuenta está bloqueada
/// - `blockingMessage`: Mensaje de bloqueo
/// - `verifiedAccount`: Indica si la cuenta está verificada
/// - `trial`: Indica si está en periodo de prueba
/// - `trialStart`: Fecha de inicio del periodo de prueba
/// - `trialEnd`: Fecha de fin del periodo de prueba
///
/// **Ubicación:**
/// - `countrycode`: Código de país
/// - `country`: País
/// - `province`: Provincia/Estado
/// - `town`: Ciudad
class AccountProfile {
  final String id;
  final String image;
  final String name;
  final String currencySign;
  final bool blockingAccount;
  final String blockingMessage;
  final bool verifiedAccount;
  final String pin;
  final bool trial;
  final DateTime trialStart;
  final DateTime trialEnd;
  final String countrycode;
  final String country;
  final String province;
  final String town;
  final DateTime creation;
  final String ownerId; // ID del administrador propietario de la cuenta

  const AccountProfile({
    this.id = "",
    this.image = "",
    this.name = "",
    this.currencySign = "\$",
    this.blockingAccount = false,
    this.blockingMessage = "",
    this.verifiedAccount = false,
    this.pin = '',
    this.trial = false,
    required this.trialStart,
    required this.trialEnd,
    this.countrycode = "",
    this.country = "",
    this.province = "",
    this.town = "",
    required this.creation,
    this.ownerId = "",
  });

  /// Copia la entidad con los valores proporcionados
  AccountProfile copyWith({
    String? id,
    String? image,
    String? name,
    String? currencySign,
    bool? blockingAccount,
    String? blockingMessage,
    bool? verifiedAccount,
    String? pin,
    bool? trial,
    DateTime? trialStart,
    DateTime? trialEnd,
    String? countrycode,
    String? country,
    String? province,
    String? town,
    DateTime? creation,
    String? ownerId,
  }) {
    return AccountProfile(
      id: id ?? this.id,
      image: image ?? this.image,
      name: name ?? this.name,
      currencySign: currencySign ?? this.currencySign,
      blockingAccount: blockingAccount ?? this.blockingAccount,
      blockingMessage: blockingMessage ?? this.blockingMessage,
      verifiedAccount: verifiedAccount ?? this.verifiedAccount,
      pin: pin ?? this.pin,
      trial: trial ?? this.trial,
      trialStart: trialStart ?? this.trialStart,
      trialEnd: trialEnd ?? this.trialEnd,
      countrycode: countrycode ?? this.countrycode,
      country: country ?? this.country,
      province: province ?? this.province,
      town: town ?? this.town,
      creation: creation ?? this.creation,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  /// Crea una instancia vacía de AccountProfile
  factory AccountProfile.empty() {
    return AccountProfile(
      trialStart: DateTime.now(),
      trialEnd: DateTime.now(),
      creation: DateTime.now(),
    );
  }

  /// Verifica si la cuenta está activa (no bloqueada y no expirada)
  bool get isActive {
    if (blockingAccount) return false;
    if (trial && DateTime.now().isAfter(trialEnd)) return false;
    return true;
  }

  /// Verifica si el periodo de prueba está activo
  bool get isTrialActive {
    if (!trial) return false;
    final now = DateTime.now();
    return now.isAfter(trialStart) && now.isBefore(trialEnd);
  }

  /// Obtiene los días restantes del periodo de prueba
  int get trialDaysRemaining {
    if (!trial || !isTrialActive) return 0;
    return trialEnd.difference(DateTime.now()).inDays;
  }

  /// Obtiene la ubicación completa formateada
  String get fullLocation {
    final parts = <String>[];
    if (town.isNotEmpty) parts.add(town);
    if (province.isNotEmpty) parts.add(province);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  /// Verifica si el administrador proporcionado es el propietario de esta cuenta
  ///
  /// **Parámetros:**
  /// - `adminId`: ID del administrador a verificar
  ///
  /// **Retorna:** `true` si el adminId coincide con el ownerId dela cuenta
  bool isOwner(String adminId) => ownerId == adminId && adminId.isNotEmpty;


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          blockingAccount == other.blockingAccount &&
          verifiedAccount == other.verifiedAccount;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      blockingAccount.hashCode ^
      verifiedAccount.hashCode;

  @override
  String toString() {
    return 'AccountProfile(id: $id, name: $name, verified: $verifiedAccount, blocked: $blockingAccount)';
  }
}
