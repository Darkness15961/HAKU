// --- NAVEGACION PRINCIPAL (BottomNavigationBar) ---
//
// Esta es la versión 100% FINAL de tu app.
// ¡Hemos reemplazado el último "placeholder"
// por la "MapaPagina" real!

import 'package:flutter/material.dart';

// --- IMPORTACIONES DE PESTAÑAS ---
// 1. Importamos la pestaña 1 (Inicio)
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/paginas/inicio_pagina.dart';
// 2. Importamos la pestaña 2 (Rutas)
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/paginas/rutas_pagina.dart';
// 3. Importamos la pestaña 4 (Perfil)
import 'package:xplore_cusco/caracteristicas/perfil/presentacion/paginas/perfil_pagina.dart';

// --- ¡NUEVA IMPORTACIÓN! (Paso 4 - Bloque 5) ---
// 4. Importamos la pestaña 3 (Mapa)
//    (Este es el archivo de diseño que tienes en el Canvas)
import 'package:xplore_cusco/caracteristicas/mapa/presentacion/paginas/mapa_pagina.dart';
// --- FIN DE LA IMPORTACIÓN ---

class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indiceSeleccionado = 0;

  // --- ¡ARREGLO! (Paso 4 - Bloque 5) ---
  //
  // Reemplazamos el "placeholder" de Mapa
  // con el "Menú" (pantalla) real que creamos.
  static final List<Widget> _paginas = <Widget>[
    // 1. INICIO (Ya está lista)
    const InicioPagina(),

    // 2. RUTAS (Ya está lista)
    const RutasPagina(),

    // 3. MAPA (¡Ahora es la página real!)
    const MapaPagina(),

    // 4. PERFIL (Ya está lista)
    const PerfilPagina(),
  ];
  // --- FIN DEL ARREGLO ---

  void _onItemTapped(int index) {
    setState(() {
      _indiceSeleccionado = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos IndexedStack para mantener el estado de las páginas
      // (así no se recargan cada vez que cambias de pestaña)
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
        selectedItemColor: Theme.of(context).primaryColor, // Color del tema
        unselectedItemColor: Colors.grey, // Color inactivo
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, // Muestra todos los labels
        onTap: _onItemTapped,
      ),
    );
  }
}