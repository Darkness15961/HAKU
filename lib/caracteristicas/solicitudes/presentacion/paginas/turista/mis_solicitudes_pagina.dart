import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../vista_modelos/solicitudes_vm.dart';
// Unused import removed
import 'detalle_solicitud_pagina.dart';
import 'crear_solicitud_pagina.dart';

class MisSolicitudesPagina extends StatefulWidget {
  const MisSolicitudesPagina({Key? key}) : super(key: key);

  @override
  State<MisSolicitudesPagina> createState() => _MisSolicitudesPaginaState();
}

class _MisSolicitudesPaginaState extends State<MisSolicitudesPagina>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolicitudesVM>().cargarMisSolicitudes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              _buildTabs(colorPrimario),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navegarACrearSolicitud(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Solicitud'),
        backgroundColor: colorPrimario,
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
                  'Mis Solicitudes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorPrimario,
                  ),
                ),
                Consumer<SolicitudesVM>(
                  builder: (context, vm, _) {
                    return Text(
                      '${vm.misSolicitudes.length} solicitudes',
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

  Widget _buildTabs(Color colorPrimario) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
      child: TabBar(
        controller: _tabController,
        labelColor: colorPrimario,
        unselectedLabelColor: Colors.grey,
        indicatorColor: colorPrimario,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Buscando'),
          Tab(text: 'Asignadas'),
          Tab(text: 'Canceladas'),
          Tab(text: 'Completadas'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Consumer<SolicitudesVM>(
      builder: (context, vm, _) {
        if (vm.cargandoMisSolicitudes) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.errorMisSolicitudes != null) {
          return _buildError(vm.errorMisSolicitudes!);
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildLista(vm.solicitudesBuscandoGuia, '🔍 Buscando Guía'),
            _buildLista(vm.solicitudesConGuia, '✅ Con Guía'),
            _buildLista(vm.solicitudesCanceladas, '❌ Canceladas'),
            _buildLista(vm.solicitudesCompletadas, '🎉 Completadas'),
          ],
        );
      },
    );
  }

  Widget _buildLista(List solicitudes, String emptyMessage) {
    if (solicitudes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<SolicitudesVM>().cargarMisSolicitudes(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: solicitudes.length,
        itemBuilder: (context, index) {
          return _buildSolicitudCard(solicitudes[index]);
        },
      ),
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
          onTap: () => _navegarADetalle(solicitud.id),
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
                    _buildEstadoBadge(solicitud.estado, colorPrimario),
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
                if (solicitud.numeroPostulaciones > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorPrimario.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mail, size: 16, color: colorPrimario),
                        const SizedBox(width: 5),
                        Text(
                          '${solicitud.numeroPostulaciones} propuesta${solicitud.numeroPostulaciones > 1 ? 's' : ''} recibida${solicitud.numeroPostulaciones > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: colorPrimario,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(String estado, Color colorPrimario) {
    Color color;
    String texto;

    switch (estado) {
      case 'buscando_guia':
        color = Colors.orange;
        texto = 'Buscando';
        break;
      case 'guia_asignado':
        color = Colors.green;
        texto = 'Asignado';
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
                context.read<SolicitudesVM>().cargarMisSolicitudes(),
            child: const Text('Reintentar'),
          ),
        ],
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

  void _navegarADetalle(String solicitudId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleSolicitudPagina(solicitudId: solicitudId),
      ),
    );
  }

  void _navegarACrearSolicitud(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearSolicitudPagina()),
    );
  }
}
