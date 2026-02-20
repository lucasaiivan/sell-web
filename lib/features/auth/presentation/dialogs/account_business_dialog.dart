import 'package:flutter/material.dart';
import 'package:sellweb/features/auth/domain/entities/account_profile.dart';
import 'package:sellweb/features/auth/domain/entities/admin_profile.dart';
import 'package:sellweb/features/auth/presentation/views/account_business_view.dart';

/// Navega a la pantalla de crear o editar cuenta de negocio.
/// Mantenemos el nombre de la función para compatibilidad, pero ahora hace un push.
Future<void> showAccountBusinessDialog({
  required BuildContext context,
  required AdminProfile currentAdmin,
  AccountProfile? account,
}) async {



  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => AccountBusinessView(
        admin: currentAdmin,
        account: account,
      ),
    ),
  );
}

