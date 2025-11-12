// --- NAVEGACION PRINCIPAL (BottomNavigationBar) ---
//
// 1. (BUG NAVEGACIÓN CORREGIDO): Reestructurado para 'ShellRoute'.
// 2. (ACOMPLADO): Ahora acepta un 'child' (el hijo) de GoRouter.
// 3. (ACOMPLADO): El 'body' es el 'child'.
// 4. (ACOMPLADO): Los 'onTap' ahora usan 'context.go()' para navegar.
// 5. (CORREGIDO): Se eliminó la lógica de 'vmAuth.esAdmin' de este widget
//    para evitar conflictos con el ShellRoute y solucionar el crash.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart'; // <-- ¡IMPORTADO!

// --- IMPORTACIONES DE PESTAÑAS (Ya no se necesitan aquí) ---
// ...

// --- ¡IMPORTACIONES DE ADMIN (Ya NO se usan aquí)! ---
// import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
// import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_dashboard_pagina.dart';
// --- FIN DE IMPORTACIONES ---


class NavegacionPrincipal extends StatefulWidget {
  // --- ¡ACOMPLADO! ---
  // Acepta el 'child' que GoRouter le pasará (ej. InicioPagina, RutasPagina, etc.)
  final Widget child;

  const NavegacionPrincipal({
    super.key,
    required this.child, // <-- Requerido por el ShellRoute
  });
  // --- FIN DE ACOMPLE ---

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {

  // (El IndexedStack y _paginas ya no se manejan aquí)

  // --- LÓGICA DE NAVEGACIÓN (¡ACTUALIZADA!) ---
  // Ahora le decimos a GoRouter a dónde ir, en lugar de cambiar un índice
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/inicio');
        break;
      case 1:
        context.go('/rutas');
        break;
      case 2:
        context.go('/mapa');
        break;
      case 3:
        context.go('/perfil');
        break;
    }
  }

  // --- LÓGICA DE ÍNDICE (¡ACTUALIZADA!) ---
  // El BottomNavBar necesita saber qué pestaña está activa
  // leyendo la RUTA actual.
  int _calcularIndiceSeleccionado(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/inicio')) {
      return 0;
    }
    if (location.startsWith('/rutas')) {
      return 1;
    }
    if (location.startsWith('/mapa')) {
      return 2;
    }
    if (location.startsWith('/perfil')) {
      return 3;
    }
    return 0; // Default a Inicio
  }
  // --- FIN DE LÓGICA ACTUALIZADA ---

  @override
  Widget build(BuildContext context) {
    // --- LÓGICA DE ADMIN ELIMINADA DE AQUÍ ---
    // final vmAuth = context.watch<AutenticacionVM>();
    // if (vmAuth.esAdmin) {
    //   return const AdminDashboardPagina();
    // }
    // --- FIN DE LA CORRECCIÓN ---

    // Si es Turista o Guía, mostramos la app normal (ShellRoute)
    return Scaffold(
      // --- ¡ACOMPLADO! ---
      // El body ahora es el 'child' que GoRouter nos pasa
      // (ej. InicioPagina, o DetalleLugarPagina)
      body: widget.child,
      // --- FIN DE ACOMPLE ---

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Rutas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        // --- ¡ACOMPLADO! ---
        currentIndex: _calcularIndiceSeleccionado(context), // <-- Lee la ruta
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => _onItemTapped(index, context), // <-- Llama al router
      ),
    );
  }
}