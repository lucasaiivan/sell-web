import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/admin_profile.dart';
import '../../domain/entities/account_profile.dart';
import '../../domain/repositories/account_repository.dart';
import '../models/admin_profile_model.dart';
import '../models/account_profile_model.dart';
import '../../../../core/services/storage/app_data_persistence_service.dart';

/// Implementación del repositorio de cuentas
///
/// Utiliza Firestore para obtener datos de cuentas y administradores.
/// Utiliza [AppDataPersistenceService] para persistencia local.
@LazySingleton(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  final AppDataPersistenceService _persistenceService;

  AccountRepositoryImpl({
    AppDataPersistenceService? persistenceService,
  }) : _persistenceService =
            persistenceService ?? AppDataPersistenceService.instance;

  @override
  Future<List<AdminProfile>> getUserAccounts(String email) async {
    print('🔍 [AccountRepositoryImpl] getUserAccounts - email: $email');
    try {
      final ref =
          FirebaseFirestore.instance.collection('/USERS/$email/ACCOUNTS/');
      print('📡 [AccountRepositoryImpl] Consultando Firestore: ${ref.path}');
      final snapshot = await ref.get();
      print('📊 [AccountRepositoryImpl] Documentos encontrados: ${snapshot.docs.length}');
      final adminProfiles = snapshot.docs
          .map((doc) {
            print('   - Doc ID: ${doc.id}, Data: ${doc.data()}');
            return AdminProfileModel.fromDocument(doc);
          })
          .toList();
      print('✅ [AccountRepositoryImpl] AdminProfiles parseados: ${adminProfiles.length}');
      return adminProfiles;
    } catch (e, stackTrace) {
      print('❌ [AccountRepositoryImpl] Error en getUserAccounts: $e');
      print('Stack trace: $stackTrace');
      // Si falla (ej: permisos), retornar lista vacía
      return [];
    }
  }

  @override
  Future<AccountProfile?> getAccount(String accountId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('/ACCOUNTS')
          .doc(accountId)
          .get();
      
      if (!doc.exists) return null;
      return AccountProfileModel.fromDocument(doc);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveSelectedAccountId(String accountId) async {
    await _persistenceService.saveSelectedAccountId(accountId);
  }

  @override
  Future<String?> getSelectedAccountId() async {
    return await _persistenceService.getSelectedAccountId();
  }

  @override
  Future<void> removeSelectedAccountId() async {
    await _persistenceService.clearSelectedAccountId();
  }
}
