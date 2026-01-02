import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../vista_modelos/solicitudes_vm.dart';
// Unused import removed
import 'crear_postulacion_pagina.dart';

class SolicitudesDisponiblesPagina extends StatefulWidget {
  const SolicitudesDisponiblesPagina({Key? key}) : super(key: key);

  @override
  State<SolicitudesDisponiblesPagina> createState() =>
      _SolicitudesDisponiblesPaginaState();
}

class _SolicitudesDisponiblesPaginaState
    extends State<SolicitudesDisponiblesPagina> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolicitudesVM>().cargarSolicitudesDisponibles();
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
          child: Column(
            children: [
              _buildHeader(context, colorPrimario),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color colorPrimario) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitudes Disponibles',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorPrimario,
                  ),
                ),
                Consumer<SolicitudesVM>(
                  builder: (context, vm, _) {
                    return Text(
                      '${vm.solicitudesDisponibles.length} solicitudes activas',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<SolicitudesVM>(
      builder: (context, vm, _) {
        if (vm.cargandoSolicitudesDisponibles) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.errorSolicitudesDisponibles != null) {
          return _buildError(vm.errorSolicitudesDisponibles!);
        }

        if (vm.solicitudesDisponibles.isEmpty) {
          return _buildEmpty();
        }

        return RefreshIndicator(
          onRefresh: () => vm.cargarSolicitudesDisponibles(),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: vm.solicitudesDisponibles.length,
            itemBuilder: (context, index) {
              return _buildSolicitudCard(vm.solicitudesDisponibles[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildSolicitudCard(solicitud) {
    final colorPrimario = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _verDetalle(solicitud),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        solicitud.titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (solicitud.presupuestoMaximo != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'S/ ${solicitud.presupuestoMaximo!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  solicitud.descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatearFecha(solicitud.fechaDeseada),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 5),
                    Text(
                      '${solicitud.numeroPersonas} personas',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (solicitud.numeroPostulaciones > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${solicitud.numeroPostulaciones} postulaciones',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _postular(solicitud),
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Postular'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimario,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No hay solicitudes disponibles',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Vuelve más tarde para ver nuevas oportunidades',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 20),
          Text(
            'Error al cargar solicitudes',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () =>
                context.read<SolicitudesVM>().cargarSolicitudesDisponibles(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _verDetalle(solicitud) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetalleModal(solicitud),
    );
  }

  Widget _buildDetalleModal(solicitud) {
    final colorPrimario = Theme.of(context).primaryColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorPrimario.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    solicitud.titulo,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorPrimario,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  solicitud.descripcion,
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _postular(solicitud);
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar Propuesta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimario,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  void _postular(solicitud) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearPostulacionPagina(solicitud: solicitud),
      ),
    );
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
