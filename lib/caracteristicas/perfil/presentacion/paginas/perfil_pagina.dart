import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --- MVVM: IMPORTACIONES ---
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import 'package:xplore_cusco/caracteristicas/rutas/presentacion/vista_modelos/rutas_vm.dart';
import 'package:xplore_cusco/caracteristicas/notificaciones/presentacion/vista_modelos/notificaciones_vm.dart';
import 'package:xplore_cusco/core/servicios/imagen_servicio.dart';

// --- IMPORTAMOS MAPA VM PARA LA NAVEGACIÓN A RECUERDOS ---
import 'package:xplore_cusco/caracteristicas/mapa/presentacion/vista_modelos/mapa_vm.dart';

class PerfilPagina extends StatelessWidget {
  const PerfilPagina({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    await context.read<AutenticacionVM>().cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final vmAuth = context.watch<AutenticacionVM>();

    // Usamos tu color Celeste (#00BCD4) como base
    final colorCabecera = const Color(0xFF00BCD4);

    if (vmAuth.estaCargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          if (vmAuth.estaLogueado) ...[
            Consumer<NotificacionesVM>(
              builder: (context, vmNotificaciones, child) {
                final int unreadCount = vmNotificaciones.unreadCount;
                return IconButton(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(unreadCount.toString()),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  onPressed: () => context.push('/notificaciones'),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                context.push('/perfil/ajustes-cuenta');
              },
            ),
          ],
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: vmAuth.estaLogueado
          ? _buildPerfilLogueado(context, vmAuth, colorCabecera)
          : _buildPerfilNoLogueado(context, colorCabecera),
    );
  }

  // --- VISTA 1: Usuario Logueado ---
  Widget _buildPerfilLogueado(
    BuildContext context,
    AutenticacionVM vmAuth,
    Color colorPrimario,
  ) {
    final usuario = vmAuth.usuarioActual!;
    final imagenServicio = ImagenServicio();

    String rolLabel = 'Explorador';
    switch (usuario.rol) {
      case 'admin':
        rolLabel = 'Administrador';
        break;
      case 'guia_aprobado':
      case 'guia_local':
        rolLabel = 'Guía Local Certificado';
        break;
      case 'guia_pendiente':
        rolLabel = 'Verificando solicitud...';
        break;
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // --- 1. HEADER CIAN ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 100,
              bottom: 30,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: colorPrimario,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorPrimario.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Foto de Perfil
                GestureDetector(
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Abriendo galería...')),
                    );
                    final nuevaUrl = await imagenServicio.seleccionarYSubir(
                      'perfiles',
                    );
                    if (nuevaUrl != null) {
                      await context
                          .read<AutenticacionVM>()
                          .actualizarFotoPerfil(nuevaUrl);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Foto actualizada')),
                      );
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              (usuario.urlFotoPerfil != null &&
                                  usuario.urlFotoPerfil!.isNotEmpty)
                              ? NetworkImage(usuario.urlFotoPerfil!)
                              : null,
                          child:
                              (usuario.urlFotoPerfil == null ||
                                  usuario.urlFotoPerfil!.isEmpty)
                              ? Text(
                                  usuario.seudonimo
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: colorPrimario,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  usuario.seudonimo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  usuario.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                if (usuario.rol != 'turista')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rolLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- 2. CUERPO DE OPCIONES ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    'Mi Actividad',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                // TARJETA DE ACTIVIDAD
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildListTile(
                        icon: Icons.favorite,
                        color: Colors.red,
                        title: 'Mis Lugares Favoritos',
                        subtitle: 'Ver los lugares que guardaste',
                        onTap: () => context.push('/perfil/mis-favoritos'),
                      ),
                      _buildDivider(),
                      _buildListTile(
                        icon: Icons.check_circle,
                        color: Colors.green,
                        title: 'Mis Rutas Inscritas',
                        subtitle: 'Ver las rutas a las que te inscribiste',
                        onTap: () => context.push('/perfil/mis-rutas'),
                      ),
                      _buildDivider(),

                      // --- ¡NUEVA OPCIÓN: MIS RECUERDOS! ---
                      _buildListTile(
                        icon: Icons
                            .photo_library_outlined, // Icono de álbum/fotos
                        color:
                            Colors.amber.shade800, // Color cálido (recuerdos)
                        title: 'Mis Recuerdos',
                        subtitle: 'Fotos de tus aventuras en el mapa',
                        onTap: () {
                          // 1. Activamos el filtro "Mis Recuerdos" (índice 1) en el Mapa
                          context.read<MapaVM>().setFiltro(1);
                          // 2. Navegamos a la pestaña del Mapa
                          context.go('/mapa');
                        },
                      ),
                      // --- FIN NUEVA OPCIÓN ---
                      _buildDivider(),
                      _buildListTile(
                        icon: Icons.map_outlined, 
                        color: const Color(0xFF00BCD4), // Cyan
                        title: 'Mis Hakuparadas',
                        subtitle: 'Tus paradas y sugerencias',
                        onTap: () => context.push('/perfil/mis-hakuparadas'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    'Gestión',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                // TARJETA DE GESTIÓN
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  child: Column(
                    children: [
                      if (usuario.rol == 'guia_aprobado' ||
                          usuario.rol == 'guia_local' ||
                          usuario.rol == 'admin') ...[
                        _buildListTile(
                          icon: Icons.add_road,
                          color: Colors.blue,
                          title: 'Mis Rutas Creadas',
                          subtitle: 'Gestionar las rutas que publicaste',
                          onTap: () {
                            context.read<RutasVM>().cambiarPestana(
                              'Creadas por mí',
                            );
                            context.go('/rutas');
                          },
                        ),
                        _buildDivider(),
                        _buildListTile(
                          icon: Icons.work,
                          color: Colors.blue,
                          title: 'Solicitudes Disponibles',
                          subtitle: 'Ver oportunidades de trabajo',
                          onTap: () =>
                              context.push('/perfil/solicitudes-disponibles'),
                        ),
                        _buildDivider(),
                        _buildListTile(
                          icon: Icons.mail,
                          color: Colors.orange,
                          title: 'Mis Postulaciones',
                          subtitle: 'Ver propuestas enviadas',
                          onTap: () =>
                              context.push('/perfil/mis-postulaciones'),
                        ),
                        _buildDivider(),
                      ],

                      if (usuario.rol == 'turista') ...[
                        _buildListTile(
                          icon: Icons.assignment_ind,
                          color: colorPrimario,
                          title: 'Solicitar ser Guía',
                          subtitle: 'Envía tu solicitud para crear rutas',
                          onTap: () => context.push('/perfil/solicitar-guia'),
                        ),
                        _buildDivider(),
                        _buildListTile(
                          icon: Icons.request_page,
                          color: Colors.purple,
                          title: 'Mis Solicitudes',
                          subtitle: 'Gestionar solicitudes de rutas',
                          onTap: () => context.push('/perfil/mis-solicitudes'),
                        ),
                        _buildDivider(),
                      ],

                      // NUEVO: SUGERIR HAKUPARADA (Botón directo de gestión)
                      _buildListTile(
                        icon: Icons.add_location_alt_outlined,
                        color: const Color(0xFF00BCD4),
                        title: 'Sugerir Hakuparada',
                        subtitle: 'Crea un punto de interés rápido',
                        onTap: () => context.push('/crear-hakuparada'),
                      ),
                      _buildDivider(),

                      _buildListTile(
                        icon: Icons.add_business_outlined, // Cambiado icono para diferenciarlo
                        color: Colors.orange,
                        title: 'Publicar un Lugar',
                        subtitle: 'Sugiere un nuevo destino',
                        onTap: () => context.push('/admin/crear-lugar'),
                      ),
                      _buildDivider(),
                      _buildListTile(
                        icon: Icons.list_alt,
                        color: Colors.purple,
                        title: 'Mis Lugares Publicados',
                        subtitle: 'Gestiona tus lugares y ve reseñas',
                        onTap: () =>
                            context.push('/perfil/mis-lugares-publicados'),
                      ),

                      if (vmAuth.esAdmin) ...[
                        _buildDivider(),
                        _buildListTile(
                          icon: Icons.admin_panel_settings,
                          color: Colors.black87,
                          title: 'Panel de Administrador',
                          subtitle: 'Gestionar solicitudes y usuarios',
                          onTap: () => context.push('/panel-admin'),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                TextButton.icon(
                  onPressed: () => _cerrarSesion(context),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- VISTA 2: Visitante ---
  Widget _buildPerfilNoLogueado(BuildContext context, Color colorCabecera) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            Icons.explore_outlined,
            size: 100,
            color: colorCabecera.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bienvenido a Haku',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Inicia sesión para guardar favoritos, crear rutas y conectar con guías.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorCabecera,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Iniciar Sesión'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.push('/registro'),
            child: Text(
              'Crear Cuenta',
              style: TextStyle(
                color: colorCabecera,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildListTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 0.5,
      indent: 70,
      color: Color(0xFFEEEEEE),
    );
  }
}
