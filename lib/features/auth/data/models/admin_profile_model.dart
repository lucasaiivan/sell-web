import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/admin_profile.dart';

/// Modelo de datos: Perfil de administrador
///
/// Extiende [AdminProfile] agregando lógica de serialización para Firestore.
class AdminProfileModel extends AdminProfile {
  const AdminProfileModel({
    super.id,
    super.inactivate,
    super.account,
    super.email,
    super.name,
    super.superAdmin,
    super.admin,
    super.personalized,
    required super.creation,
    required super.lastUpdate,
    super.startTime,
    super.endTime,
    super.daysOfWeek,
    super.arqueo,
    super.historyArqueo,
    super.transactions,
    super.catalogue,
    super.multiuser,
    super.editAccount,
  });

  factory AdminProfileModel.fromDocument(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return AdminProfileModel(
      id: doc.id,
      inactivate: data.containsKey("inactivate") ? doc["inactivate"] : false,
      account: doc["account"],
      email: data.containsKey("email") ? doc["email"] : '',
      name: data.containsKey('name') ? doc['name'] : '',
      superAdmin: data.containsKey("superAdmin") ? doc["superAdmin"] : false,
      admin: data.containsKey("admin") ? doc["admin"] : false,
      personalized:
          data.containsKey("personalized") ? doc["personalized"] : false,
      creation: data.containsKey("creation")
          ? (doc["creation"] is Timestamp
              ? (doc["creation"] as Timestamp).toDate()
              : doc["creation"] as DateTime)
          : DateTime.now(),
      lastUpdate: data.containsKey("lastUpdate")
          ? (doc["lastUpdate"] is Timestamp
              ? (doc["lastUpdate"] as Timestamp).toDate()
              : doc["lastUpdate"] as DateTime)
          : DateTime.now(),
      startTime: data.containsKey("startTime") ? Map<String, dynamic>.from(doc["startTime"]) : {},
      endTime: data.containsKey("endTime") ? Map<String, dynamic>.from(doc["endTime"]) : {},
      daysOfWeek: data.containsKey("daysOfWeek") ? List<String>.from(doc["daysOfWeek"]) : [],
      arqueo: data.containsKey("arqueo") ? doc["arqueo"] : false,
      historyArqueo:
          data.containsKey("historyArqueo") ? doc["historyArqueo"] : false,
      transactions:
          data.containsKey("transactions") ? doc["transactions"] : false,
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
        'name': name,
        "superAdmin": superAdmin,
        "admin": admin,
        'creation': Timestamp.fromDate(creation),
        'lastUpdate': Timestamp.fromDate(lastUpdate),
        'startTime': startTime,
        'endTime': endTime,
        'daysOfWeek': daysOfWeek,
        "personalized": personalized,
        "arqueo": arqueo,
        "historyArqueo": historyArqueo,
        "transactions": transactions,
        "catalogue": catalogue,
        "multiuser": multiuser,
        "editAccount": editAccount,
      };

  factory AdminProfileModel.fromMap(Map data) {
    return AdminProfileModel(
      id: data['id'] ?? '',
      inactivate: data['inactivate'] ?? false,
      account: data['account'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      superAdmin: data['superAdmin'] ?? false,
      admin: data['admin'] ?? false,
      personalized: data['personalized'] ?? false,
      creation: data['creation'] is String
          ? DateTime.parse(data['creation'])
          : (data['creation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdate: data['lastUpdate'] is String
          ? DateTime.parse(data['lastUpdate'])
          : (data['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: data['startTime'] != null ? Map<String, dynamic>.from(data['startTime']) : {},
      endTime: data['endTime'] != null ? Map<String, dynamic>.from(data['endTime']) : {},
      daysOfWeek: data['daysOfWeek'] != null ? List<String>.from(data['daysOfWeek']) : [],
      arqueo: data['arqueo'] ?? false,
      historyArqueo: data['historyArqueo'] ?? false,
      transactions: data['transactions'] ?? false,
      catalogue: data['catalogue'] ?? false,
      multiuser: data['multiuser'] ?? false,
      editAccount: data['editAccount'] ?? false,
    );
  }

  factory AdminProfileModel.fromEntity(AdminProfile entity) {
    return AdminProfileModel(
      id: entity.id,
      inactivate: entity.inactivate,
      account: entity.account,
      email: entity.email,
      name: entity.name,
      superAdmin: entity.superAdmin,
      admin: entity.admin,
      personalized: entity.personalized,
      creation: entity.creation,
      lastUpdate: entity.lastUpdate,
      startTime: entity.startTime,
      endTime: entity.endTime,
      daysOfWeek: entity.daysOfWeek,
      arqueo: entity.arqueo,
      historyArqueo: entity.historyArqueo,
      transactions: entity.transactions,
      catalogue: entity.catalogue,
      multiuser: entity.multiuser,
      editAccount: entity.editAccount,
    );
  }
}
