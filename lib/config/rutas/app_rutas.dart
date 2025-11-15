// --- MAPA DE RUTAS (GPS) DE LA APP (COMPLETO Y CORREGIDO) ---
//
// (...)
// 7. (¡CORREGIDO!): Añadida la importación y la ruta para el
//    nuevo sub-menú 'gestion-contenido'.
// 8. (¡AÑADIDO AHORA!): Añadidas las rutas para 'gestion-provincias' y 'crear-provincia'.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- Importamos la key global ---
import 'package:xplore_cusco/caracteristicas/mapa/presentacion/vista_modelos/mapa_vm.dart' as mapa_vm;

// --- Importaciones de "Edificios" (Pantallas) ---
// (Tus imports existentes...)
import 'package:xplore_cusco/caracteristicas/splash/presentacion/paginas/splash_pagina.dart';
import 'package:xplore_cusco/caracteristicas/navegacion/presentacion/paginas/navegacion_principal.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/inicio_pagina.dart';
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/rutas_pagina.dart';
import 'package:xplore_cusco/caracteristicas/mapa/presentacion/paginas/mapa_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/perfil_pagina.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/provincia_lugares_pagina.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/detalle_lugar_pagina.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/comentarios_pagina.dart';
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/detalle_ruta_pagina.dart';
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/crear_ruta_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/mis_lugares_favoritos_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/mis_rutas_inscritas_pagina.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/login_pagina.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/registro_pagina.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/solicitar_guia_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_dashboard_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_guias_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_cuentas_pagina.dart';
import 'package:xplore_cusco/caracteristicas/notificaciones/presentacion/paginas/notificaciones_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_lugares_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_crear_lugar_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_contenido_pagina.dart';

// --- ¡AÑADIDO! ---
// Importamos las nuevas páginas de Gestión de Provincias
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_provincias_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_crear_provincia_pagina.dart';
// --- FIN DE LO AÑADIDO ---


// --- Importaciones de "Recetas" (Entidades) ---
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/provincia.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';
import 'package:xplore_cusco/caracteristicas/rutas/dominio/entidades/ruta.dart';

// --- Key global para el ShellRoute ---
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'ShellKey');


class AppRutas {
  // Creamos el "GPS" (router) con su "mapa" (routes)
  static final router = GoRouter(

    navigatorKey: mapa_vm.navigatorKey,
    initialLocation: '/',

    routes: [
      // --- Rutas SIN "cáscara" (Splash, Login, Admin) ---
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashPagina();
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

      // --- ¡RUTA DE ADMIN RESTAURADA AQUÍ! ---
      GoRoute(
        path: '/panel-admin',
        builder: (BuildContext context, GoRouterState state) {
          return const AdminDashboardPagina();
        },
      ),
      GoRoute(
        path: '/admin/gestion-guias',
        builder: (BuildContext context, GoRouterState state) {
          return const AdminGestionGuiasPagina();
        },
      ),
      GoRoute(
        path: '/admin/gestion-cuentas',
        builder: (BuildContext context, GoRouterState state) {
          return const AdminGestionCuentasPagina();
        },
      ),
      GoRoute(
        path: '/admin/gestion-contenido',
        builder: (BuildContext context, GoRouterState state) {
          return const AdminGestionContenidoPagina();
        },
      ),
      GoRoute(
        path: '/admin/gestion-lugares',
        builder: (BuildContext context, GoRouterState state) {
          return const AdminGestionLugaresPagina();
        },
      ),
      GoRoute(
        path: '/admin/crear-lugar',
        builder: (BuildContext context, GoRouterState state) {
          final lugar = state.extra as Lugar?;
          return AdminCrearLugarPagina(lugar: lugar);
        },
      ),

      // --- ¡AÑADIDO! ---
      // Rutas para la nueva Gestión de Provincias
      GoRoute(
        path: '/admin/gestion-provincias',
        builder: (BuildContext context, GoRouterState state) {
          return const AdminGestionProvinciasPagina();
        },
      ),
      GoRoute(
        path: '/admin/crear-provincia',
        builder: (BuildContext context, GoRouterState state) {
          final provincia = state.extra as Provincia?;
          return AdminCrearProvinciaPagina(provincia: provincia);
        },
      ),
      // --- FIN DE LO AÑADIDO ---

      GoRoute(
        path: '/notificaciones',
        builder: (BuildContext context, GoRouterState state) {
          return const NotificacionesPagina();
        },
      ),


      // --- LÓGICA DE "CÁSCARA" (ShellRoute) ---
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return NavegacionPrincipal(child: child);
        },

        // --- Pestañas Principales ---
        routes: <RouteBase>[

          // (Tus pestañas 1, 2, 3, 4 van aquí intactas...)
          // --- Pestaña 1: INICIO ---
          GoRoute(
              path: '/inicio',
              builder: (BuildContext context, GoRouterState state) {
                return const InicioPagina();
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'provincia',
                  builder: (BuildContext context, GoRouterState state) {
                    final provincia = state.extra as Provincia;
                    return ProvinciaLugaresPagina(provincia: provincia);
                  },
                ),
                GoRoute(
                  path: 'detalle-lugar',
                  builder: (BuildContext context, GoRouterState state) {
                    final lugar = state.extra as Lugar;
                    return DetalleLugarPagina(lugar: lugar);
                  },
                ),
                GoRoute(
                  path: 'comentarios',
                  builder: (BuildContext context, GoRouterState state) {
                    final lugar = state.extra as Lugar;
                    return ComentariosPagina(lugar: lugar);
                  },
                ),
              ]
          ),

          // --- Pestaña 2: RUTAS ---
          GoRoute(
              path: '/rutas',
              builder: (BuildContext context, GoRouterState state) {
                return const RutasPagina();
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'detalle-ruta',
                  builder: (BuildContext context, GoRouterState state) {
                    final ruta = state.extra as Ruta;
                    return DetalleRutaPagina(ruta: ruta);
                  },
                ),
                GoRoute(
                  path: 'crear-ruta',
                  builder: (BuildContext context, GoRouterState state) {
                    final ruta = state.extra as Ruta?;
                    return CrearRutaPagina(ruta: ruta);
                  },
                ),
              ]
          ),

          // --- Pestaña 3: MAPA ---
          GoRoute(
            path: '/mapa',
            builder: (BuildContext context, GoRouterState state) {
              return const MapaPagina();
            },
          ),

          // --- Pestaña 4: PERFIL ---
          GoRoute(
              path: '/perfil',
              builder: (BuildContext context, GoRouterState state) {
                return const PerfilPagina();
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'solicitar-guia',
                  builder: (BuildContext context, GoRouterState state) {
                    return const SolicitarGuiaPagina();
                  },
                ),
                GoRoute(
                  path: 'mis-favoritos',
                  builder: (BuildContext context, GoRouterState state) {
                    return const MisLugaresFavoritosPagina();
                  },
                ),
                GoRoute(
                  path: 'mis-rutas',
                  builder: (BuildContext context, GoRouterState state) {
                    return const MisRutasInscritasPagina();
                  },
                ),
              ]
          ),
        ],
      ),
    ],
  );
}