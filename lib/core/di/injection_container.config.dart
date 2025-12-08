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
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:sellweb/core/di/injection_container.dart' as _i220;
import 'package:sellweb/core/presentation/providers/account_scope_provider.dart'
    as _i185;
import 'package:sellweb/core/presentation/providers/theme_provider.dart'
    as _i984;
import 'package:sellweb/core/services/database/firestore_datasource.dart'
    as _i485;
import 'package:sellweb/core/services/database/i_firestore_datasource.dart'
    as _i562;
import 'package:sellweb/core/services/external/thermal_printer_http_service.dart'
    as _i897;
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart'
    as _i581;
import 'package:sellweb/core/services/storage/i_storage_datasource.dart'
    as _i283;
import 'package:sellweb/core/services/storage/storage_datasource.dart' as _i390;
import 'package:sellweb/core/services/theme/theme_service.dart' as _i750;
import 'package:sellweb/core/USAGE_EXAMPLES.dart' as _i1071;
import 'package:sellweb/features/analytics/data/datasources/analytics_preferences_remote_datasource.dart'
    as _i716;
import 'package:sellweb/features/analytics/data/datasources/analytics_remote_datasource.dart'
    as _i577;
import 'package:sellweb/features/analytics/data/repositories/analytics_repository_impl.dart'
    as _i164;
import 'package:sellweb/features/analytics/data/services/analytics_preferences_service.dart'
    as _i956;
import 'package:sellweb/features/analytics/data/services/trend_calculator_service.dart'
    as _i1012;
import 'package:sellweb/features/analytics/domain/repositories/analytics_repository.dart'
    as _i732;
import 'package:sellweb/features/analytics/domain/usecases/get_sales_analytics_usecase.dart'
    as _i161;
import 'package:sellweb/features/analytics/presentation/providers/analytics_provider.dart'
    as _i975;
import 'package:sellweb/features/auth/data/repositories/account_repository_impl.dart'
    as _i166;
import 'package:sellweb/features/auth/data/repositories/auth_repository_impl.dart'
    as _i566;
import 'package:sellweb/features/auth/domain/repositories/account_repository.dart'
    as _i840;
import 'package:sellweb/features/auth/domain/repositories/auth_repository.dart'
    as _i348;
import 'package:sellweb/features/auth/domain/usecases/add_demo_account_if_anonymous_usecase.dart'
    as _i823;
import 'package:sellweb/features/auth/domain/usecases/clear_admin_profile_usecase.dart'
    as _i465;
import 'package:sellweb/features/auth/domain/usecases/fetch_admin_profile_usecase.dart'
    as _i33;
import 'package:sellweb/features/auth/domain/usecases/get_account_admins_usecase.dart'
    as _i563;
import 'package:sellweb/features/auth/domain/usecases/get_account_usecase.dart'
    as _i134;
import 'package:sellweb/features/auth/domain/usecases/get_demo_account_usecase.dart'
    as _i612;
import 'package:sellweb/features/auth/domain/usecases/get_demo_admin_profile_usecase.dart'
    as _i388;
import 'package:sellweb/features/auth/domain/usecases/get_profiles_accounts_associated_usecase.dart'
    as _i817;
import 'package:sellweb/features/auth/domain/usecases/get_selected_account_id_usecase.dart'
    as _i654;
import 'package:sellweb/features/auth/domain/usecases/get_user_accounts_usecase.dart'
    as _i644;
import 'package:sellweb/features/auth/domain/usecases/get_user_stream_usecase.dart'
    as _i557;
import 'package:sellweb/features/auth/domain/usecases/load_admin_profile_usecase.dart'
    as _i769;
import 'package:sellweb/features/auth/domain/usecases/remove_selected_account_id_usecase.dart'
    as _i2;
import 'package:sellweb/features/auth/domain/usecases/save_admin_profile_usecase.dart'
    as _i475;
import 'package:sellweb/features/auth/domain/usecases/save_selected_account_id_usecase.dart'
    as _i695;
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
import 'package:sellweb/features/cash_register/data/repositories/cash_register_repository_impl.dart'
    as _i1059;
import 'package:sellweb/features/cash_register/domain/repositories/cash_register_repository.dart'
    as _i818;
import 'package:sellweb/features/cash_register/domain/usecases/add_cash_inflow_usecase.dart'
    as _i457;
