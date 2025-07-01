import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:intl/intl.dart';

class UserAuth {
  final String? uid;
  final String? email;
  final String? displayName; 
  final bool? isAnonymous;
  final String? photoUrl;

  UserAuth({
    this.uid,
    this.email,
    this.displayName, 
    this.isAnonymous,
    this.photoUrl,
  });
  
}

class AdminModel {
  
  AdminModel({
    this.id = "",
    this.inactivate = false,
    this.account = "", 
    this.email = '',  
    this.name='', 
    this.superAdmin = false,  
    this.admin = false,  
    this.personalized = false,  
    required this.creation,
    required this.lastUpdate,
    this.startTime = const {},
    this.endTime = const {},
    this.daysOfWeek = const [],
    // ... 
    this.arqueo = false,  
    this.historyArqueo = false, 
    this.transactions = false, 
    this.catalogue = false,  
    this.multiuser = false,  
    this.editAccount = false,   
  });

  String id = ""; // id de autenticación del usuario
  bool inactivate = false; // inactivar usuario
  String account = ""; // el ID de la cuenta administrada por defecto es el ID del usuario quien lo creo
  String email = ''; // email del usuario
  String name=''; // nombre del usuario (opcaional)
  bool superAdmin = false; // Super administrador es el usaurio que creo la cuenta
  bool admin = false; // permiso de administrador 
  Timestamp creation = Timestamp.now(); // Fecha en la que se creo la cuenta
  Timestamp lastUpdate = Timestamp.now(); // Fecha en la que se actualizo la cuenta
  Map<String,dynamic> startTime = {}; // hora de acceso habilitada para el usuario
  Map<String,dynamic> endTime = {}; // hora de cierre de acceso para el usuario
  List daysOfWeek = []; // dias de la semana habilitados al acceso
  // permisos personalizados
  bool personalized = false;
  // ...  
  bool arqueo = false; // crear arqueo de caja
  bool historyArqueo = false; // ver y eliminar registros de arqueo de caja
  bool transactions = false; // ver y eliminar registros de transacciones
  bool catalogue = false;  // ver, editar y eliminar productos del catalogo
  bool multiuser = false;  // ver, editar y eliminar usuarios de la cuenta
  bool editAccount = false; // editar la cuenta


  factory AdminModel.fromDocument(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return AdminModel( 
      id: doc.id,
      inactivate: data.containsKey("inactivate") ? doc["inactivate"] : false,
      account: doc["account"],
      email: data.containsKey("email") ? doc["email"] : '',
      name: data.containsKey('name') ? doc['name'] : '',
      superAdmin: data.containsKey("superAdmin") ? doc["superAdmin"] : false,
      admin: data.containsKey("admin") ? doc["admin"] : false,
      personalized: data.containsKey("personalized") ? doc["personalized"] : false,
      creation: data.containsKey("creation") ? doc["creation"] : Timestamp.now(),
      lastUpdate: data.containsKey("lastUpdate") ? doc["lastUpdate"] : Timestamp.now(),
      startTime: data.containsKey("startTime") ? doc["startTime"] : {},
      endTime: data.containsKey("endTime") ? doc["endTime"] : {},
      daysOfWeek: data.containsKey("daysOfWeek") ? doc["daysOfWeek"] : [],
      // ... 
      arqueo: data.containsKey("arqueo") ? doc["arqueo"] : false,
      historyArqueo: data.containsKey("historyArqueo") ? doc["historyArqueo"] : false,
      transactions: data.containsKey("transactions") ? doc["transactions"] : false,
      catalogue: data.containsKey("catalogue") ? doc["catalogue"] : false,
      multiuser: data.containsKey("multiuser") ? doc["multiuser"] : false,
      editAccount: data.containsKey("editAccount") ? doc["editAccount"] : false,

    );
    
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "inactivate": inactivate,
    "account": account,
    "email": email,
    'name':name,
    "superAdmin": superAdmin,
    "admin": admin,
    'creation': creation,
    'lastUpdate': lastUpdate,
    'startTime': startTime,
    'endTime': endTime,
    'daysOfWeek': daysOfWeek,
    // permisos personalizados
    "personalized": personalized, 
    "arqueo": arqueo,
    "historyArqueo": historyArqueo,
    "transactions": transactions,
    "catalogue": catalogue,
    "multiuser": multiuser,
    "editAccount": editAccount,
  };

