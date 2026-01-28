import 'package:injectable/injectable.dart';
import 'package:hive_flutter/hive_flutter.dart';

@module
abstract class LocalDatabaseModule {
  
  @preResolve
  Future<HiveInterface> get initHive async {
    await Hive.initFlutter();
    return Hive;
  }

  @preResolve
  @Named('productsBox')
  Future<Box> get productsBox async {
    return await Hive.openBox('products_cache_v1');
  }

  @preResolve
  @Named('categoriesBox')
  Future<Box> get categoriesBox async {
    return await Hive.openBox('categories_cache_v1');
  }
}