import 'package:sellweb/features/cash_register/domain/usecases/add_cash_outflow_usecase.dart'
    as _i9;
import 'package:sellweb/features/cash_register/domain/usecases/add_cash_register_to_history_usecase.dart'
    as _i548;
import 'package:sellweb/features/cash_register/domain/usecases/cash_register_usecases.dart'
    as _i795;
import 'package:sellweb/features/cash_register/domain/usecases/close_cash_register_usecase.dart'
    as _i202;
import 'package:sellweb/features/cash_register/domain/usecases/create_cash_register_fixed_description_usecase.dart'
    as _i23;
import 'package:sellweb/features/cash_register/domain/usecases/delete_cash_register_fixed_description_usecase.dart'
    as _i264;
import 'package:sellweb/features/cash_register/domain/usecases/delete_cash_register_from_history_usecase.dart'
    as _i847;
import 'package:sellweb/features/cash_register/domain/usecases/delete_cash_register_usecase.dart'
    as _i96;
import 'package:sellweb/features/cash_register/domain/usecases/delete_transaction_usecase.dart'
    as _i830;
import 'package:sellweb/features/cash_register/domain/usecases/get_active_cash_registers_stream_usecase.dart'
    as _i797;
import 'package:sellweb/features/cash_register/domain/usecases/get_active_cash_registers_usecase.dart'
    as _i216;
import 'package:sellweb/features/cash_register/domain/usecases/get_cash_register_by_date_range_usecase.dart'
    as _i760;
import 'package:sellweb/features/cash_register/domain/usecases/get_cash_register_by_days_usecase.dart'
    as _i522;
import 'package:sellweb/features/cash_register/domain/usecases/get_cash_register_fixed_descriptions_usecase.dart'
    as _i322;
import 'package:sellweb/features/cash_register/domain/usecases/get_cash_register_history_stream_usecase.dart'
    as _i276;
import 'package:sellweb/features/cash_register/domain/usecases/get_cash_register_history_usecase.dart'
    as _i95;
import 'package:sellweb/features/cash_register/domain/usecases/get_today_cash_registers_usecase.dart'
    as _i209;
import 'package:sellweb/features/cash_register/domain/usecases/get_today_transactions_stream_usecase.dart'
    as _i34;
import 'package:sellweb/features/cash_register/domain/usecases/get_transaction_detail_usecase.dart'
    as _i827;
import 'package:sellweb/features/cash_register/domain/usecases/get_transactions_by_date_range_usecase.dart'
    as _i466;
import 'package:sellweb/features/cash_register/domain/usecases/get_transactions_stream_usecase.dart'
    as _i454;
import 'package:sellweb/features/cash_register/domain/usecases/open_cash_register_usecase.dart'
    as _i512;
import 'package:sellweb/features/cash_register/domain/usecases/process_ticket_annullment_usecase.dart'
    as _i547;
import 'package:sellweb/features/cash_register/domain/usecases/save_ticket_to_transaction_history_usecase.dart'
    as _i223;
import 'package:sellweb/features/cash_register/domain/usecases/save_ticket_transaction_usecase.dart'
    as _i1034;
import 'package:sellweb/features/cash_register/domain/usecases/set_cash_register_usecase.dart'
    as _i173;
import 'package:sellweb/features/cash_register/domain/usecases/update_billing_on_annullment_usecase.dart'
    as _i851;
import 'package:sellweb/features/cash_register/domain/usecases/update_sales_and_billing_usecase.dart'
    as _i90;
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart'
    as _i306;
import 'package:sellweb/features/catalogue/data/datasources/catalogue_remote_datasource.dart'
    as _i983;
import 'package:sellweb/features/catalogue/data/repositories/catalogue_repository_impl.dart'
    as _i576;
import 'package:sellweb/features/catalogue/domain/repositories/catalogue_repository.dart'
    as _i83;
import 'package:sellweb/features/catalogue/domain/usecases/add_product_to_catalogue_usecase.dart'
    as _i821;
import 'package:sellweb/features/catalogue/domain/usecases/catalogue_usecases.dart'
    as _i1012;
import 'package:sellweb/features/catalogue/domain/usecases/create_brand_usecase.dart'
    as _i753;
import 'package:sellweb/features/catalogue/domain/usecases/create_public_product_usecase.dart'
    as _i540;
