/// Entidad de dominio: Perfil de usuario autenticado
///
/// Representa el perfil básico de un usuario autenticado en el sistema.
/// Esta es una entidad pura de dominio sin dependencias externas.
///
/// **Propiedades:**
/// - `uid`: ID único del usuario
/// - `email`: Correo electrónico del usuario
/// - `displayName`: Nombre para mostrar del usuario
/// - `isAnonymous`: Indica si el usuario está autenticado como invitado
/// - `photoUrl`: URL de la foto de perfil del usuario
class AuthProfile {
  final String? uid;
  final String? email;
  final String? displayName;
  final bool? isAnonymous;
  final String? photoUrl;

  const AuthProfile({
    this.uid,
    this.email,
    this.displayName,
    this.isAnonymous,
    this.photoUrl,
  });

  /// Copia la entidad con los valores proporcionados
  AuthProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isAnonymous,
    String? photoUrl,
  }) {
    return AuthProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthProfile &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          isAnonymous == other.isAnonymous &&
          photoUrl == other.photoUrl;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      isAnonymous.hashCode ^
      photoUrl.hashCode;

  @override
  String toString() {
    return 'AuthProfile(uid: $uid, email: $email, displayName: $displayName, isAnonymous: $isAnonymous, photoUrl: $photoUrl)';
  }
}
