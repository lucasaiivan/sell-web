import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/account_profile.dart';

/// Modelo de datos: Perfil de cuenta comercial
///
/// Extiende [AccountProfile] agregando lógica de serialización para Firestore.
class AccountProfileModel extends AccountProfile {
  const AccountProfileModel({
    super.id,
    super.username,
    super.image,
    super.name,
    super.currencySign,
    super.blockingAccount,
    super.blockingMessage,
    super.verifiedAccount,
    super.pin,
    super.trial,
    required super.trialStart,
    required super.trialEnd,
    super.countrycode,
    super.country,
    super.province,
    super.town,
    required super.creation,
  });

  factory AccountProfileModel.fromDocument(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return AccountProfileModel(
      id: doc.id,
      username: data["username"] ?? '',
      image: data.containsKey('image')
          ? data['image']
          : data["imagen_perfil"] ?? '',
      name: data.containsKey('name')
          ? data['name']
          : data["nombre_negocio"] ?? 'null',
      currencySign: data.containsKey('currencySign')
          ? data['currencySign']
          : data["signo_moneda"] ?? '',
      blockingAccount: data.containsKey('blockingAccount')
          ? data['blockingAccount']
          : data["bloqueo"] ?? false,
      blockingMessage: data.containsKey('blockingMessage')
          ? data['blockingMessage']
          : data["mensaje_bloqueo"] ?? '',
      verifiedAccount: data.containsKey('verifiedAccount')
          ? data['verifiedAccount']
          : data["cuenta_verificada"] ?? false,
      pin: data.containsKey('pin') ? data['pin'] : '',
      countrycode: data.containsKey('countrycode')
          ? data['countrycode']
          : data["codigo_pais"] ?? '',
      country:
          data.containsKey('country') ? data['country'] : data["pais"] ?? '',
      province: data.containsKey('province')
          ? data['province']
          : data["provincia"] ?? '',
      town: data.containsKey('town') ? data['town'] : data["ciudad"] ?? '',
      trial: data.containsKey('trial') ? data['trial'] : false,
      trialStart: data.containsKey('trialStart')
          ? (data['trialStart'] is Timestamp
              ? (data['trialStart'] as Timestamp).toDate()
              : data['trialStart'] as DateTime)
          : DateTime.now(),
      trialEnd: data.containsKey('trialEnd')
          ? (data['trialEnd'] is Timestamp
              ? (data['trialEnd'] as Timestamp).toDate()
              : data['trialEnd'] as DateTime)
          : DateTime.now(),
      creation: data.containsKey("creation")
          ? (data["creation"] is Timestamp
              ? (data["creation"] as Timestamp).toDate()
              : data["creation"] as DateTime)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "image": image,
        "name": name,
        "creation": Timestamp.fromDate(creation),
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
        "trialStart": Timestamp.fromDate(trialStart),
        "trialEnd": Timestamp.fromDate(trialEnd),
      };

  factory AccountProfileModel.fromMap(Map data) {
    return AccountProfileModel(
      id: data['id'] ?? '',
      username: data['username'] ?? '',
      image: data.containsKey('image')
          ? data['image']
          : data['imagen_perfil'] ?? '',
      name: data.containsKey('name')
          ? data['name']
          : data['nombre_negocio'] ?? '',
      creation: data.containsKey('creation')
          ? (data['creation'] is String
              ? DateTime.parse(data['creation'])
              : (data['creation'] as Timestamp).toDate())
          : (data['timestamp_creation'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      currencySign: data.containsKey('currencySign')
          ? data['currencySign']
          : data['signo_moneda'] ?? "\$",
      blockingAccount: data.containsKey('blockingAccount')
          ? data['blockingAccount']
          : data['bloqueo'] ?? false,
      blockingMessage: data.containsKey('blockingMessage')
          ? data['blockingMessage']
          : data['mensaje_bloqueo'] ?? '',
      verifiedAccount: data.containsKey('verifiedAccount')
          ? data['verifiedAccount']
          : data['cuenta_verificada'] ?? false,
      pin: data.containsKey('pin') ? data['pin'] : '',
      countrycode: data.containsKey('countrycode')
          ? data['countrycode']
          : data['codigo_pais'] ?? '',
      town: data.containsKey('town') ? data['town'] : data['ciudad'] ?? '',
      province: data.containsKey('province')
          ? data['province']
          : data['provincia'] ?? '',
      country:
          data.containsKey('country') ? data['country'] : data['pais'] ?? '',
      trial: data.containsKey('trial') ? data['trial'] : false,
      trialStart: data.containsKey('trialStart')
          ? (data['trialStart'] as Timestamp).toDate()
          : Timestamp.now().toDate(),
      trialEnd: data.containsKey('trialEnd')
          ? (data['trialEnd'] as Timestamp).toDate()
          : Timestamp.now().toDate(),
    );
  }

  factory AccountProfileModel.fromEntity(AccountProfile entity) {
    return AccountProfileModel(
      id: entity.id,
      username: entity.username,
      image: entity.image,
      name: entity.name,
      currencySign: entity.currencySign,
      blockingAccount: entity.blockingAccount,
      blockingMessage: entity.blockingMessage,
      verifiedAccount: entity.verifiedAccount,
      pin: entity.pin,
      trial: entity.trial,
      trialStart: entity.trialStart,
      trialEnd: entity.trialEnd,
      countrycode: entity.countrycode,
      country: entity.country,
      province: entity.province,
      town: entity.town,
      creation: entity.creation,
    );
  }
}