import 'package:sellweb/features/catalogue/domain/usecases/decrement_product_stock_usecase.dart'
    as _i84;
import 'package:sellweb/features/catalogue/domain/usecases/get_brands_stream_usecase.dart'
    as _i230;
import 'package:sellweb/features/catalogue/domain/usecases/get_catalogue_stream_usecase.dart'
    as _i474;
import 'package:sellweb/features/catalogue/domain/usecases/get_categories_stream_usecase.dart'
    as _i690;
import 'package:sellweb/features/catalogue/domain/usecases/get_demo_products_usecase.dart'
    as _i329;
import 'package:sellweb/features/catalogue/domain/usecases/get_product_by_code_usecase.dart'
    as _i377;
import 'package:sellweb/features/catalogue/domain/usecases/get_products_usecase.dart'
    as _i453;
import 'package:sellweb/features/catalogue/domain/usecases/get_providers_stream_usecase.dart'
    as _i241;
import 'package:sellweb/features/catalogue/domain/usecases/get_public_product_by_code_usecase.dart'
    as _i1001;
import 'package:sellweb/features/catalogue/domain/usecases/increment_product_sales_usecase.dart'
    as _i878;
import 'package:sellweb/features/catalogue/domain/usecases/is_product_scanned_usecase.dart'
    as _i943;
import 'package:sellweb/features/catalogue/domain/usecases/register_product_price_usecase.dart'
    as _i651;
import 'package:sellweb/features/catalogue/domain/usecases/update_product_favorite_usecase.dart'
    as _i55;
import 'package:sellweb/features/catalogue/domain/usecases/update_stock_usecase.dart'
    as _i226;
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart'
    as _i127;
import 'package:sellweb/features/multiuser/data/datasources/multi_user_remote_datasource.dart'
    as _i925;
import 'package:sellweb/features/multiuser/data/repositories/multi_user_repository_impl.dart'
    as _i431;
import 'package:sellweb/features/multiuser/domain/repositories/multi_user_repository.dart'
    as _i754;
import 'package:sellweb/features/multiuser/domain/usecases/create_user_usecase.dart'
    as _i442;
import 'package:sellweb/features/multiuser/domain/usecases/delete_user_usecase.dart'
    as _i799;
import 'package:sellweb/features/multiuser/domain/usecases/get_users_usecase.dart'
    as _i353;
import 'package:sellweb/features/multiuser/domain/usecases/update_user_usecase.dart'
    as _i395;
import 'package:sellweb/features/multiuser/presentation/provider/multi_user_provider.dart'
    as _i564;
import 'package:sellweb/features/sales/domain/usecases/add_product_to_ticket_usecase.dart'
    as _i60;
import 'package:sellweb/features/sales/domain/usecases/assign_seller_to_ticket_usecase.dart'
    as _i634;
import 'package:sellweb/features/sales/domain/usecases/associate_ticket_with_cash_register_usecase.dart'
    as _i1056;
import 'package:sellweb/features/sales/domain/usecases/clear_last_sold_ticket_usecase.dart'
    as _i276;
import 'package:sellweb/features/sales/domain/usecases/create_empty_ticket_usecase.dart'
    as _i283;
import 'package:sellweb/features/sales/domain/usecases/create_quick_product_usecase.dart'
    as _i853;
import 'package:sellweb/features/sales/domain/usecases/get_last_sold_ticket_usecase.dart'
    as _i162;
import 'package:sellweb/features/sales/domain/usecases/has_last_sold_ticket_usecase.dart'
    as _i556;
import 'package:sellweb/features/sales/domain/usecases/prepare_sale_ticket_usecase.dart'
    as _i399;
import 'package:sellweb/features/sales/domain/usecases/prepare_ticket_for_transaction_usecase.dart'
    as _i220;
import 'package:sellweb/features/sales/domain/usecases/remove_product_from_ticket_usecase.dart'
    as _i449;
import 'package:sellweb/features/sales/domain/usecases/save_last_sold_ticket_usecase.dart'
    as _i401;
import 'package:sellweb/features/sales/domain/usecases/sell_usecases.dart'
    as _i76;
import 'package:sellweb/features/sales/domain/usecases/set_ticket_discount_usecase.dart'
    as _i240;
import 'package:sellweb/features/sales/domain/usecases/set_ticket_payment_mode_usecase.dart'
    as _i953;
