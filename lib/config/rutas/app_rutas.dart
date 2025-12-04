import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// --- 1. IMPORTACIONES DE VIEWMODELS ---
import 'package:xplore_cusco/caracteristicas/mapa/presentacion/vista_modelos/mapa_vm.dart'
    as mapa_vm;

// --- 2. IMPORTACIONES DE ENTIDADES ---
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/provincia.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';
import 'package:xplore_cusco/caracteristicas/rutas/dominio/entidades/ruta.dart';

// --- 3. IMPORTACIONES DE PÁGINAS (Asegúrate de que estas rutas existan) ---
import 'package:xplore_cusco/caracteristicas/splash/presentacion/paginas/splash_pagina.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/login_pagina.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/registro_pagina.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/recuperar_contrasena_pagina.dart';
import 'package:xplore_cusco/caracteristicas/navegacion/presentacion/paginas/navegacion_principal.dart';

// Páginas de Inicio
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/inicio_pagina.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/provincia_lugares_pagina.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/detalle_lugar_pagina.dart'; // <--- ¡IMPORTANTE!
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/comentarios_pagina.dart'; // <--- ¡IMPORTANTE!

// Páginas de Rutas
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/rutas_pagina.dart';
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/detalle_ruta_pagina.dart';
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/crear_ruta_pagina.dart';

// Páginas de Mapa
import 'package:xplore_cusco/caracteristicas/mapa/presentacion/paginas/mapa_pagina.dart';
import 'package:xplore_cusco/caracteristicas/mapa/presentacion/paginas/mapa_simple_pagina.dart';

// Páginas de Perfil
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/perfil_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/mis_lugares_favoritos_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/mis_rutas_inscritas_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/ajustes_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/mis_lugares_publicados_pagina.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/paginas/solicitar_guia_pagina.dart';

// Páginas de Notificaciones
import 'package:xplore_cusco/caracteristicas/notificaciones/presentacion/paginas/notificaciones_pagina.dart';

// Páginas de Admin
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_dashboard_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_guias_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_cuentas_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_contenido_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_lugares_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_crear_lugar_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_gestion_provincias_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_crear_provincia_pagina.dart';
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/selector_ubicacion_pagina.dart';

// --- Key global para el ShellRoute ---
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'ShellKey',
);

class AppRutas {
  static final router = GoRouter(
    navigatorKey: mapa_vm.navigatorKey,
    initialLocation: '/', // Arranca en splash screen SIEMPRE

    routes: [
      // --- Rutas SIN "cáscara" (Pantalla completa) ---
      GoRoute(path: '/', builder: (context, state) => SplashPagina()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPagina()),
      GoRoute(
        path: '/registro',
        builder: (context, state) => const RegistroPagina(),
      ),
      GoRoute(
        path: '/recuperar-contrasena',
        builder: (context, state) => const RecuperarContrasenaPage(),
      ),

      // Rutas de Admin
      GoRoute(
        path: '/panel-admin',
        builder: (context, state) => const AdminDashboardPagina(),
      ),
      GoRoute(
        path: '/admin/gestion-guias',
        builder: (context, state) => const AdminGestionGuiasPagina(),
      ),
      GoRoute(
        path: '/admin/gestion-cuentas',
        builder: (context, state) => const AdminGestionCuentasPagina(),
      ),
      GoRoute(
        path: '/admin/gestion-contenido',
        builder: (context, state) => const AdminGestionContenidoPagina(),
      ),
      GoRoute(
        path: '/admin/gestion-lugares',
        builder: (context, state) => const AdminGestionLugaresPagina(),
      ),
      GoRoute(
        path: '/admin/crear-lugar',
        builder: (context, state) {
          final lugar = state.extra as Lugar?;
          return AdminCrearLugarPagina(lugar: lugar);
        },
      ),
      GoRoute(
        path: '/admin/gestion-provincias',
        builder: (context, state) => const AdminGestionProvinciasPagina(),
      ),
      GoRoute(
        path: '/admin/crear-provincia',
        builder: (context, state) {
          final provincia = state.extra as Provincia?;
          return AdminCrearProvinciaPagina(provincia: provincia);
        },
      ),
      GoRoute(
        path: '/admin/selector-ubicacion',
        builder: (context, state) {
          final LatLng? ubicacionInicial = state.extra as LatLng?;
          return SelectorUbicacionPagina(ubicacionInicial: ubicacionInicial);
        },
      ),

      // Rutas Extras
      GoRoute(
        path: '/mapa-lugar',
        builder: (context, state) {
          final lugar = state.extra as Lugar;
          return MapaSimplePagina(lugar: lugar);
        },
      ),
      GoRoute(
        path: '/notificaciones',
        builder: (context, state) => const NotificacionesPagina(),
      ),

      // --- SHELL ROUTE (Barra de Navegación Inferior) ---
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return NavegacionPrincipal(child: child);
        },
        routes: [
          // Pestaña 1: INICIO
          GoRoute(
            path: '/inicio',
            builder: (context, state) => const InicioPagina(),
            routes: [
              GoRoute(
                path: 'provincia',
                builder: (context, state) {
                  final provincia = state.extra as Provincia;
                  return ProvinciaLugaresPagina(provincia: provincia);
                },
              ),
              GoRoute(
                path: 'detalle-lugar',
                builder: (context, state) {
                  final lugar = state.extra as Lugar;
                  // Aquí se usa DetalleLugarPagina
                  return DetalleLugarPagina(lugar: lugar);
                },
              ),
              GoRoute(
                path: 'comentarios',
                builder: (context, state) {
                  final lugar = state.extra as Lugar;
                  // Aquí se usa ComentariosPagina
                  return ComentariosPagina(lugar: lugar);
                },
              ),
            ],
          ),

          // Pestaña 2: RUTAS
          GoRoute(
            path: '/rutas',
            builder: (context, state) => const RutasPagina(),
            routes: [
              GoRoute(
                path: 'detalle-ruta',
                builder: (context, state) {
                  final ruta = state.extra as Ruta;
                  return DetalleRutaPagina(ruta: ruta);
                },
              ),
              GoRoute(
                path: 'crear-ruta',
                builder: (context, state) {
                  final ruta = state.extra as Ruta?;
                  return CrearRutaPagina(ruta: ruta);
                },
              ),
            ],
          ),

          // Pestaña 3: MAPA
          GoRoute(
            path: '/mapa',
            builder: (context, state) => const MapaPagina(),
          ),

          // Pestaña 4: PERFIL
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const PerfilPagina(),
            routes: [
              GoRoute(
                path: 'solicitar-guia',
                builder: (context, state) => const SolicitarGuiaPagina(),
              ),
              GoRoute(
                path: 'mis-favoritos',
                builder: (context, state) => const MisLugaresFavoritosPagina(),
              ),
              GoRoute(
                path: 'mis-rutas',
                builder: (context, state) => const MisRutasInscritasPagina(),
              ),
              GoRoute(
                path: 'ajustes',
                builder: (context, state) => const AjustesPagina(),
              ),
              GoRoute(
                path: 'mis-lugares-publicados',
                builder: (context, state) => const MisLugaresPublicadosPagina(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
