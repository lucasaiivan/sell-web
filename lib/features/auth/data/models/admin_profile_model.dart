import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/admin_profile.dart';

/// Modelo de datos: Perfil de administrador
///
/// Extiende [AdminProfile] agregando lógica de serialización para Firestore.
class AdminProfileModel extends AdminProfile {
  const AdminProfileModel({
    super.id,
    super.inactivate,
    super.inactivateNote,
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
    super.permissions,
    super.lastAccountCreation,
  });

  factory AdminProfileModel.fromDocument(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    
    // 1. Cargar lista de permisos existentes si la hay
    List<String> permissions = data.containsKey("permissions")
        ? List<String>.from(data["permissions"])
        : [];

    // 2. Migrar campos booleanos antiguos a la lista de permisos si no existen en la lista
    if (data.containsKey("arqueo") && data["arqueo"] == true) {
      if (!permissions.contains(AdminPermission.createCashCount.name)) {
        permissions.add(AdminPermission.createCashCount.name);
      }
    }
    if (data.containsKey("historyArqueo") && data["historyArqueo"] == true) {
      if (!permissions.contains(AdminPermission.viewCashCountHistory.name)) {
        permissions.add(AdminPermission.viewCashCountHistory.name);
      }
    }
    if (data.containsKey("transactions") && data["transactions"] == true) {
      if (!permissions.contains(AdminPermission.manageTransactions.name)) {
        permissions.add(AdminPermission.manageTransactions.name);
      }
    }
    if (data.containsKey("catalogue") && data["catalogue"] == true) {
      if (!permissions.contains(AdminPermission.manageCatalogue.name)) {
        permissions.add(AdminPermission.manageCatalogue.name);
      }
    }
    if (data.containsKey("multiuser") && data["multiuser"] == true) {
      if (!permissions.contains(AdminPermission.manageUsers.name)) {
        permissions.add(AdminPermission.manageUsers.name);
      }
    }
    if (data.containsKey("editAccount") && data["editAccount"] == true) {
      if (!permissions.contains(AdminPermission.manageAccount.name)) {
        permissions.add(AdminPermission.manageAccount.name);
      }
    }

    return AdminProfileModel(
      id: doc.id,
      inactivate: data.containsKey("inactivate") ? doc["inactivate"] : false,
      inactivateNote:
          data.containsKey("inactivateNote") ? doc["inactivateNote"] : '',
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
      startTime: data.containsKey("startTime")
          ? Map<String, dynamic>.from(doc["startTime"])
          : {},
      endTime: data.containsKey("endTime")
          ? Map<String, dynamic>.from(doc["endTime"])
          : {},
      daysOfWeek: data.containsKey("daysOfWeek")
          ? List<String>.from(doc["daysOfWeek"])
          : [],
      permissions: permissions,
      lastAccountCreation: data.containsKey("lastAccountCreation")
          ? (doc["lastAccountCreation"] is Timestamp
              ? (doc["lastAccountCreation"] as Timestamp).toDate()
              : doc["lastAccountCreation"] as DateTime?)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "inactivate": inactivate,
        "inactivateNote": inactivateNote,
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
        // Guardar la nueva lista de permisos
        "permissions": permissions,
        // Guardar lastAccountCreation si existe
        if (lastAccountCreation != null)
          "lastAccountCreation": Timestamp.fromDate(lastAccountCreation!),
        // Mantener compatibilidad escribiendo los booleanos calculados (getters)
        "arqueo": arqueo,
        "historyArqueo": historyArqueo,
        "transactions": transactions,
        "catalogue": catalogue,
        "multiuser": multiuser,
        "editAccount": editAccount,
      };

  factory AdminProfileModel.fromMap(Map data) {
    List<String> permissions = data.containsKey("permissions")
        ? List<String>.from(data["permissions"])
        : [];

    // Migración manual para fromMap también
    if ((data['arqueo'] ?? false) && !permissions.contains(AdminPermission.createCashCount.name)) {
      permissions.add(AdminPermission.createCashCount.name);
    }
    if ((data['historyArqueo'] ?? false) && !permissions.contains(AdminPermission.viewCashCountHistory.name)) {
      permissions.add(AdminPermission.viewCashCountHistory.name);
    }
    if ((data['transactions'] ?? false) && !permissions.contains(AdminPermission.manageTransactions.name)) {
      permissions.add(AdminPermission.manageTransactions.name);
    }
    if ((data['catalogue'] ?? false) && !permissions.contains(AdminPermission.manageCatalogue.name)) {
      permissions.add(AdminPermission.manageCatalogue.name);
    }
    if ((data['multiuser'] ?? false) && !permissions.contains(AdminPermission.manageUsers.name)) {
      permissions.add(AdminPermission.manageUsers.name);
    }
    if ((data['editAccount'] ?? false) && !permissions.contains(AdminPermission.manageAccount.name)) {
      permissions.add(AdminPermission.manageAccount.name);
    }

    return AdminProfileModel(
      id: data['id'] ?? '',
      inactivate: data['inactivate'] ?? false,
      inactivateNote: data['inactivateNote'] ?? '',
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
      startTime: data['startTime'] != null
          ? Map<String, dynamic>.from(data['startTime'])
          : {},
      endTime: data['endTime'] != null
          ? Map<String, dynamic>.from(data['endTime'])
          : {},
      daysOfWeek: data['daysOfWeek'] != null
          ? List<String>.from(data['daysOfWeek'])
          : [],
      permissions: permissions,
      lastAccountCreation: data['lastAccountCreation'] is String
          ? DateTime.parse(data['lastAccountCreation'])
          : (data['lastAccountCreation'] as Timestamp?)?.toDate(),
    );
  }

  factory AdminProfileModel.fromEntity(AdminProfile entity) {
    return AdminProfileModel(
      id: entity.id,
      inactivate: entity.inactivate,
      inactivateNote: entity.inactivateNote,
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
      permissions: entity.permissions,
      lastAccountCreation: entity.lastAccountCreation,
    );
  }
}
