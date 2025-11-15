// lib/caracteristicas/notificaciones/presentacion/paginas/notificaciones_pagina.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/notificaciones_vm.dart';
import '../../dominio/entidades/notificacion.dart';

class NotificacionesPagina extends StatefulWidget {
  const NotificacionesPagina({super.key});

  @override
  State<NotificacionesPagina> createState() => _NotificacionesPaginaState();
}

class _NotificacionesPaginaState extends State<NotificacionesPagina> {

  @override
  void initState() {
    super.initState();
    // Llama al ViewModel para cargar los datos falsos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Usamos 'read' aquí porque solo es una acción
      context.read<NotificacionesVM>().cargarNotificaciones();
    });
  }

  // --- ¡AÑADIDO! ---
  // Helper para formatear la fecha
  String _formatTimeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inDays > 1) {
      return 'hace ${duration.inDays} días';
    } else if (duration.inDays == 1) {
      return 'ayer';
    } else if (duration.inHours > 1) {
      return 'hace ${duration.inHours} horas';
    } else if (duration.inMinutes > 1) {
      return 'hace ${duration.inMinutes} minutos';
    } else {
      return 'justo ahora';
    }
  }
  // --- FIN DE LO AÑADIDO ---

  @override
  Widget build(BuildContext context) {
    // 'watch' escucha los notifyListeners() del VM
    final vm = context.watch<NotificacionesVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(context, vm),
      // --- ¡AÑADIDO! ---
      // Un fondo más suave para que las tarjetas resalten
      backgroundColor: Colors.grey[50],
      // --- FIN DE LO AÑADIDO ---
    );
  }

  Widget _buildBody(BuildContext context, NotificacionesVM vm) {
    // 1. Estado de Carga
    if (vm.estaCargando) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Estado Vacío
    final notificaciones = vm.notificaciones;
    if (notificaciones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No tienes notificaciones', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    // 3. Estado con Datos
    return RefreshIndicator(
      onRefresh: vm.cargarNotificaciones, // Permite refrescar la lista
      child: ListView.builder(
        // --- ¡AÑADIDO! ---
        // Padding alrededor de la lista
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        // --- FIN DE LO AÑADIDO ---
        itemCount: notificaciones.length,
        itemBuilder: (context, index) {
          final notificacion = notificaciones[index];
          return _buildNotificacionTile(context, vm, notificacion);
        },
      ),
    );
  }

  // --- ¡WIDGET COMPLETAMENTE REDISEÑADO! ---
  // Widget para cada item de la lista
  Widget _buildNotificacionTile(BuildContext context, NotificacionesVM vm, Notificacion notificacion) {
    // Lógica para el icono
    IconData iconData;
    Color iconColor;
    switch (notificacion.tipo) {
      case 'cancelacion':
        iconData = Icons.warning_amber_rounded;
        iconColor = Colors.red;
        break;
      case 'confirmacion':
        iconData = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.info_outline;
        iconColor = Theme.of(context).colorScheme.primary;
    }

    final bool noLeida = !notificacion.leido;
    final colorPrimario = Theme.of(context).colorScheme.primary;

    // Usamos una Card para un look más profesional
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      elevation: noLeida ? 2.0 : 0.5,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: noLeida ? colorPrimario.withOpacity(0.5) : Colors.transparent,
            width: 0.5,
          )
      ),
      child: ListTile(
        // Resaltado sutil para los no leídos
        tileColor: noLeida ? colorPrimario.withOpacity(0.03) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          notificacion.titulo,
          style: TextStyle(
            fontWeight: noLeida ? FontWeight.bold : FontWeight.normal,
            color: noLeida ? Colors.black87 : Colors.black54,
          ),
        ),
        // Usamos un Column en el subtítulo para añadir la fecha
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4.0),
            // El cuerpo del mensaje
            Text(
              notificacion.cuerpo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: noLeida ? Colors.black87 : Colors.black54,
              ),
            ),
            const SizedBox(height: 6.0),
            // La fecha formateada
            Text(
              _formatTimeAgo(notificacion.fecha),
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        // El punto azul de "no leído"
        trailing: noLeida
            ? CircleAvatar(radius: 5, backgroundColor: colorPrimario)
            : null,
        onTap: () {
          // Al tocar, llama al VM para marcarla como leída
          if (noLeida) {
            vm.marcarComoLeida(notificacion.id);
          }

          // Muestra el diálogo con el detalle
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: Text(notificacion.titulo),
              content: Text(notificacion.cuerpo),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
// --- FIN DEL REDISEÑO ---
}