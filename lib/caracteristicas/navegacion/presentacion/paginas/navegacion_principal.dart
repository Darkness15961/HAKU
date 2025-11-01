import 'package:flutter/material.dart';
import '../../../inicio/presentacion/paginas/inicio_pagina.dart';
import '../../../rutas/presentacion/paginas/rutas_pagina.dart';
import '../../../mapa/presentacion/paginas/mapa_pagina.dart';
import '../../../perfil/presentacion/paginas/perfil_pagina.dart';

class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indice = 0;

  final List<Widget> _paginas = const [
    InicioPagina(),
    RutasPagina(),
    MapaPagina(),
    PerfilPagina(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).colorScheme.primary;
    final colorInactivo = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return Scaffold(
      body: _paginas[_indice],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indice,
        selectedItemColor: colorPrimario,
        unselectedItemColor: colorInactivo,
        onTap: (index) => setState(() => _indice = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Rutas'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
