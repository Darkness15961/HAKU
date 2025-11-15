// --- CARACTERISTICAS/PERFIL/PRESENTACION/PAGINAS/MIS_RUTAS_INSCRITAS_PAGINA.DART ---
//
// 1. (¡BUG CORREGIDO!): Se renombró la clase de 'PerfilPagina' a
//    'MisRutasInscritasPagina' para arreglar el error de navegación.
// 2. (¡LIMPIEZA!): Se reemplazó el contenido duplicado de 'perfil_pagina.dart'
//    por el contenido correcto para esta página.
// 3. (¡ERROR CORREGIDO!): Se cambió 'vmRutas.rutasRecomendadas' por
//    'vmRutas.rutasFiltradas' para usar el getter correcto.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM: IMPORTACIONES ---
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../rutas/presentacion/vista_modelos/rutas_vm.dart';
import '../../../rutas/dominio/entidades/ruta.dart'; // <-- Importamos la entidad Ruta

class MisRutasInscritasPagina extends StatelessWidget {
  const MisRutasInscritasPagina({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos a los VMs para obtener los datos
    final vmAuth = context.watch<AutenticacionVM>();
    final vmRutas = context.watch<RutasVM>();

    final colorPrimario = Theme.of(context).colorScheme.primary;

    // --- ¡LÓGICA DE FILTRADO CORREGIDA! ---
    // Cruzamos la lista de IDs del usuario con la lista general de rutas
    // Usamos 'rutasFiltradas' que es el getter correcto en RutasVM
    final List<Ruta> rutasInscritas = vmRutas.rutasFiltradas
        .where((ruta) => vmAuth.rutasInscritasIds.contains(ruta.id))
        .toList();
    // --- FIN DE LÓGICA ---

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Rutas Inscritas'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),

      body: rutasInscritas.isEmpty
          ? const Center( // Mensaje si la lista está vacía
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aún no te has inscrito a ninguna ruta.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder( // Lista si hay rutas
        padding: const EdgeInsets.all(8.0),
        itemCount: rutasInscritas.length,
        itemBuilder: (context, index) {
          final ruta = rutasInscritas[index];
          // (Usamos un ListTile simple, puedes mejorarlo
          //  copiando el _buildRouteCard de 'rutas_pagina.dart' si quieres)
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  ruta.urlImagenPrincipal,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(ruta.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Guía: ${ruta.guiaNombre}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/rutas/detalle-ruta', extra: ruta);
              },
            ),
          );
        },
      ),
    );
  }
}