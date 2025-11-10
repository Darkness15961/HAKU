// --- MAPA DE RUTAS (GPS) DE LA APP ---
//
// 1. (ACOMPLADO): Se importa 'admin_dashboard_pagina.dart'.
// 2. (ACOMPLADO): La ruta '/panel-admin' ahora apunta al Dashboard.
// 3. (ACOMPLADO): Se crea la nueva ruta '/admin/gestion-guias'.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- Importamos la key global ---
import 'package:xplore_cusco/caracteristicas/mapa/presentacion/vista_modelos/mapa_vm.dart' as mapa_vm;

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

// 4. Pantallas del Menú 4 (Perfil)
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/mis_lugares_favoritos_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/mis_rutas_inscritas_pagina.dart';

// --- ¡IMPORTACIONES DE ADMIN ACOMPLADAS! ---
// (Importamos el Dashboard)
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_dashboard_pagina.dart';
// (Importamos la página de Gestión de Guías - ¡LA QUE RENOMBRAMOS!)
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_guias_pagina.dart';
// --- FIN DE IMPORTACIONES ---


// --- Importaciones de "Recetas" (Entidades) ---
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/provincia.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';
import 'package:xplore_cusco/caracteristicas/rutas/dominio/entidades/ruta.dart';

class AppRutas {
  // Creamos el "GPS" (router) con su "mapa" (routes)
  static final router = GoRouter(

    navigatorKey: mapa_vm.navigatorKey,
    initialLocation: '/',

    routes: [
      // ... (Rutas de Menú 1, Auth, Menú 2 y Perfil se mantienen igual)
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
          // (A futuro: acoplar la lógica de 'extra' para editar)
          final ruta = state.extra as Ruta?;
          return CrearRutaPagina(ruta: ruta); // Pasar la ruta (si existe)
        },
      ),
      GoRoute(
        path: '/solicitar-guia',
        builder: (BuildContext context, GoRouterState state) {
          return const SolicitarGuiaPagina();
        },
      ),
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

      // --- ¡RUTAS DE ADMIN ACOMPLADAS! ---
      GoRoute(
        path: '/panel-admin', // (La ruta principal del Admin)
        builder: (BuildContext context, GoRouterState state) {
          return const AdminDashboardPagina(); // <-- Apunta al Dashboard
        },
      ),
      GoRoute(
        path: '/admin/gestion-guias', // (La sub-página de guías)
        builder: (BuildContext context, GoRouterState state) {
          return const AdminGestionGuiasPagina(); // <-- Apunta al archivo renombrado
        },
      ),
      // --- FIN DE RUTAS DE ADMIN ---
    ],
  );
}