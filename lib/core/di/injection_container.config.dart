// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:sellweb/core/di/injection_container.dart' as _i220;
import 'package:sellweb/domain/usecases/account_usecase.dart' as _i910;
import 'package:sellweb/domain/usecases/catalogue_usecases.dart' as _i758;
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
    gh.factory<_i127.CatalogueProvider>(() => _i127.CatalogueProvider(
          catalogueUseCases: gh<_i758.CatalogueUseCases>(),
          getUserAccountsUseCase: gh<_i910.AccountsUseCase>(),
        ));
    gh.lazySingleton<_i983.CatalogueRemoteDataSource>(() =>
        _i983.CatalogueRemoteDataSourceImpl(gh<_i974.FirebaseFirestore>()));
    gh.lazySingleton<_i83.CatalogueRepository>(() =>
        _i576.CatalogueRepositoryImpl(gh<_i983.CatalogueRemoteDataSource>()));
    gh.lazySingleton<_i226.UpdateStockUseCase>(
        () => _i226.UpdateStockUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i453.GetProductsUseCase>(
        () => _i453.GetProductsUseCase(gh<_i83.CatalogueRepository>()));
    return this;
  }
}

class _$ExternalModule extends _i220.ExternalModule {}