  factory AdminModel.fromMap(Map data) {
    return AdminModel(
      id: data['id'] ?? '',
      inactivate: data['inactivate'] ?? false,
      account: data['account'] ?? '',
      email: data['email'] ?? '',
      name:data['name'] ?? '',
      superAdmin: data['superAdmin'] ?? false,
      admin: data['admin'] ?? false,
      personalized: data['personalized'] ?? false,
      creation: data['creation'] ?? Timestamp.now(),
      lastUpdate: data['lastUpdate'] ?? Timestamp.now(),
      startTime: data['startTime'] ?? {},
      endTime: data['endTime'] ?? {},
      daysOfWeek: data['daysOfWeek'] ?? [],
      // ... 
      arqueo: data['arqueo'] ?? false,
      historyArqueo: data['historyArqueo'] ?? false,
      transactions: data['transactions'] ?? false,
      catalogue: data['catalogue'] ?? false,
      multiuser: data['multiuser'] ?? false,
      editAccount: data['editAccount'] ?? false,
    );
  }

  AdminModel.fromDocumentSnapshot({required DocumentSnapshot documentSnapshot}) { 
    // get
    late Map data= {};
    if (documentSnapshot.data() != null) {data = documentSnapshot.data() as Map; }

    //  set
    id = data.containsKey('id') ? data['id'] : documentSnapshot.id;
    inactivate = data.containsKey('inactivate') ? data['inactivate'] : false;
    account = data.containsKey('account') ? data['account'] : documentSnapshot.id;
    email = data.containsKey('email') ? data['email'] : '';
    name = data.containsKey('name') ? data['name'] : '';
    superAdmin = data.containsKey('superAdmin') ? data['superAdmin'] : false;
    admin = data.containsKey('admin') ? data['admin'] : false;
    personalized = data.containsKey('personalized') ? data['personalized'] : false;
    creation = data.containsKey('creation') ? data['creation'] : Timestamp.now();
    lastUpdate = data.containsKey('lastUpdate') ? data['lastUpdate'] : Timestamp.now();
    startTime = data.containsKey('startTime') ? data['startTime'] : {};
    endTime = data.containsKey('endTime') ? data['endTime'] : {};
    daysOfWeek = data.containsKey('daysOfWeek') ? data['daysOfWeek'] : [];
    // ... 
    arqueo = data.containsKey('arqueo') ? data['arqueo'] : false;
    historyArqueo = data.containsKey('historyArqueo') ? data['historyArqueo'] : false;
    transactions = data.containsKey('transactions') ? data['transactions'] : false;
    catalogue = data.containsKey('catalogue') ? data['catalogue'] : false;
    multiuser = data.containsKey('multiuser') ? data['multiuser'] : false;
    editAccount = data.containsKey('editAccount') ? data['editAccount'] : false;
  }

  AdminModel copyWith({ 
    bool? inactivate,
    String? id,
    String? account,
    String? email,
    String? name,
    bool? superAdmin,
    bool? admin,
    bool? personalized,
    Timestamp? creation,
    Timestamp? lastUpdate,
    Map<String,dynamic>? startTime,
    Map<String,dynamic>? endTime,
    List<String>? daysOfWeek,
    // ...
    bool? sell,
    bool? arqueo,
    bool? historyArqueo,
    bool? transactions,
    bool? catalogue,
    bool? multiuser,
    bool? editAccount,
  }) {
    return AdminModel(
      inactivate: inactivate ?? this.inactivate,
      id: id ?? this.id,
      account: account ?? this.account,
      email: email ?? this.email,
      name: name ?? this.name,
      superAdmin: superAdmin ?? this.superAdmin,
      admin: admin ?? this.admin,
      personalized: personalized ?? this.personalized,
      creation: creation ?? this.creation,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      // ... 
      arqueo: arqueo ?? this.arqueo,
      historyArqueo: historyArqueo ?? this.historyArqueo,
      transactions: transactions ?? this.transactions,
      catalogue: catalogue ?? this.catalogue,
      multiuser: multiuser ?? this.multiuser,
      editAccount: editAccount ?? this.editAccount,
    );
  }


