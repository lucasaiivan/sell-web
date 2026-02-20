import '../../domain/entities/auth_profile.dart';

/// Modelo de datos: Perfil de usuario autenticado
///
/// Extiende [AuthProfile] agregando lógica de conversión desde Firebase Auth.
/// Esta clase pertenece a la capa de datos y maneja la serialización.
///
/// **Responsabilidad:**
/// - Convertir datos de Firebase Auth a entidad de dominio
/// - No contiene lógica de negocio
///
/// **Uso:**
/// ```dart
/// final firebaseUser = FirebaseAuth.instance.currentUser;
/// final authProfile = AuthProfileModel.fromFirebaseUser(firebaseUser);
/// ```
class AuthProfileModel extends AuthProfile {
  const AuthProfileModel({
    super.uid,
    super.email,
    super.displayName,
    super.isAnonymous,
    super.photoUrl,
  });

  /// Crea AuthProfileModel desde un usuario de Firebase Auth
  ///
  /// Acepta user dinámico para evitar dependencia directa de Firebase en firma
  factory AuthProfileModel.fromFirebaseUser(dynamic user) {
    if (user == null) {
      return const AuthProfileModel();
    }

    return AuthProfileModel(
      uid: user.uid as String?,
      email: user.email as String?,
      displayName: user.displayName as String?,
      isAnonymous: user.isAnonymous as bool?,
      photoUrl: user.photoURL as String?,
    );
  }

  /// Convierte a Map para JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isAnonymous': isAnonymous,
      'photoUrl': photoUrl,
    };
  }

  /// Crea AuthProfileModel desde Map
  factory AuthProfileModel.fromJson(Map<String, dynamic> json) {
    return AuthProfileModel(
      uid: json['uid'] as String?,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      isAnonymous: json['isAnonymous'] as bool?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  /// Convierte el modelo a entidad pura de dominio
  AuthProfile toEntity() {
    return AuthProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      isAnonymous: isAnonymous,
      photoUrl: photoUrl,
    );
  }

  /// Crea modelo desde entidad
  factory AuthProfileModel.fromEntity(AuthProfile entity) {
    return AuthProfileModel(
      uid: entity.uid,
      email: entity.email,
      displayName: entity.displayName,
      isAnonymous: entity.isAnonymous,
      photoUrl: entity.photoUrl,
    );
  }

  @override
  AuthProfileModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isAnonymous,
    String? photoUrl,
  }) {
    return AuthProfileModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
