// --- MAPA DE RUTAS (GPS) DE LA APP ---
//
// ¡VERSIÓN FINAL!
// Le hemos "enseñado" las dos nuevas "direcciones"
// para "/mis-favoritos" y "/mis-rutas".

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
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/solicitar_guia_pagina.dart';

// 3. Pantallas del Menú 2 (Rutas)
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/detalle_ruta_pagina.dart';
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/crear_ruta_pagina.dart';

// --- ¡NUEVAS IMPORTACIONES DEL PASO 4! ---
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/mis_lugares_favoritos_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/mis_rutas_inscritas_pagina.dart';
// --- FIN DE NUEVAS IMPORTACIONES ---


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
          // (Recuerda que esta página también necesita
          // una lógica de "editar" si state.extra no es nulo)
          return const CrearRutaPagina();
        },
      ),

      GoRoute(
        path: '/solicitar-guia',
        builder: (BuildContext context, GoRouterState state) {
          return const SolicitarGuiaPagina();
        },
      ),

      // --- ¡NUEVAS RUTAS DEL PASO 4! ---
      GoRoute(
        path: '/mis-favoritos',
        builder: (BuildContext context, GoRouterState state) {
          return const MisLugaresFavoritosPagina();
        },
      ),
      GoRoute(
        path: '/mis-rutas',
        builder: (BuildContext context, GoRouterState state) {
          return const MisRutasInscritasPagina();
        },
      ),
      // --- FIN DE LA NUEVA RUTA ---
    ],
  );
}