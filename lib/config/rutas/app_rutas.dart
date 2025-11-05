// --- MAPA DE RUTAS (GPS) DE LA APP ---
//
// Esta es la versión ACTUALIZADA de nuestro "GPS".
// Le hemos "enseñado" la nueva "dirección"
// para "/solicitar-guia".

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- Importaciones de "Edificios" (Pantallas) ---

// 1. Pantallas del Menú 1 (Inicio)
import 'package:xplore_cusco/caracteristicas/splash/presentacion/paginas/splash_pagina.dart';
import 'package:xplore_cusco/caracteristicas/navegacion/presentacion/paginas/navegacion_principal.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/provincia_lugares_pagina.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/detalle_lugar_pagina.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/comentarios_pagina.dart';

// 2. Pantallas de Autenticación
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/login_pagina.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/registro_pagina.dart';
// --- ¡NUEVA IMPORTACIÓN! (Paso 4 - Bloque 5) ---
//    (Dart se quejará de este import hasta
//    que creemos el archivo en el siguiente paso)
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/solicitar_guia_pagina.dart';
// --- FIN DE NUEVA IMPORTACIÓN ---

// 3. Pantallas del Menú 2 (Rutas)
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/detalle_ruta_pagina.dart';
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/crear_ruta_pagina.dart';


// --- Importaciones de "Recetas" (Entidades) ---
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/provincia.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';
import 'package:xplore_cusco/caracteristicas/rutas/dominio/entidades/ruta.dart';

class AppRutas {
  // Creamos el "GPS" (router) con su "mapa" (routes)
  static final router = GoRouter(
    initialLocation: '/', // La app siempre arranca en el Splash

    // El "mapa" con la lista de todas las "direcciones"
    routes: [
      // --- Direcciones del Menú 1 (Completas) ---
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashPagina();
        },
      ),
      GoRoute(
        path: '/navegacion',
        builder: (BuildContext context, GoRouterState state) {
          return const NavegacionPrincipal();
        },
      ),
      GoRoute(
        path: '/provincia',
        builder: (BuildContext context, GoRouterState state) {
          final provincia = state.extra as Provincia;
          return ProvinciaLugaresPagina(provincia: provincia);
        },
      ),
      GoRoute(
        path: '/detalle-lugar',
        builder: (BuildContext context, GoRouterState state) {
          final lugar = state.extra as Lugar;
          return DetalleLugarPagina(lugar: lugar);
        },
      ),
      GoRoute(
        path: '/comentarios',
        builder: (BuildContext context, GoRouterState state) {
          return const ComentariosPagina();
        },
      ),

      // --- Direcciones de Autenticación (Completas) ---
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginPagina();
        },
      ),
      GoRoute(
        path: '/registro',
        builder: (BuildContext context, GoRouterState state) {
          return const RegistroPagina();
        },
      ),

      // --- Direcciones del Menú 2 (Rutas - Completas) ---
      GoRoute(
        path: '/detalle-ruta',
        builder: (BuildContext context, GoRouterState state) {
          final ruta = state.extra as Ruta;
          return DetalleRutaPagina(ruta: ruta);
        },
      ),
      GoRoute(
        path: '/crear-ruta',
        builder: (BuildContext context, GoRouterState state) {
          return const CrearRutaPagina();
        },
      ),

      // --- ¡NUEVA RUTA AÑADIDA! (Paso 4 - Bloque 5) ---
      //
      // --- Dirección de Solicitud de Guía ---

      // Dirección 10: Formulario de Solicitud (/solicitar-guia)
      GoRoute(
        path: '/solicitar-guia',
        builder: (BuildContext context, GoRouterState state) {
          // El "edificio" en esta dirección es el formulario
          // para que el Turista se convierta en Guía.
          // (Dará un error hasta que creemos el archivo)
          return const SolicitarGuiaPagina();
        },
      ),
      // --- FIN DE LA NUEVA RUTA ---
    ],
  );
}

