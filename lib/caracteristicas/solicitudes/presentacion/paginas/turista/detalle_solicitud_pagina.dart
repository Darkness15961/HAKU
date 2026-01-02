import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../vista_modelos/solicitudes_vm.dart';
import '../../../dominio/entidades/postulacion_guia.dart';

class DetalleSolicitudPagina extends StatefulWidget {
  final String solicitudId;

  const DetalleSolicitudPagina({Key? key, required this.solicitudId})
    : super(key: key);

  @override
  State<DetalleSolicitudPagina> createState() => _DetalleSolicitudPaginaState();
}

class _DetalleSolicitudPaginaState extends State<DetalleSolicitudPagina> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolicitudesVM>().cargarDetalleSolicitud(widget.solicitudId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).primaryColor;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorPrimario.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Consumer<SolicitudesVM>(
            builder: (context, vm, _) {
              if (vm.cargandoDetalleSolicitud) {
                return const Center(child: CircularProgressIndicator());
              }

              final solicitud = vm.solicitudActual;
              if (solicitud == null) {
                return const Center(child: Text('Solicitud no encontrada'));
              }

              return CustomScrollView(
                slivers: [
                  _buildAppBar(context, solicitud, colorPrimario),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(solicitud, colorPrimario),
                          const SizedBox(height: 20),
                          if (solicitud.esBuscandoGuia) ...[
                            _buildPostulacionesSection(
                              vm.postulacionesSolicitudActual,
                              colorPrimario,
                            ),
                          ],
                          if (solicitud.tieneGuiaAsignado) ...[
                            _buildGuiaAsignadoCard(colorPrimario),
                          ],
                          const SizedBox(height: 20),
                          _buildAccionesCard(solicitud, colorPrimario),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, solicitud, Color colorPrimario) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: colorPrimario,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          solicitud.titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black26,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colorPrimario, colorPrimario.withOpacity(0.8)],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.map_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(solicitud, Color colorPrimario) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Estado:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              _buildEstadoBadge(solicitud.estado, colorPrimario),
            ],
          ),
          const Divider(height: 30),
          Text(
            solicitud.descripcion,
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          const Divider(height: 30),
          _buildInfoRow(
            Icons.calendar_today,
            'Fecha',
            _formatearFecha(solicitud.fechaDeseada),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.people,
            'Personas',
            '${solicitud.numeroPersonas}',
          ),
          if (solicitud.presupuestoMaximo != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              Icons.attach_money,
              'Presupuesto',
              'S/ ${solicitud.presupuestoMaximo!.toStringAsFixed(2)}',
            ),
          ],
          if (solicitud.esPrivada) ...[
            const SizedBox(height: 10),
            _buildInfoRow(Icons.lock, 'Privacidad', 'Ruta Privada'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icono, String label, String valor) {
    return Row(
      children: [
        Icon(icono, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text('$label:', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(width: 10),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPostulacionesSection(
    List<PostulacionGuia> postulaciones,
    Color colorPrimario,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.mail, color: colorPrimario),
            const SizedBox(width: 10),
            Text(
              'Propuestas Recibidas (${postulaciones.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (postulaciones.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    'Aún no hay propuestas',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ...postulaciones.map((postulacion) {
            return _buildPostulacionCard(postulacion, colorPrimario);
          }).toList(),
      ],
    );
  }

  Widget _buildPostulacionCard(
    PostulacionGuia postulacion,
    Color colorPrimario,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colorPrimario.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: postulacion.guiaFotoUrl != null
                    ? NetworkImage(postulacion.guiaFotoUrl!)
                    : null,
                child: postulacion.guiaFotoUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      postulacion.guiaNombre ?? 'Guía',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (postulacion.guiaRating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 5),
                          Text(
                            postulacion.guiaRating!.toStringAsFixed(1),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Text(
                postulacion.precioFormateado,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorPrimario,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Text(
            postulacion.descripcionPropuesta,
            style: TextStyle(color: Colors.grey[700]),
          ),
          if (postulacion.serviciosIncluidos.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: postulacion.serviciosIncluidos.map((servicio) {
                return Chip(
                  label: Text(servicio, style: const TextStyle(fontSize: 12)),
                  backgroundColor: colorPrimario.withOpacity(0.1),
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _aceptarPostulacion(postulacion.id),
              icon: const Icon(Icons.check_circle),
              label: const Text('Aceptar Propuesta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimario,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuiaAsignadoCard(Color colorPrimario) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 60, color: Colors.green[700]),
          const SizedBox(height: 10),
          Text(
            '¡Guía Asignado!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tu solicitud ha sido aceptada y la ruta ha sido creada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.green[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildAccionesCard(solicitud, Color colorPrimario) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          if (solicitud.puedeSerCancelada)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelarSolicitud(solicitud.id),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar Solicitud'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          else
            Text(
              'No se puede cancelar (menos de 24h)',
              style: TextStyle(color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildEstadoBadge(String estado, Color colorPrimario) {
    Color color;
    String texto;

    switch (estado) {
      case 'buscando_guia':
        color = Colors.orange;
        texto = 'Buscando Guía';
        break;
      case 'guia_asignado':
        color = Colors.green;
        texto = 'Guía Asignado';
        break;
      case 'cancelada':
        color = Colors.red;
        texto = 'Cancelada';
        break;
      case 'completada':
        color = Colors.blue;
        texto = 'Completada';
        break;
      default:
        color = Colors.grey;
        texto = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _aceptarPostulacion(String postulacionId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text(
          '¿Aceptar esta propuesta?\n\nSe creará la ruta automáticamente y se rechazarán las demás propuestas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final vm = context.read<SolicitudesVM>();
    final rutaId = await vm.aceptarPostulacion(postulacionId);

    if (rutaId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Propuesta aceptada. Ruta creada.')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Error al aceptar propuesta')),
      );
    }
  }

  Future<void> _cancelarSolicitud(String solicitudId) async {
    final motivoController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Estás seguro de cancelar esta solicitud?'),
            const SizedBox(height: 15),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo de cancelación',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final vm = context.read<SolicitudesVM>();
    final error = await vm.cancelarSolicitud(
      solicitudId,
      motivoController.text.isEmpty
          ? 'Sin motivo especificado'
          : motivoController.text,
    );

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Solicitud cancelada')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ $error')));
      }
    }
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }
}