  String get getAccessTimeFormat {
    // devuelve la hora de acceso del usuario con formato de 24 horas [hh:mm] 
    if (startTime.isEmpty && endTime.isEmpty) return "";
    
    return "${startTime['hour'].toString().padLeft(2, '0')}:${startTime['minute'].toString().padLeft(2, '0')} - ${endTime['hour'].toString().padLeft(2, '0')}:${endTime['minute'].toString().padLeft(2, '0')}";
  }
  bool get hasAccessHour{
    // var
    DateTime now = DateTime.now(); 
    // devuelve verdadero si el usuario tiene acceso a la cuenta dentro del horario establecido
    if (startTime.isEmpty || endTime.isEmpty) return false; 
    DateTime start = DateTime(now.year, now.month, now.day, startTime['hour'], startTime['minute']);
    DateTime end = DateTime(now.year, now.month, now.day, endTime['hour'], endTime['minute']);
    return now.isAfter(start) && now.isBefore(end); 
  } 
  bool get hasAccessDay{
    // var
    DateTime now = DateTime.now(); 
    bool dayAccess = false;  
    // devuelve verdadero si el usuario tiene acceso a la cuenta en el día de la semana establecido 
    String dayName = DateFormat('EEEE', 'en_US').format(now).toString().toLowerCase().replaceAll(' ', '');  
    for (var day in daysOfWeek) {  
      if (day.toString().toLowerCase().replaceAll(' ', '') == dayName.toString().toLowerCase().replaceAll(' ', '') ) {
        dayAccess = true; 
      }
    }

    return dayAccess;
  } 
  List get getDaysOfWeek{
    // devuelve los días de la semana en español
    List<String> days = [];
    for (var day in daysOfWeek) {
      days.add(translateDay(day: day));
    }
    return days;
  }
  String translateDay({required String day}){
    // devuelve el dia de la semana en español
    switch (day) {
      case 'monday':
        return 'Lunes';
      case 'tuesday':
        return 'Martes';
      case 'wednesday':
        return 'Miércoles';
      case 'thursday':
        return 'Jueves';
      case 'friday':
        return 'Viernes';
      case 'saturday':
        return 'Sábado';
      case 'sunday':
        return 'Domingo';
      default:
        return '';
    }
  }
}

class ProfileAccountModel {
  // Informacion de la cuenta
  late Timestamp creation;
  String id = "";
  String username = "";
  String image = "";
  String name = "";
  String currencySign = "\$";
  bool blockingAccount = false;
  String blockingMessage = "";
  bool verifiedAccount = false;
  String pin = '';
  bool trial = false;
  late Timestamp trialStart;
  late Timestamp trialEnd;
  String countrycode = ""; // codigo de pais
  String country = ""; // pais
  String province = ""; // provincia
  String town = ""; // ciudad

  ProfileAccountModel({
    this.id = "",
    this.countrycode = "",
    this.username = '',
    this.image = "",
    this.name = "",
    this.currencySign = "\$",
    this.blockingAccount = false,
    this.blockingMessage = "",
    this.verifiedAccount = false,
    this.pin = '',
    this.country = "",
    this.province = "",
    this.town = "",
    Timestamp? creation,
    this.trial = false,
    Timestamp? trialStart,
    Timestamp? trialEnd,
  }) {
    this.creation = creation ?? Timestamp.now();
    this.trialStart = trialStart ?? Timestamp.now();
    this.trialEnd = trialEnd ?? Timestamp.now();
  }
  ProfileAccountModel copyWith({
    // account info
    // informacion de cuenta
    // location
    // data user creation
    String? id,
    bool? subscribed,
    String? countrycode,
    String? username,
    String? image,
    String? name, 
    String? currencySign,
    bool? blockingAccount,
    String? blockingMessage,
    bool? verifiedAccount, 
    String? pin,
    String? country,
    String? province,
    String? town, 
    Timestamp? creation,
  }) {
    return ProfileAccountModel(
      // account info
      // informacion de cuenta
      // location
      // data user creation
      id: id ?? this.id, 
      countrycode: countrycode ?? this.countrycode,
      username: username ?? this.username,
      image: image ?? this.image,
      name: name ?? this.name, 
      currencySign: currencySign ?? this.currencySign,
      blockingAccount: blockingAccount ?? this.blockingAccount,
      blockingMessage: blockingMessage ?? this.blockingMessage,
      verifiedAccount: verifiedAccount ?? this.verifiedAccount, 
      pin: pin ?? this.pin,
      country: country ?? this.country,
      province: province ?? this.province,
      town: town ?? this.town, 
      creation: creation ?? this.creation,
      trial: trial,
      trialStart: trialStart,
      trialEnd: trialEnd,  
    );
  }

