import 'package:flutter/material.dart';

/// Retorna true si el ancho de pantalla es menor a 700px (modo móvil).
bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 700;
