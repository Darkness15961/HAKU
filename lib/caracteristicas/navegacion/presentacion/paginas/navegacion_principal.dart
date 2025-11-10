// --- NAVEGACION PRINCIPAL (BottomNavigationBar) ---
//
// 1. (BUG CORREGIDO): Ahora importa 'admin_dashboard_pagina.dart'
//    (el nuevo panel) en lugar de 'admin_panel_pagina.dart'.
// 2. (ACOMPLADO): Si el usuario es 'admin', muestra 'AdminDashboardPagina'.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- IMPORTACIONES DE PESTAÑAS ---
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/inicio_pagina.dart';
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/rutas_pagina.dart';
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/perfil_pagina.dart';
import 'package:xplore_cusco/caracteristicas/mapa/presentacion/paginas/mapa_pagina.dart';

// --- ¡IMPORTACIONES DE ADMIN CORREGIDAS! ---
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
// ¡Importa el Dashboard, no el panel de gestión!
import 'package:xplore_cusco/caracteristicas/administracion/presentacion/paginas/admin_dashboard_pagina.dart';
// --- FIN DE IMPORTACIONES ---


class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indiceSeleccionado = 0;

  static final List<Widget> _paginas = <Widget>[
    const InicioPagina(),
    const RutasPagina(),
    const MapaPagina(),
    const PerfilPagina(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _indiceSeleccionado = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- ¡ACOMPLE DE LÓGICA ADMIN! ---
    final vmAuth = context.watch<AutenticacionVM>();

    // Si el usuario es Admin...
    if (vmAuth.esAdmin) {
      // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
      // Muestra el DASHBOARD (el entorno), no el panel antiguo.
      return const AdminDashboardPagina();
    }
    // --- FIN DE CORRECCIÓN ---

    // Si es Turista o Guía, mostramos la app normal
    return Scaffold(
      body: IndexedStack(
        index: _indiceSeleccionado,
        children: _paginas,
      ),
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
        currentIndex: _indiceSeleccionado,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}