  ProfileAccountModel.fromMap(Map data) {
    id = data['id'];
    username = data['username']; 
    image =data.containsKey('image') ? data['image'] : data['imagen_perfil'] ?? '';
    name = data.containsKey('name') ? data['name'] : data['nombre_negocio']; 
    creation = data.containsKey('creation')? data['creation']: data['timestamp_creation']?? Timestamp.now();
    currencySign = data.containsKey('currencySign')
        ? data['currencySign']
        : data['signo_moneda'] ?? "\$";
    blockingAccount = data.containsKey('blockingAccount')
        ? data['blockingAccount']
        : data['bloqueo'];
    blockingMessage = data.containsKey('blockingMessage')
        ? data['blockingMessage']
        : data['mensaje_bloqueo'];
    verifiedAccount = data.containsKey('verifiedAccount')
        ? data['verifiedAccount']
        : data['cuenta_verificada'];
    pin =  data.containsKey('pin') ? data['pin'] : '';
    countrycode = data.containsKey('countrycode')
        ? data['countrycode']
        : data['codigo_pais']; 
    town = data.containsKey('town') ? data['town'] : data['ciudad'];
    province =
        data.containsKey('province') ? data['province'] : data['provincia'];
    country = data.containsKey('country') ? data['country'] : data['pais'];
    trial = data.containsKey('trial') ? data['trial'] : false;
    trialStart = data.containsKey('trialStart') ? data['trialStart'] : Timestamp.now();
    trialEnd = data.containsKey('trialEnd') ? data['trialEnd'] : Timestamp.now();
  }
  Map<String, dynamic> toJson() => {
        "id": id,
        // "subscribed": subscribed,
        "username": username,
        "image": image,
        "name": name, 
        "creation": creation,
        "currencySign": currencySign,
        "blockingAccount": blockingAccount,
        "blockingMessage": blockingMessage,
        "verifiedAccount": verifiedAccount,
        "pin": pin,
        "countrycode": countrycode,
        "country": country,
        "province": province,
        "town": town, 
        "trial": trial,
        "trialStart": trialStart,
        "trialEnd": trialEnd,
      };

  ProfileAccountModel.fromDocumentSnapshot( {required DocumentSnapshot documentSnapshot}) {
    // get
    late Map data= {};
    if (documentSnapshot.data() != null) {data = documentSnapshot.data() as Map; }

    //  set
    creation = data["creation"]??Timestamp.now(); 
    id = data.containsKey('id') ? data['id'] : documentSnapshot.id;
    username = data["username"] ?? '';
    image = data.containsKey('image') ? data['image'] : data["imagen_perfil"] ?? '';
    name = data.containsKey('name')
        ? data['name']
        : data["nombre_negocio"] ?? 'null'; 
    currencySign = data.containsKey('currencySign')
        ? data['currencySign']
        : data["signo_moneda"] ?? '';
    blockingAccount = data.containsKey('blockingAccount')
        ? data['blockingAccount']
        : data["bloqueo"] ?? false;
    blockingMessage = data.containsKey('blockingMessage')
        ? data['blockingMessage']
        : data["mensaje_bloqueo"] ?? '';
    verifiedAccount = data.containsKey('verifiedAccount')
        ? data['verifiedAccount']
        : data["cuenta_verificada"] ?? false;
    pin = data.containsKey('pin') ? data['pin'] : '';
    countrycode = data.containsKey('countrycode')
        ? data['countrycode']
        : data["codigo_pais"] ?? '';
    country =
        data.containsKey('country') ? data['country'] : data["pais"] ?? '';
    province = data.containsKey('province')
        ? data['province']
        : data["provincia"] ?? '';
    town = data.containsKey('town') ? data['town'] : data["ciudad"] ?? ''; 
    trial = data.containsKey('trial') ? data['trial'] : false;
    trialStart = data.containsKey('trialStart') ? data['trialStart'] : Timestamp.now();
    trialEnd = data.containsKey('trialEnd') ? data['trialEnd'] : Timestamp.now();
  }
}
