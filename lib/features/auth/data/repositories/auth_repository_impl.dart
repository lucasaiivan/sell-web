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
import '../../../../core/services/storage/i_storage_datasource.dart';
import '../../../../core/utils/helpers/id_generator.dart';

/// Implementación del repositorio de autenticación
///
/// Utiliza Firebase Auth y Google Sign In para gestionar la autenticación.
/// Convierte los usuarios de Firebase a entidades de dominio [AuthProfile].
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final IStorageDataSource _storageDataSource;

  AuthRepositoryImpl(
    this._firebaseAuth,
    this._googleSignIn,
    this._storageDataSource,
  );

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
  @override
  Future<Either<Failure, void>> deleteBusinessAccount(String accountId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Obtener la referencia de la cuenta
      final accountRef = firestore.doc(FirestorePaths.account(accountId));
      final accountDoc = await accountRef.get();

      if (!accountDoc.exists) {
        return Left(FirestoreFailure('La cuenta no existe'));
      }

      // 2. Limpiar referencias en usuarios (Admins)
      // Obtenemos los usuarios que tienen acceso a esta cuenta
      final accountUsersRef =
          firestore.collection(FirestorePaths.accountUsers(accountId));
      final accountUsersSnapshot = await accountUsersRef.get();

      final batch = firestore.batch();
      bool batchHasOps = false;

      for (final doc in accountUsersSnapshot.docs) {
        final email = doc.id; // El ID es el email
        // Referencia a la cuenta en el perfil del usuario
        final userAccountRef = firestore.doc(
            FirestorePaths.userManagedAccount(email, accountId));
        batch.delete(userAccountRef);
        batchHasOps = true;
      }

      if (batchHasOps) {
        await batch.commit();
      }

      // 3. Eliminar subcolecciones (Recursive delete client-side simulator)
      // Lista explícita de subcolecciones conocidas según FirestorePaths
      final subcollections = [
        'CATALOGUE',
        'CATEGORY',
        'PROVIDER',
        'TRANSACTIONS',
        'USERS',
        'CASHREGISTERS',
        'RECORDS',
        'FIXERDESCRIPTIONS',
        'SETTINGS',
      ];

      for (final subcollection in subcollections) {
        final collectionDir = accountRef.collection(subcollection);
        await _deleteCollection(collectionDir);
      }

      // 4. Eliminar TODAS las imágenes en Storage asociadas a esta cuenta
      try {
        // A. Eliminar toda la carpeta de la cuenta en Storage (incluye productos, perfil, etc.)
        // Esto eliminará recursivamente:
        // - ACCOUNTS/{accountId}/PRODUCTS/* (todas las imágenes de productos)
        // - ACCOUNTS/{accountId}/PROFILE/* (imagen de perfil)
        // - ACCOUNTS/{accountId}/BRANDS/* (si existen imágenes de marcas personalizadas)
        final accountStoragePath = 'ACCOUNTS/$accountId';
        await _storageDataSource.deleteFolder(accountStoragePath);
        print('✅ Imágenes de la cuenta eliminadas: $accountStoragePath');
      } catch (e) {
        // Si falla la eliminación de Storage, logueamos pero continuamos
        // No queremos que un error en Storage bloquee la eliminación de la cuenta
        print('⚠️ Error eliminando imágenes de Storage: $e');
      }

      // 5. Eliminar el documento de la cuenta
      await accountRef.delete();

      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure(
          'Error al eliminar cuenta de negocio: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUserAccount() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null || currentUser.email == null) {
        return Left(ServerFailure('No hay usuario autenticado'));
      }

      final email = currentUser.email!;

      // 1. Obtener todas las cuentas gestionadas por el usuario
      // IMPORTANTE: Solo debemos eliminar las que son PROPIEDAD del usuario.
      // Sin embargo, la estructura actual no distingue claramente propiedad vs administración en el path
      // Asumiremos que si está en 'ACCOUNTS' del usuario, debemos procesarla.
      // Pero si es solo admin, ¿deberíamos borrar la cuenta del negocio?
      // El requerimiento dice: "1-eliminar cuenta, 2-eliminar cuentas (cuenta de su propiedad creado por ese usuario auteticado)"
      // Para seguridad, verificaremos si el usuario es SuperAdmin de la cuenta antes de borrarla.
      
      final userAccountsRef =
          firestore.collection(FirestorePaths.userManagedAccounts(email));
      final userAccountsSnapshot = await userAccountsRef.get();

      for (final doc in userAccountsSnapshot.docs) {
        final accountId = doc.id;
        final accountData = doc.data();
        
        // Verificar si es superAdmin o propietario para decidir si borrar el negocio completo
        // Si es solo 'admin', solo quitamos la referencia (que el paso 3 y el delete de Auth harian implicitamente
        // al no poder acceder más). Pero para limpieza completa:
        
        final isSuperAdmin = accountData['superAdmin'] == true;
        
        if (isSuperAdmin) {
           // Si es dueño, borramos el negocio
           final result = await deleteBusinessAccount(accountId);
           result.fold(
             (failure) => print('Error borrando cuenta $accountId: $failure'),
             (_) => print('Cuenta $accountId eliminada correctamente'),
           );
        } else {
          // Si no es dueño, solo removemos la referencia de SU perfil
          await doc.reference.delete();
          
          // Y removemos su usuario de la lista de usuarios de la cuenta
           await firestore
              .doc(FirestorePaths.accountUser(accountId, email))
              .delete();
        }
      }

      // 2. Eliminar documento de usuario
      await firestore.doc(FirestorePaths.user(email)).delete();

      // 3. Eliminar usuario de Firebase Auth
      // Requerimos borrarlo al final
      await currentUser.delete();

      return const Right(null);
    } catch (e) {
      if (e is fb_auth.FirebaseAuthException && e.code == 'requires-recent-login') {
         return Left(ServerFailure('Por seguridad, debes iniciar sesión nuevamente para eliminar tu cuenta.'));
      }
      return Left(ServerFailure('Error al eliminar usuario: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveBusinessAccount(
      String accountId, String email) async {
    try {
      final firestore = FirebaseFirestore.instance;

      final batch = firestore.batch();

      // 1. Referencia a la cuenta en el perfil del usuario
      final userAccountRef =
          firestore.doc(FirestorePaths.userManagedAccount(email, accountId));
      batch.delete(userAccountRef);

      // 2. Referencia al usuario en la lista de usuarios de la cuenta
      final accountUserRef =
          firestore.doc(FirestorePaths.accountUser(accountId, email));
      batch.delete(accountUserRef);

      await batch.commit();

      return const Right(null);
    } catch (e) {
      return Left(
          FirestoreFailure('Error al salir de la cuenta: ${e.toString()}'));
    }
  }

  /// Helper para eliminar colecciones grandes por lotes
  Future<void> _deleteCollection(Query collectionRef) async {
    // Implementación recursiva por lotes
    final limit = 500;
    final snapshot = await collectionRef.limit(limit).get();

    if (snapshot.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
      
      // NOTA: Si las subcolecciones tuvieran subcolecciones propias (nivel 3),
      // necesitaríamos recursividad aquí.
      // Según el análisis, la estructura es mayormente plana (Nivel 2), 
      // excepto casos puntuales que trataremos si existen.
      // Para una solución genérica robusta, deberíamos listar subcolecciones de cada doc.
      // Pero Firestore no permite listar subcolecciones de un doc en Web/Client SDK fácilmente
      // sin conocer sus nombres.
      // Asumimos estructura conocida.
    }
    
    await batch.commit();

    // Si borramos el límite, reintentamos (hay más docs)
    if (snapshot.size >= limit) {
      await _deleteCollection(collectionRef);
    }
  }
}
