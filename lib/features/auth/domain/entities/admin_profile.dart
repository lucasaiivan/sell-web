/// Entidad de dominio: Perfil de administrador
///
/// Representa a un usuario administrador con permisos y configuraciones específicas.
/// Esta es una entidad pura de dominio sin dependencias externas (solo Dart).
///
/// **Propiedades principales:**
/// - `id`: ID de autenticación del usuario
/// - `account`: ID de la cuenta administrada
/// - `email`: Email del usuario
/// - `name`: Nombre del usuario
/// - `superAdmin`: Indica si es el super administrador (creador de la cuenta)
/// - `admin`: Indica si tiene permisos de administrador
///
/// **Permisos personalizados:**
/// - `arqueo`: Crear arqueo de caja
/// - `historyArqueo`: Ver y eliminar registros de arqueo
/// - `transactions`: Ver y eliminar transacciones
/// - `catalogue`: Gestionar catálogo de productos
/// - `multiuser`: Gestionar usuarios de la cuenta
/// - `editAccount`: Editar configuración de la cuenta
///
/// **Configuración de acceso:**
/// - `startTime`: Hora de inicio de acceso (Map con 'hour' y 'minute')
/// - `endTime`: Hora de fin de acceso
/// - `daysOfWeek`: Días de la semana con acceso habilitado
class AdminProfile {
  final String id;
  final bool inactivate;
  final String account;
  final String email;
  final String name;
  final bool superAdmin;
  final bool admin;
  final bool personalized;
  final DateTime creation;
  final DateTime lastUpdate;
  final Map<String, dynamic> startTime;
  final Map<String, dynamic> endTime;
  final List<String> daysOfWeek;
  
  // Permisos personalizados
  final bool arqueo;
  final bool historyArqueo;
  final bool transactions;
  final bool catalogue;
  final bool multiuser;
  final bool editAccount;

  const AdminProfile({
    this.id = "",
    this.inactivate = false,
    this.account = "",
    this.email = '',
    this.name = '',
    this.superAdmin = false,
    this.admin = false,
    this.personalized = false,
    required this.creation,
    required this.lastUpdate,
    this.startTime = const {},
    this.endTime = const {},
    this.daysOfWeek = const [],
    this.arqueo = false,
    this.historyArqueo = false,
    this.transactions = false,
    this.catalogue = false,
    this.multiuser = false,
    this.editAccount = false,
  });

  /// Copia la entidad con los valores proporcionados
  AdminProfile copyWith({
    String? id,
    bool? inactivate,
    String? account,
    String? email,
    String? name,
    bool? superAdmin,
    bool? admin,
    bool? personalized,
    DateTime? creation,
    DateTime? lastUpdate,
    Map<String, dynamic>? startTime,
    Map<String, dynamic>? endTime,
    List<String>? daysOfWeek,
    bool? arqueo,
    bool? historyArqueo,
    bool? transactions,
    bool? catalogue,
    bool? multiuser,
    bool? editAccount,
  }) {
    return AdminProfile(
      id: id ?? this.id,
      inactivate: inactivate ?? this.inactivate,
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
      arqueo: arqueo ?? this.arqueo,
      historyArqueo: historyArqueo ?? this.historyArqueo,
      transactions: transactions ?? this.transactions,
      catalogue: catalogue ?? this.catalogue,
      multiuser: multiuser ?? this.multiuser,
      editAccount: editAccount ?? this.editAccount,
    );
  }

  /// Obtiene la hora de acceso formateada (HH:MM - HH:MM)
  String get accessTimeFormat {
    if (startTime.isEmpty && endTime.isEmpty) return "";

    final startHour = startTime['hour']?.toString().padLeft(2, '0') ?? '00';
    final startMinute = startTime['minute']?.toString().padLeft(2, '0') ?? '00';
    final endHour = endTime['hour']?.toString().padLeft(2, '0') ?? '00';
    final endMinute = endTime['minute']?.toString().padLeft(2, '0') ?? '00';

    return "$startHour:$startMinute - $endHour:$endMinute";
  }

  /// Verifica si el usuario tiene acceso en la hora actual
  bool get hasAccessHour {
    if (startTime.isEmpty || endTime.isEmpty) return false;

    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
      startTime['hour'] as int? ?? 0,
      startTime['minute'] as int? ?? 0,
    );
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      endTime['hour'] as int? ?? 0,
      endTime['minute'] as int? ?? 0,
    );

    return now.isAfter(start) && now.isBefore(end);
  }

  /// Verifica si el usuario tiene acceso en el día actual
  bool get hasAccessDay {
    if (daysOfWeek.isEmpty) return false;

    final now = DateTime.now();
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final currentDay = dayNames[now.weekday - 1];

    return daysOfWeek.any((day) => 
      day.toLowerCase().replaceAll(' ', '') == currentDay
    );
  }

  /// Verifica si hay configuración de horarios de acceso
  bool get hasAccessTimeConfiguration {
    return startTime.isNotEmpty || endTime.isNotEmpty;
  }

  /// Obtiene los días de la semana en español
  List<String> get daysOfWeekInSpanish {
    return daysOfWeek.map((day) => _translateDay(day)).toList();
  }

  /// Traduce un día de la semana al español
  String _translateDay(String day) {
    final translations = {
      'monday': 'Lunes',
      'tuesday': 'Martes',
      'wednesday': 'Miércoles',
      'thursday': 'Jueves',
      'friday': 'Viernes',
      'saturday': 'Sábado',
      'sunday': 'Domingo',
    };
    return translations[day.toLowerCase()] ?? '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          inactivate == other.inactivate &&
          account == other.account &&
          email == other.email &&
          name == other.name &&
          superAdmin == other.superAdmin &&
          admin == other.admin;

  @override
  int get hashCode =>
      id.hashCode ^
      inactivate.hashCode ^
      account.hashCode ^
      email.hashCode ^
      name.hashCode ^
      superAdmin.hashCode ^
      admin.hashCode;

  @override
  String toString() {
    return 'AdminProfile(id: $id, email: $email, name: $name, superAdmin: $superAdmin, admin: $admin)';
  }
}