import 'package:sellweb/features/sales/domain/usecases/set_ticket_received_cash_usecase.dart'
    as _i519;
import 'package:sellweb/features/sales/domain/usecases/update_ticket_fields_usecase.dart'
    as _i382;
import 'package:sellweb/features/sales/presentation/providers/printer_provider.dart'
    as _i178;
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart'
    as _i454;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final externalModule = _$ExternalModule();
    gh.lazySingleton<_i974.FirebaseFirestore>(() => externalModule.firestore);
    gh.lazySingleton<_i457.FirebaseStorage>(() => externalModule.storage);
    await gh.lazySingletonAsync<_i460.SharedPreferences>(
      () => externalModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i59.FirebaseAuth>(() => externalModule.firebaseAuth);
    gh.lazySingleton<_i116.GoogleSignIn>(() => externalModule.googleSignIn);
    gh.lazySingleton<_i853.CreateQuickProductUseCase>(
        () => _i853.CreateQuickProductUseCase());
    gh.lazySingleton<_i283.CreateEmptyTicketUseCase>(
        () => _i283.CreateEmptyTicketUseCase());
    gh.lazySingleton<_i220.PrepareTicketForTransactionUseCase>(
        () => _i220.PrepareTicketForTransactionUseCase());
    gh.lazySingleton<_i399.PrepareSaleTicketUseCase>(
        () => _i399.PrepareSaleTicketUseCase());
    gh.lazySingleton<_i240.SetTicketDiscountUseCase>(
        () => _i240.SetTicketDiscountUseCase());
    gh.lazySingleton<_i634.AssignSellerToTicketUseCase>(
        () => _i634.AssignSellerToTicketUseCase());
    gh.lazySingleton<_i382.UpdateTicketFieldsUseCase>(
        () => _i382.UpdateTicketFieldsUseCase());
    gh.lazySingleton<_i519.SetTicketReceivedCashUseCase>(
        () => _i519.SetTicketReceivedCashUseCase());
    gh.lazySingleton<_i60.AddProductToTicketUseCase>(
        () => _i60.AddProductToTicketUseCase());
    gh.lazySingleton<_i953.SetTicketPaymentModeUseCase>(
        () => _i953.SetTicketPaymentModeUseCase());
    gh.lazySingleton<_i1056.AssociateTicketWithCashRegisterUseCase>(
        () => _i1056.AssociateTicketWithCashRegisterUseCase());
    gh.lazySingleton<_i449.RemoveProductFromTicketUseCase>(
        () => _i449.RemoveProductFromTicketUseCase());
    gh.lazySingleton<_i388.GetDemoAdminProfileUseCase>(
        () => _i388.GetDemoAdminProfileUseCase());
    gh.lazySingleton<_i612.GetDemoAccountUseCase>(
        () => _i612.GetDemoAccountUseCase());
    gh.lazySingleton<_i329.GetDemoProductsUseCase>(
        () => _i329.GetDemoProductsUseCase());
    gh.lazySingleton<_i377.GetProductByCodeUseCase>(
        () => _i377.GetProductByCodeUseCase());
    gh.lazySingleton<_i1012.TrendCalculatorService>(
        () => _i1012.TrendCalculatorService());
    gh.lazySingleton<_i283.IStorageDataSource>(
        () => _i390.StorageDataSource(gh<_i457.FirebaseStorage>()));
    gh.lazySingleton<_i581.AppDataPersistenceService>(
        () => _i581.AppDataPersistenceService(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i276.ClearLastSoldTicketUseCase>(() =>
        _i276.ClearLastSoldTicketUseCase(
            gh<_i581.AppDataPersistenceService>()));
    gh.lazySingleton<_i401.SaveLastSoldTicketUseCase>(() =>
        _i401.SaveLastSoldTicketUseCase(gh<_i581.AppDataPersistenceService>()));
    gh.lazySingleton<_i162.GetLastSoldTicketUseCase>(() =>
        _i162.GetLastSoldTicketUseCase(gh<_i581.AppDataPersistenceService>()));
    gh.lazySingleton<_i556.HasLastSoldTicketUseCase>(() =>
        _i556.HasLastSoldTicketUseCase(gh<_i581.AppDataPersistenceService>()));
    gh.lazySingleton<_i769.LoadAdminProfileUseCase>(() =>
        _i769.LoadAdminProfileUseCase(gh<_i581.AppDataPersistenceService>()));
    gh.lazySingleton<_i465.ClearAdminProfileUseCase>(() =>
        _i465.ClearAdminProfileUseCase(gh<_i581.AppDataPersistenceService>()));
    gh.lazySingleton<_i475.SaveAdminProfileUseCase>(() =>
        _i475.SaveAdminProfileUseCase(gh<_i581.AppDataPersistenceService>()));
    gh.lazySingleton<_i750.ThemeService>(
        () => _i750.ThemeService(gh<_i581.AppDataPersistenceService>()));
    gh.lazySingleton<_i897.ThermalPrinterHttpService>(() =>
        _i897.ThermalPrinterHttpService(gh<_i581.AppDataPersistenceService>()));
    gh.factory<_i984.ThemeDataAppProvider>(() => _i984.ThemeDataAppProvider(
          gh<_i750.ThemeService>(),
          gh<_i581.AppDataPersistenceService>(),
        ));
    gh.lazySingleton<_i76.SellUsecases>(() => _i76.SellUsecases(
        persistenceService: gh<_i581.AppDataPersistenceService>()));
    gh.lazySingleton<_i823.AddDemoAccountIfAnonymousUseCase>(() =>
        _i823.AddDemoAccountIfAnonymousUseCase(
            gh<_i612.GetDemoAccountUseCase>()));
    gh.lazySingleton<_i943.IsProductScannedUseCase>(() =>
        _i943.IsProductScannedUseCase(gh<_i377.GetProductByCodeUseCase>()));
    gh.lazySingleton<_i562.IFirestoreDataSource>(
        () => _i485.FirestoreDataSource(gh<_i974.FirebaseFirestore>()));
    gh.factory<_i178.PrinterProvider>(
        () => _i178.PrinterProvider(gh<_i897.ThermalPrinterHttpService>()));
    gh.lazySingleton<_i577.AnalyticsRemoteDataSource>(() =>
        _i577.AnalyticsRemoteDataSource(gh<_i562.IFirestoreDataSource>()));
    gh.lazySingleton<_i716.AnalyticsPreferencesRemoteDataSource>(() =>
        _i716.AnalyticsPreferencesRemoteDataSource(
            gh<_i562.IFirestoreDataSource>()));
    gh.lazySingleton<_i818.CashRegisterRepository>(() =>
        _i1059.CashRegisterRepositoryImpl(gh<_i562.IFirestoreDataSource>()));
    gh.lazySingleton<_i348.AuthRepository>(() => _i566.AuthRepositoryImpl(
          gh<_i59.FirebaseAuth>(),
          gh<_i116.GoogleSignIn>(),
        ));
    gh.lazySingleton<_i1071.IProductRepository>(
        () => _i1071.ProductRepositoryImpl(gh<_i562.IFirestoreDataSource>()));
    gh.lazySingleton<_i1071.GetProductsUseCase>(
        () => _i1071.GetProductsUseCase(gh<_i1071.IProductRepository>()));
    gh.lazySingleton<_i840.AccountRepository>(() => _i166.AccountRepositoryImpl(
          gh<_i562.IFirestoreDataSource>(),
          gh<_i581.AppDataPersistenceService>(),
        ));
    gh.lazySingleton<_i654.GetSelectedAccountIdUseCase>(
        () => _i654.GetSelectedAccountIdUseCase(gh<_i840.AccountRepository>()));
    gh.lazySingleton<_i695.SaveSelectedAccountIdUseCase>(() =>
        _i695.SaveSelectedAccountIdUseCase(gh<_i840.AccountRepository>()));
    gh.lazySingleton<_i134.GetAccountUseCase>(
        () => _i134.GetAccountUseCase(gh<_i840.AccountRepository>()));
    gh.lazySingleton<_i563.GetAccountAdminsUseCase>(
        () => _i563.GetAccountAdminsUseCase(gh<_i840.AccountRepository>()));
    gh.lazySingleton<_i2.RemoveSelectedAccountIdUseCase>(() =>
        _i2.RemoveSelectedAccountIdUseCase(gh<_i840.AccountRepository>()));
    gh.factory<_i1071.ProductProvider>(
        () => _i1071.ProductProvider(gh<_i1071.GetProductsUseCase>()));
    gh.lazySingleton<_i33.FetchAdminProfileUseCase>(() =>
        _i33.FetchAdminProfileUseCase(gh<_i563.GetAccountAdminsUseCase>()));
    gh.lazySingleton<_i817.GetProfilesAccountsAssociatedUseCase>(
        () => _i817.GetProfilesAccountsAssociatedUseCase(
              gh<_i563.GetAccountAdminsUseCase>(),
              gh<_i134.GetAccountUseCase>(),
            ));
    gh.lazySingleton<_i83.CatalogueRepository>(
        () => _i576.CatalogueRepositoryImpl(gh<_i562.IFirestoreDataSource>()));
    gh.factory<_i956.AnalyticsPreferencesService>(
        () => _i956.AnalyticsPreferencesService(
              gh<_i581.AppDataPersistenceService>(),
              gh<_i716.AnalyticsPreferencesRemoteDataSource>(),
            ));
    gh.lazySingleton<_i925.MultiUserRemoteDataSource>(() =>
        _i925.MultiUserRemoteDataSourceImpl(gh<_i562.IFirestoreDataSource>()));
    gh.lazySingleton<_i983.CatalogueRemoteDataSource>(() =>
        _i983.CatalogueRemoteDataSourceImpl(gh<_i562.IFirestoreDataSource>()));
    gh.lazySingleton<_i732.AnalyticsRepository>(() =>
        _i164.AnalyticsRepositoryImpl(gh<_i577.AnalyticsRemoteDataSource>()));
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
    gh.lazySingleton<_i23.CreateCashRegisterFixedDescriptionUseCase>(() =>
        _i23.CreateCashRegisterFixedDescriptionUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i522.GetCashRegisterByDaysUseCase>(() =>
        _i522.GetCashRegisterByDaysUseCase(gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i851.UpdateBillingOnAnnullmentUseCase>(() =>
        _i851.UpdateBillingOnAnnullmentUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i90.UpdateSalesAndBillingUseCase>(() =>
        _i90.UpdateSalesAndBillingUseCase(gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i1034.SaveTicketTransactionUseCase>(() =>
        _i1034.SaveTicketTransactionUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i9.AddCashOutflowUseCase>(
        () => _i9.AddCashOutflowUseCase(gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i466.GetTransactionsByDateRangeUseCase>(() =>
        _i466.GetTransactionsByDateRangeUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i95.GetCashRegisterHistoryUseCase>(() =>
        _i95.GetCashRegisterHistoryUseCase(gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i34.GetTodayTransactionsStreamUseCase>(() =>
        _i34.GetTodayTransactionsStreamUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i276.GetCashRegisterHistoryStreamUseCase>(() =>
        _i276.GetCashRegisterHistoryStreamUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i827.GetTransactionDetailUseCase>(() =>
        _i827.GetTransactionDetailUseCase(gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i173.SetCashRegisterUseCase>(
        () => _i173.SetCashRegisterUseCase(gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i512.OpenCashRegisterUseCase>(() =>
        _i512.OpenCashRegisterUseCase(gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i548.AddCashRegisterToHistoryUseCase>(() =>
        _i548.AddCashRegisterToHistoryUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i202.CloseCashRegisterUseCase>(() =>
        _i202.CloseCashRegisterUseCase(gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i847.DeleteCashRegisterFromHistoryUseCase>(() =>
        _i847.DeleteCashRegisterFromHistoryUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i216.GetActiveCashRegistersUseCase>(() =>
        _i216.GetActiveCashRegistersUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i760.GetCashRegisterByDateRangeUseCase>(() =>
        _i760.GetCashRegisterByDateRangeUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i322.GetCashRegisterFixedDescriptionsUseCase>(() =>
        _i322.GetCashRegisterFixedDescriptionsUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i797.GetActiveCashRegistersStreamUseCase>(() =>
        _i797.GetActiveCashRegistersStreamUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i96.DeleteCashRegisterUseCase>(() =>
        _i96.DeleteCashRegisterUseCase(gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i457.AddCashInflowUseCase>(
        () => _i457.AddCashInflowUseCase(gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i454.GetTransactionsStreamUseCase>(() =>
        _i454.GetTransactionsStreamUseCase(gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i830.DeleteTransactionUseCase>(() =>
        _i830.DeleteTransactionUseCase(gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i209.GetTodayCashRegistersUseCase>(() =>
        _i209.GetTodayCashRegistersUseCase(gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i264.DeleteCashRegisterFixedDescriptionUseCase>(() =>
        _i264.DeleteCashRegisterFixedDescriptionUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i547.ProcessTicketAnnullmentUseCase>(() =>
        _i547.ProcessTicketAnnullmentUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i795.CashRegisterUsecases>(
        () => _i795.CashRegisterUsecases(gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i223.SaveTicketToTransactionHistoryUseCase>(() =>
        _i223.SaveTicketToTransactionHistoryUseCase(
            gh<_i818.CashRegisterRepository>()));
    gh.lazySingleton<_i651.RegisterProductPriceUseCase>(() =>
        _i651.RegisterProductPriceUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i55.UpdateProductFavoriteUseCase>(() =>
        _i55.UpdateProductFavoriteUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i753.CreateBrandUseCase>(
        () => _i753.CreateBrandUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i821.AddProductToCatalogueUseCase>(() =>
        _i821.AddProductToCatalogueUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i540.CreatePublicProductUseCase>(
        () => _i540.CreatePublicProductUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i230.GetBrandsStreamUseCase>(
        () => _i230.GetBrandsStreamUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i241.GetProvidersStreamUseCase>(
        () => _i241.GetProvidersStreamUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i474.GetCatalogueStreamUseCase>(
        () => _i474.GetCatalogueStreamUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i1001.GetPublicProductByCodeUseCase>(() =>
        _i1001.GetPublicProductByCodeUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i84.DecrementProductStockUseCase>(() =>
        _i84.DecrementProductStockUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i878.IncrementProductSalesUseCase>(() =>
        _i878.IncrementProductSalesUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i690.GetCategoriesStreamUseCase>(
        () => _i690.GetCategoriesStreamUseCase(gh<_i83.CatalogueRepository>()));
    gh.factory<_i1012.CatalogueUseCases>(
        () => _i1012.CatalogueUseCases(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i226.UpdateStockUseCase>(
        () => _i226.UpdateStockUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i453.GetProductsUseCase>(
        () => _i453.GetProductsUseCase(gh<_i83.CatalogueRepository>()));
    gh.lazySingleton<_i644.GetUserAccountsUseCase>(
        () => _i644.GetUserAccountsUseCase(
              gh<_i840.AccountRepository>(),
              gh<_i581.AppDataPersistenceService>(),
            ));
    gh.lazySingleton<_i754.MultiUserRepository>(() =>
        _i431.MultiUserRepositoryImpl(gh<_i925.MultiUserRemoteDataSource>()));
    gh.lazySingleton<_i442.CreateUserUseCase>(
        () => _i442.CreateUserUseCase(gh<_i754.MultiUserRepository>()));
    gh.lazySingleton<_i353.GetUsersUseCase>(
        () => _i353.GetUsersUseCase(gh<_i754.MultiUserRepository>()));
    gh.lazySingleton<_i799.DeleteUserUseCase>(
        () => _i799.DeleteUserUseCase(gh<_i754.MultiUserRepository>()));
    gh.lazySingleton<_i395.UpdateUserUseCase>(
        () => _i395.UpdateUserUseCase(gh<_i754.MultiUserRepository>()));
    gh.factory<_i127.CatalogueProvider>(() => _i127.CatalogueProvider(
          gh<_i474.GetCatalogueStreamUseCase>(),
          gh<_i1001.GetPublicProductByCodeUseCase>(),
          gh<_i821.AddProductToCatalogueUseCase>(),
          gh<_i540.CreatePublicProductUseCase>(),
          gh<_i651.RegisterProductPriceUseCase>(),
          gh<_i878.IncrementProductSalesUseCase>(),
          gh<_i84.DecrementProductStockUseCase>(),
          gh<_i55.UpdateProductFavoriteUseCase>(),
          gh<_i690.GetCategoriesStreamUseCase>(),
          gh<_i241.GetProvidersStreamUseCase>(),
          gh<_i230.GetBrandsStreamUseCase>(),
          gh<_i753.CreateBrandUseCase>(),
        ));
    gh.factory<_i638.AuthProvider>(() => _i638.AuthProvider(
          gh<_i253.SignInWithGoogleUseCase>(),
          gh<_i1046.SignInSilentlyUseCase>(),
          gh<_i380.SignInAnonymouslyUseCase>(),
          gh<_i158.SignOutUseCase>(),
          gh<_i557.GetUserStreamUseCase>(),
          gh<_i644.GetUserAccountsUseCase>(),
        ));
    gh.factory<_i306.CashRegisterProvider>(() => _i306.CashRegisterProvider(
          gh<_i512.OpenCashRegisterUseCase>(),
          gh<_i202.CloseCashRegisterUseCase>(),
          gh<_i216.GetActiveCashRegistersUseCase>(),
          gh<_i797.GetActiveCashRegistersStreamUseCase>(),
          gh<_i457.AddCashInflowUseCase>(),
          gh<_i9.AddCashOutflowUseCase>(),
          gh<_i90.UpdateSalesAndBillingUseCase>(),
          gh<_i95.GetCashRegisterHistoryUseCase>(),
          gh<_i522.GetCashRegisterByDaysUseCase>(),
          gh<_i760.GetCashRegisterByDateRangeUseCase>(),
          gh<_i547.ProcessTicketAnnullmentUseCase>(),
          gh<_i23.CreateCashRegisterFixedDescriptionUseCase>(),
          gh<_i322.GetCashRegisterFixedDescriptionsUseCase>(),
          gh<_i264.DeleteCashRegisterFixedDescriptionUseCase>(),
          gh<_i34.GetTodayTransactionsStreamUseCase>(),
          gh<_i466.GetTransactionsByDateRangeUseCase>(),
          gh<_i223.SaveTicketToTransactionHistoryUseCase>(),
          gh<_i581.AppDataPersistenceService>(),
        ));
    gh.factory<_i454.SalesProvider>(() => _i454.SalesProvider(
          getUserAccountsUseCase: gh<_i644.GetUserAccountsUseCase>(),
          addProductToTicketUseCase: gh<_i60.AddProductToTicketUseCase>(),
          removeProductFromTicketUseCase:
              gh<_i449.RemoveProductFromTicketUseCase>(),
          createQuickProductUseCase: gh<_i853.CreateQuickProductUseCase>(),
          setTicketPaymentModeUseCase: gh<_i953.SetTicketPaymentModeUseCase>(),
          setTicketDiscountUseCase: gh<_i240.SetTicketDiscountUseCase>(),
          setTicketReceivedCashUseCase:
              gh<_i519.SetTicketReceivedCashUseCase>(),
          associateTicketWithCashRegisterUseCase:
              gh<_i1056.AssociateTicketWithCashRegisterUseCase>(),
          prepareSaleTicketUseCase: gh<_i399.PrepareSaleTicketUseCase>(),
          prepareTicketForTransactionUseCase:
              gh<_i220.PrepareTicketForTransactionUseCase>(),
          saveLastSoldTicketUseCase: gh<_i401.SaveLastSoldTicketUseCase>(),
          getLastSoldTicketUseCase: gh<_i162.GetLastSoldTicketUseCase>(),
          persistenceService: gh<_i581.AppDataPersistenceService>(),
          printerService: gh<_i897.ThermalPrinterHttpService>(),
          catalogueUseCases: gh<_i1012.CatalogueUseCases>(),
        ));
    gh.lazySingleton<_i161.GetSalesAnalyticsUseCase>(
        () => _i161.GetSalesAnalyticsUseCase(gh<_i732.AnalyticsRepository>()));
    gh.factory<_i564.MultiUserProvider>(() => _i564.MultiUserProvider(
          gh<_i353.GetUsersUseCase>(),
          gh<_i442.CreateUserUseCase>(),
          gh<_i395.UpdateUserUseCase>(),
          gh<_i799.DeleteUserUseCase>(),
          gh<_i644.GetUserAccountsUseCase>(),
        ));
    gh.factory<_i975.AnalyticsProvider>(() => _i975.AnalyticsProvider(
          gh<_i161.GetSalesAnalyticsUseCase>(),
          gh<_i956.AnalyticsPreferencesService>(),
          gh<_i1012.TrendCalculatorService>(),
        ));
    gh.factory<_i185.AccountScopeProvider>(() => _i185.AccountScopeProvider(
          gh<_i127.CatalogueProvider>(),
          gh<_i306.CashRegisterProvider>(),
          gh<_i975.AnalyticsProvider>(),
        ));
    return this;
  }
}

class _$ExternalModule extends _i220.ExternalModule {}
