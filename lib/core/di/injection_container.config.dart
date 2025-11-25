// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:sellweb/core/di/injection_container.dart' as _i220;
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart'
    as _i581;
import 'package:sellweb/data/catalogue_repository_impl.dart' as _i187;
import 'package:sellweb/domain/repositories/catalogue_repository.dart' as _i534;
import 'package:sellweb/domain/usecases/catalogue_usecases.dart' as _i758;
import 'package:sellweb/features/auth/data/repositories/account_repository_impl.dart'
    as _i166;
import 'package:sellweb/features/auth/data/repositories/auth_repository_impl.dart'
    as _i566;
import 'package:sellweb/features/auth/domain/repositories/account_repository.dart'
    as _i840;
import 'package:sellweb/features/auth/domain/repositories/auth_repository.dart'
    as _i348;
import 'package:sellweb/features/auth/domain/usecases/get_user_accounts_usecase.dart'
    as _i644;
import 'package:sellweb/features/auth/domain/usecases/get_user_stream_usecase.dart'
    as _i557;
import 'package:sellweb/features/auth/domain/usecases/sign_in_anonymously_usecase.dart'
    as _i380;
import 'package:sellweb/features/auth/domain/usecases/sign_in_silently_usecase.dart'
    as _i1046;
import 'package:sellweb/features/auth/domain/usecases/sign_in_with_google_usecase.dart'
    as _i253;
import 'package:sellweb/features/auth/domain/usecases/sign_out_usecase.dart'
    as _i158;
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart'
    as _i638;
import 'package:sellweb/features/catalogue/data/datasources/catalogue_remote_datasource.dart'
    as _i983;
import 'package:sellweb/features/catalogue/data/repositories/catalogue_repository_impl.dart'
    as _i576;
import 'package:sellweb/features/catalogue/domain/repositories/catalogue_repository.dart'
    as _i83;
import 'package:sellweb/features/catalogue/domain/usecases/get_products_usecase.dart'
    as _i453;
import 'package:sellweb/features/catalogue/domain/usecases/update_stock_usecase.dart'
    as _i226;
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart'
    as _i127;
import 'package:sellweb/features/sales/domain/usecases/sell_usecases.dart'
    as _i76;
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart'
    as _i454;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final externalModule = _$ExternalModule();
    gh.lazySingleton<_i974.FirebaseFirestore>(() => externalModule.firestore);
    gh.lazySingleton<_i581.AppDataPersistenceService>(
        () => externalModule.appDataPersistenceService);
    gh.lazySingleton<_i59.FirebaseAuth>(() => externalModule.firebaseAuth);
    gh.lazySingleton<_i116.GoogleSignIn>(() => externalModule.googleSignIn);
    gh.lazySingleton<_i76.SellUsecases>(() => _i76.SellUsecases(
        persistenceService: gh<_i581.AppDataPersistenceService>()));
    gh.lazySingleton<_i983.CatalogueRemoteDataSource>(() =>
        _i983.CatalogueRemoteDataSourceImpl(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i83.CatalogueRepository>(() =>
        _i576.CatalogueRepositoryImpl(gh<_i983.CatalogueRemoteDataSource>()));
    gh.lazySingleton<_i534.CatalogueRepository>(
        () => _i187.CatalogueRepositoryImpl(id: gh<String>()));
    gh.lazySingleton<_i840.AccountRepository>(() => _i166.AccountRepositoryImpl(
        persistenceService: gh<_i581.AppDataPersistenceService>()));
    gh.lazySingleton<_i226.UpdateStockUseCase>(
        () => _i226.UpdateStockUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i453.GetProductsUseCase>(
        () => _i453.GetProductsUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i348.AuthRepository>(() => _i566.AuthRepositoryImpl(
          gh<_i59.FirebaseAuth>(),
          gh<_i116.GoogleSignIn>(),
        ));
    gh.lazySingleton<_i758.CatalogueUseCases>(
        () => _i758.CatalogueUseCases(gh<_i534.CatalogueRepository>()));
    gh.factory<_i127.CatalogueProvider>(() => _i127.CatalogueProvider(
        catalogueUseCases: gh<_i758.CatalogueUseCases>()));
    gh.lazySingleton<_i644.GetUserAccountsUseCase>(
        () => _i644.GetUserAccountsUseCase(
              gh<_i840.AccountRepository>(),
              persistenceService: gh<_i581.AppDataPersistenceService>(),
            ));
    gh.factory<_i454.SalesProvider>(() => _i454.SalesProvider(
          getUserAccountsUseCase: gh<_i644.GetUserAccountsUseCase>(),
          sellUsecases: gh<_i76.SellUsecases>(),
          catalogueUseCases: gh<_i758.CatalogueUseCases>(),
        ));
    gh.lazySingleton<_i557.GetUserStreamUseCase>(
        () => _i557.GetUserStreamUseCase(gh<_i348.AuthRepository>()));
    gh.lazySingleton<_i1046.SignInSilentlyUseCase>(
        () => _i1046.SignInSilentlyUseCase(gh<_i348.AuthRepository>()));
    gh.lazySingleton<_i253.SignInWithGoogleUseCase>(
        () => _i253.SignInWithGoogleUseCase(gh<_i348.AuthRepository>()));
    gh.lazySingleton<_i380.SignInAnonymouslyUseCase>(
        () => _i380.SignInAnonymouslyUseCase(gh<_i348.AuthRepository>()));
    gh.lazySingleton<_i158.SignOutUseCase>(
        () => _i158.SignOutUseCase(gh<_i348.AuthRepository>()));
    gh.factory<_i638.AuthProvider>(() => _i638.AuthProvider(
          gh<_i253.SignInWithGoogleUseCase>(),
          gh<_i1046.SignInSilentlyUseCase>(),
          gh<_i380.SignInAnonymouslyUseCase>(),
          gh<_i158.SignOutUseCase>(),
          gh<_i557.GetUserStreamUseCase>(),
          gh<_i644.GetUserAccountsUseCase>(),
        ));
    return this;
  }
}

class _$ExternalModule extends _i220.ExternalModule {}
