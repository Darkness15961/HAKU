import 'package:flutter/material.dart';
import '../../caracteristicas/splash/presentacion/paginas/splash_pagina.dart';
import '../../caracteristicas/navegacion/presentacion/paginas/navegacion_principal.dart';

class AppRutas {
  static const String splash = '/';
  static const String navegacion = '/navegacion';

  static Map<String, WidgetBuilder> rutas = {
    splash: (context) => const SplashPagina(),
    navegacion: (context) => const NavegacionPrincipal(),
  };
}
