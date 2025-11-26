---
description: Crear un nuevo feature completo con Feature-First + Clean Architecture
---

# WORKFLOW: NUEVO FEATURE (Clean Architecture)
# Estándar: Feature-First + Domain/Data/Presentation

## 1. PREPARACIÓN
# Estructura de directorios
mkdir -p lib/features/[name]/{domain/{entities,repositories,usecases},data/{models,datasources,repositories},presentation/{providers,pages,widgets}}

## 2. DOMAIN LAYER (Puro Dart)

### 2.1 Entity (domain/entities/my_entity.dart)
# Reglas: Inmutable, Equatable (opc), sin dependencias externas.
class MyEntity {
  final String id;
  final String name;
  const MyEntity({required this.id, required this.name});
  
  MyEntity copyWith({String? id, String? name}) {
    return MyEntity(id: id ?? this.id, name: name ?? this.name);
  }
}

### 2.2 Repository Interface (domain/repositories/my_repository.dart)
# Reglas: Abstract class, retorna Future<Either<Failure, T>>.
abstract class MyRepository {
  Future<Either<Failure, List<MyEntity>>> getAll(String accountId);
  Future<Either<Failure, void>> create(MyEntity entity);
}

### 2.3 UseCase (domain/usecases/get_all_usecase.dart)
# Reglas: @lazySingleton, 1 clase = 1 operación.
@lazySingleton
class GetAllUseCase implements UseCase<List<MyEntity>, String> {
  final MyRepository _repo;
  GetAllUseCase(this._repo);

  @override
  Future<Either<Failure, List<MyEntity>>> call(String params) => _repo.getAll(params);
}

## 3. DATA LAYER (Implementación)

### 3.1 Model (data/models/my_model.dart)
# Reglas: Extiende Entity, Mapeo JSON/Firestore.
class MyModel extends MyEntity {
  const MyModel({required super.id, required super.name});

  factory MyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MyModel(id: doc.id, name: data['name']);
  }

  Map<String, dynamic> toJson() => {'name': name};
  
  factory MyModel.fromEntity(MyEntity e) => MyModel(id: e.id, name: e.name);
}

### 3.2 DataSource (data/datasources/my_datasource.dart)
# Reglas: @lazySingleton, Throw Exceptions, usa Models.
@lazySingleton
class MyDataSource {
  final FirebaseFirestore _db;
  MyDataSource(this._db);

  CollectionReference _coll(String accId) => _db.collection('acc').doc(accId).collection('items');

  Future<List<MyModel>> getAll(String accId) async {
    try {
      final snap = await _coll(accId).get();
      return snap.docs.map((d) => MyModel.fromFirestore(d)).toList();
    } catch (e) { throw Exception(e); }
  }
}

### 3.3 Repository Impl (data/repositories/my_repo_impl.dart)
# Reglas: @LazySingleton(as: Interface), Catch Exceptions -> Failures.
@LazySingleton(as: MyRepository)
class MyRepoImpl implements MyRepository {
  final MyDataSource _ds;
  MyRepoImpl(this._ds);

  @override
  Future<Either<Failure, List<MyEntity>>> getAll(String accId) async {
    try {
      final res = await _ds.getAll(accId);
      return Right(res);
    } catch (e) { return Left(ServerFailure(e.toString())); }
  }
}

## 4. PRESENTATION LAYER (UI)

### 4.1 Provider (presentation/providers/my_provider.dart)
# Reglas: @injectable, ChangeNotifier, inyecta UseCases.
@injectable
class MyProvider extends ChangeNotifier {
  final GetAllUseCase _getAll;
  MyProvider(this._getAll);

  List<MyEntity> _items = [];
  bool _loading = false;
  
  List<MyEntity> get items => _items;
  bool get isLoading => _loading;

  Future<void> load(String accId) async {
    _loading = true; notifyListeners();
    final res = await _getAll(accId);
    res.fold(
      (err) => print(err), // Manejar error
      (data) => _items = data
    );
    _loading = false; notifyListeners();
  }
}

### 4.2 Page (presentation/pages/my_page.dart)
# Reglas: Consumer/Selector, initState carga datos.
class MyPage extends StatefulWidget { ... }
class _MyPageState extends State<MyPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyProvider>().load('id');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyProvider>(
      builder: (ctx, prov, _) {
        if (prov.isLoading) return CircularProgressIndicator();
        return ListView.builder(
          itemCount: prov.items.length,
          itemBuilder: (_, i) => Text(prov.items[i].name)
        );
      }
    );
  }
}

## 5. SETUP FINAL

# Generar DI
dart run build_runner build --delete-conflicting-outputs

# Registrar en main.dart
ChangeNotifierProvider(create: (_) => getIt<MyProvider>())

# Check Quality
flutter analyze
flutter build web --release

## REGLAS DE ORO
1. Domain NO importa Data ni Presentation.
2. Presentation SOLO habla con Domain (UseCases).
3. Data SOLO implementa Domain.
4. Feature Isolation: No importar features vecinos directamente (usar Core).