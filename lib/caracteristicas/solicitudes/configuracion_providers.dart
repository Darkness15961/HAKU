// ============================================
// Configuración de Providers para Solicitudes
// ============================================
//
// Agrega este código a tu archivo main.dart o donde configures los providers
//
// INSTRUCCIONES:
// 1. Importa este archivo en tu main.dart
// 2. Agrega SolicitudesVM a tu MultiProvider
// 3. Asegúrate de que esté después de AutenticacionVM si lo usas
//
// ============================================

/*

import 'package:provider/provider.dart';
import 'caracteristicas/solicitudes/presentacion/vista_modelos/solicitudes_vm.dart';

// En tu MultiProvider, agrega:

MultiProvider(
  providers: [
    // ... otros providers existentes ...
    
    ChangeNotifierProvider(
      create: (_) => SolicitudesVM(),
    ),
    
  ],
  child: MyApp(),
)

*/

// ============================================
// Ejemplo de uso en una página
// ============================================

/*

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/solicitudes_vm.dart';

class EjemploUsoPagina extends StatefulWidget {
  const EjemploUsoPagina({Key? key}) : super(key: key);

  @override
  State<EjemploUsoPagina> createState() => _EjemploUsoPaginaState();
}

class _EjemploUsoPaginaState extends State<EjemploUsoPagina> {
  @override
  void initState() {
    super.initState();
    // Cargar datos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<SolicitudesVM>();
      vm.cargarMisSolicitudes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Solicitudes')),
      body: Consumer<SolicitudesVM>(
        builder: (context, vm, child) {
          if (vm.cargandoMisSolicitudes) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.errorMisSolicitudes != null) {
            return Center(
              child: Text('Error: ${vm.errorMisSolicitudes}'),
            );
          }

          if (vm.misSolicitudes.isEmpty) {
            return const Center(
              child: Text('No tienes solicitudes'),
            );
          }

          return ListView.builder(
            itemCount: vm.misSolicitudes.length,
            itemBuilder: (context, index) {
              final solicitud = vm.misSolicitudes[index];
              return ListTile(
                title: Text(solicitud.titulo),
                subtitle: Text(solicitud.estadoTexto),
                trailing: Text('${solicitud.numeroPostulaciones} propuestas'),
              );
            },
          );
        },
      ),
    );
  }
}

*/
