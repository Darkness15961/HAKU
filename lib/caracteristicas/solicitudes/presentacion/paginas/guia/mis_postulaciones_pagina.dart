import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../vista_modelos/solicitudes_vm.dart';

class MisPostulacionesPagina extends StatefulWidget {
  const MisPostulacionesPagina({Key? key}) : super(key: key);

  @override
  State<MisPostulacionesPagina> createState() => _MisPostulacionesPaginaState();
}

class _MisPostulacionesPaginaState extends State<MisPostulacionesPagina>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolicitudesVM>().cargarMisPostulaciones();
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
                  'Mis Postulaciones',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorPrimario,
                  ),
                ),
                Consumer<SolicitudesVM>(
                  builder: (context, vm, _) {
                    return Text(
                      '${vm.misPostulaciones.length} postulaciones',
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
          Tab(text: 'Pendientes'),
          Tab(text: 'Aceptadas'),
          Tab(text: 'Rechazadas'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Consumer<SolicitudesVM>(
      builder: (context, vm, _) {
        if (vm.cargandoMisPostulaciones) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.errorMisPostulaciones != null) {
          return _buildError(vm.errorMisPostulaciones!);
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildLista(vm.postulacionesPendientes, '⏳ Pendientes'),
            _buildLista(vm.postulacionesAceptadas, '✅ Aceptadas'),
            _buildLista(vm.postulacionesRechazadas, '❌ Rechazadas'),
          ],
        );
      },
    );
  }

  Widget _buildLista(List postulaciones, String emptyMessage) {
    if (postulaciones.isEmpty) {
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
      onRefresh: () => context.read<SolicitudesVM>().cargarMisPostulaciones(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: postulaciones.length,
        itemBuilder: (context, index) {
          return _buildPostulacionCard(postulaciones[index]);
        },
      ),
    );
  }

  Widget _buildPostulacionCard(postulacion) {
    final colorPrimario = Theme.of(context).primaryColor;
    Color estadoColor;
    IconData estadoIcon;

    switch (postulacion.estado) {
      case 'pendiente':
        estadoColor = Colors.orange;
        estadoIcon = Icons.access_time;
        break;
      case 'aceptada':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      case 'rechazada':
        estadoColor = Colors.red;
        estadoIcon = Icons.cancel;
        break;
      default:
        estadoColor = Colors.grey;
        estadoIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: estadoColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(estadoIcon, color: estadoColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    postulacion.estadoTexto,
                    style: TextStyle(
                      color: estadoColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
              'Solicitud: ${postulacion.solicitudId}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              postulacion.descripcionPropuesta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Text(
                  postulacion.tiempoDesdePostulacion,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            if (postulacion.serviciosIncluidos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (postulacion.serviciosIncluidos as List)
                    .take(3)
                    .map<Widget>((servicio) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorPrimario.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          servicio.toString(),
                          style: TextStyle(color: colorPrimario, fontSize: 11),
                        ),
                      );
                    })
                    .toList(),
              ),
            ],
            if (postulacion.estado == 'aceptada') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.green[700]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '¡Felicidades! Tu propuesta fue aceptada',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
            'Error al cargar postulaciones',
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
                context.read<SolicitudesVM>().cargarMisPostulaciones(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
