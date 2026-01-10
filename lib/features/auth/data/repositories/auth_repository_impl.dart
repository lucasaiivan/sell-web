import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_profile.dart';
import '../../domain/entities/account_profile.dart';
import '../models/auth_profile_model.dart';
import '../models/account_profile_model.dart';
import '../models/admin_profile_model.dart';
import '../../domain/entities/admin_profile.dart';
import '../../../../core/services/database/firestore_paths.dart';
import '../../../../core/utils/helpers/id_generator.dart';

/// Implementación del repositorio de autenticación
///
/// Utiliza Firebase Auth y Google Sign In para gestionar la autenticación.
/// Convierte los usuarios de Firebase a entidades de dominio [AuthProfile].
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl(this._firebaseAuth, this._googleSignIn);

  @override
  Future<Either<Failure, AuthProfile>> signInWithGoogle() async {
    try {
      // Usar signInSilently primero para verificar si ya hay sesión activa
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();

      // Si no hay sesión silenciosa, intentar login interactivo
      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) {
        return Left(ServerFailure('Usuario canceló el inicio de sesión'));
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final fbUser = userCredential.user;

      if (fbUser == null) {
        return Left(ServerFailure('Error al obtener datos del usuario'));
      }

      return Right(AuthProfileModel.fromFirebaseUser(fbUser).toEntity());
    } catch (e) {
      return Left(ServerFailure(
          'Error en inicio de sesión con Google: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al cerrar sesión: ${e.toString()}'));
    }
  }

  @override
  Stream<AuthProfile?> get user =>
      _firebaseAuth.authStateChanges().map((fbUser) {
        print(
            '🔔 [AuthRepositoryImpl] authStateChanges - fbUser: ${fbUser?.email}, uid: ${fbUser?.uid}');
        if (fbUser == null) {
          print('❌ [AuthRepositoryImpl] Usuario es null');
          return null;
        }
        final authProfile =
            AuthProfileModel.fromFirebaseUser(fbUser).toEntity();
        print(
            '✅ [AuthRepositoryImpl] AuthProfile creado: ${authProfile.email}');
        return authProfile;
      });

  @override
  Future<Either<Failure, AuthProfile>> signInAnonymously() async {
    try {
      final userCredential = await _firebaseAuth.signInAnonymously();
      final fbUser = userCredential.user;

      if (fbUser == null) {
        return Left(ServerFailure('Error al crear usuario anónimo'));
      }

      return Right(AuthProfileModel.fromFirebaseUser(fbUser).toEntity());
    } catch (e) {
      return Left(
          ServerFailure('Error en inicio de sesión anónimo: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AuthProfile>> signInSilently() async {
    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signInSilently();

      if (googleUser == null) {
        return Left(ServerFailure('No hay sesión guardada'));
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final fbUser = userCredential.user;

      if (fbUser == null) {
        return Left(ServerFailure('Error al obtener datos del usuario'));
      }

      return Right(AuthProfileModel.fromFirebaseUser(fbUser).toEntity());
    } catch (e) {
      return Left(ServerFailure(
          'Error en inicio de sesión silencioso: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkUsernameExists(String username) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Consultar en collection '/ACCOUNTS' donde username == providedUsername
      final querySnapshot = await firestore
          .collection(FirestorePaths.accounts)
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      // Si hay documentos, el username ya existe
      return Right(querySnapshot.docs.isNotEmpty);
    } catch (e) {
      return Left(FirestoreFailure(
          'Error al verificar disponibilidad del username: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AccountProfile>> createBusinessAccount(
      AccountProfile account) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null || currentUser.email == null) {
        return Left(ServerFailure(
            'No hay un usuario autenticado con email para crear la cuenta'));
      }

      final email = currentUser.email!;

      // Generar ID único para la cuenta usando IdGenerator
      final accountId = IdGenerator.generateAccountId();

      // Crear AccountProfile con el ID generado
      final accountWithId = account.copyWith(
        id: accountId,
        creation: DateTime.now(),
      );

      // Convertir a Map para Firestore
      final accountModel = AccountProfileModel.fromEntity(accountWithId);
      final accountData = accountModel.toFirestore();

      // Crear el perfil de administrador (superuser)
      final adminProfile = AdminProfileModel(
        id: currentUser.uid,
        email: email,
        name: currentUser.displayName ?? '',
        account: accountId,
        superAdmin: true, // Por defecto es superuser
        admin: true,
        creation: DateTime.now(),
        lastUpdate: DateTime.now(),
        permissions: AdminPermission.values
            .map((e) => e.name)
            .toList(), // Full permissions
      );

      final adminData = adminProfile.toJson();

      // Batch para asegurar que se crea la cuenta y los accesos atómicamente
      final batch = firestore.batch();

      // 1. Guardar la cuenta en /ACCOUNTS/{id}
      batch.set(firestore.doc(FirestorePaths.account(accountId)), accountData);

      // 2. Crear identificación de acceso en /ACCOUNTS/{accountId}/USERS/{email}
      batch.set(
          firestore.doc(FirestorePaths.accountUser(accountId, email)), adminData);

      // 3. Crear identificación de acceso en /USERS/{email}/ACCOUNTS/{accountId}
      batch.set(
          firestore.doc(FirestorePaths.userManagedAccount(email, accountId)),
          adminData);

      await batch.commit();

      return Right(accountWithId);
    } catch (e) {
      return Left(FirestoreFailure('Error al crear la cuenta: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateBusinessAccount(
      AccountProfile account) async {
    try {
      final firestore = FirebaseFirestore.instance;

      if (account.id.isEmpty) {
        return Left(ValidationFailure('ID de cuenta inválido'));
      }

      // Convertir a Map para Firestore
      final accountModel = AccountProfileModel.fromEntity(account);
      final data = accountModel.toFirestore();

      // Actualizar documento en '/ACCOUNTS/{id}'
      await firestore
          .doc(FirestorePaths.account(account.id))
          .set(data, SetOptions(merge: true));

      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure(
          'Error al actualizar la cuenta: ${e.toString()}'));
    }
  }
}
