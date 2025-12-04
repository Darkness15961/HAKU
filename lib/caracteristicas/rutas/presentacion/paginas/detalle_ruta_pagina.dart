import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM ---
import '../vista_modelos/rutas_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/servicios/imagen_servicio.dart';
import '../../../inicio/dominio/repositorios/lugares_repositorio.dart';
import '../../../inicio/datos/repositorios/lugares_repositorio_supabase.dart';
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../dominio/entidades/ruta.dart';

class DetalleRutaPagina extends StatelessWidget {
  final Ruta ruta;

  const DetalleRutaPagina({super.key, required this.ruta});

  // --- Lógica de Seguridad ---
  bool _checkAndRedirect(BuildContext context, String action) {
    final authVM = context.read<AutenticacionVM>();
    if (!authVM.estaLogueado) {
      _showLoginRequiredModal(context, action);
      return false;
    }
    return true;
  }

  void _handleRegistration(BuildContext context) {
    if (!_checkAndRedirect(context, 'inscribirte en esta ruta')) return;

    final vmAuth = context.read<AutenticacionVM>();
    final estaInscrito = vmAuth.rutasInscritasIds.contains(ruta.id);

    if (estaInscrito) {
      context.read<RutasVM>().salirDeRuta(ruta.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has cancelado tu registro (Simulado)')),
      );
    } else {
      context.read<RutasVM>().inscribirseEnRuta(ruta.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Registro a la ruta exitoso! (Simulado)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // --- Helper de Colores (El mismo de la lista para mantener consistencia) ---
  // --- REEMPLAZAR ESTE MÉTODO COMPLETO ---
  Color _getColorCategoria(String categoria) {
    // Convertimos a minúsculas y limpiamos espacios por seguridad
    final categoriaLower = categoria.toLowerCase().trim();

    // Verificamos coincidencias parciales para ser más flexibles
    if (categoriaLower.contains('familiar'))
      return const Color(0xFF4CAF50); // Verde
    if (categoriaLower.contains('cultural'))
      return const Color(0xFF3F51B5); // Indigo
    if (categoriaLower.contains('aventura'))
      return const Color(0xFFFF9800); // Naranja
    if (categoriaLower.contains('+18')) return const Color(0xFF212121); // Negro
    if (categoriaLower.contains('naturaleza'))
      return const Color(0xFF9C27B0); // Morado
    if (categoriaLower.contains('extrema'))
      return const Color(0xFFD32F2F); // Rojo

    // Default para datos antiguos o desconocidos
    return Colors.grey;
  }

  // --- AGREGAR ESTE NUEVO MÉTODO ---
  IconData _getIconForCategory(String categoria) {
    final categoriaLower = categoria.toLowerCase().trim();

    if (categoriaLower.contains('familiar')) return Icons.family_restroom;
    if (categoriaLower.contains('cultural')) return Icons.museum;
    if (categoriaLower.contains('aventura')) return Icons.hiking;
    if (categoriaLower.contains('+18'))
      return Icons.local_bar; // O Icons.nightlife
    if (categoriaLower.contains('naturaleza'))
      return Icons.self_improvement; // O Icons.landscape
    if (categoriaLower.contains('extrema'))
      return Icons.volcano; // O Icons.warning

    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    final bool esModoPreview = ruta.id == 'preview_id';
    final bool esFavorita = esModoPreview
        ? false
        : vmAuth.rutasFavoritasIds.contains(ruta.id);
    final bool estaInscrito = esModoPreview
        ? false
        : vmAuth.rutasInscritasIds.contains(ruta.id);

    final String? usuarioIdActual = vmAuth.usuarioActual?.id;
    final bool esPropietario =
        esModoPreview ||
        (vmAuth.estaLogueado && usuarioIdActual == ruta.guiaId);
    final bool esGuia = vmAuth.usuarioActual?.id == ruta.guiaId;

    final int cuposDisponibles = ruta.cuposTotales - ruta.inscritosCount;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- 1. HEADER CINEMÁTICO ---
          SliverAppBar(
            expandedHeight: 350.0,
            floating: false,
            pinned: true,
            backgroundColor: colorPrimario,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              // Botón de editar (solo para el propietario)
              if (esPropietario && !esModoPreview)
                IconButton(
                  onPressed: () {
                    context.push('/rutas/crear-ruta', extra: ruta);
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                ),
              // Botón de favorito
              IconButton(
                onPressed: () {
                  if (esModoPreview) {
                    _showPreviewModeWarning(context);
                    return;
                  }
                  if (_checkAndRedirect(context, 'guardar esta ruta')) {
                    context.read<RutasVM>().toggleFavoritoRuta(ruta.id);
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    esFavorita ? Icons.favorite : Icons.favorite_border,
                    color: esFavorita ? Colors.red : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // A. Imagen de Fondo
                  Image.network(
                    ruta.urlImagenPrincipal,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  // B. Gradiente Oscuro (Para que el texto se lea bien)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.9),
                        ],
                        stops: const [0.4, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // C. Contenido del Header
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Etiquetas (Chips) Modernas
                        Row(
                          children: [
                            // Categoria
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getColorCategoria(ruta.categoria),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                ruta.categoria.toUpperCase(),
                                style: TextStyle(
                                  color: _getColorCategoria(ruta.categoria),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Cupos
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.group,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$cuposDisponibles cupos',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Título Grande
                        Text(
                          ruta.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26.0,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Rating
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ruta.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              ' (${ruta.reviewsCount} reseñas)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 2. DETALLES ---
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              _buildInfoCard(context, ruta, cuposDisponibles: cuposDisponibles),

              // --- AVISO DE ESTADO (DINÁMICO) ---
              if (ruta.estado != 'convocatoria')
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ruta.estado == 'en_curso'
                        ? Colors.green[50]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ruta.estado == 'en_curso'
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        ruta.estado == 'en_curso' ? Icons.live_tv : Icons.flag,
                        color: ruta.estado == 'en_curso'
                            ? Colors.green
                            : Colors.grey[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ruta.estado == 'en_curso'
                              ? "¡Esta ruta está EN CURSO ahora mismo!"
                              : "Esta ruta ha FINALIZADO",
                          style: TextStyle(
                            color: ruta.estado == 'en_curso'
                                ? Colors.green
                                : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // --- INFORMACIÓN DEL EVENTO (NUEVO) ---
              if (ruta.fechaEvento != null || ruta.puntoEncuentro != null) ...[
                const SizedBox(height: 20),
                _buildSectionTitle('📅 Información del Evento'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal[50]!, Colors.teal[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ruta.fechaEvento != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.calendar_month,
                                color: Colors.teal,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fecha y Hora',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatFechaCompleta(ruta.fechaEvento!),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _formatHoraCompleta(ruta.fechaEvento!),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.teal[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (ruta.puntoEncuentro != null) ...[
                        if (ruta.fechaEvento != null)
                          const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.orange,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Punto de Encuentro',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ruta.puntoEncuentro!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              _buildSectionTitle('Tu Guía'),
              _buildGuideProfile(context, ruta),

              // --- SECCIÓN EQUIPAMIENTO (NUEVO) ---
              if (ruta.equipamiento.isNotEmpty) ...[
                _buildSectionTitle('🎒 Equipamiento Necesario'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ruta.equipamiento
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const Divider(height: 40),
              ],

              const Divider(
                height: 40,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),

              _buildSectionTitle('Sobre la Experiencia'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  ruta.descripcion,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Itinerario'),
              _buildTimelineItinerary(ruta.lugaresIncluidos),

              const SizedBox(height: 120),
            ]),
          ),
        ],
      ),

      // --- BOTÓN INFERIOR INTELIGENTE ---
      bottomNavigationBar: _buildSmartBottomBar(
        context,
        ruta,
        esGuia,
        estaInscrito,
      ),
    );
  }

  Widget _buildSmartBottomBar(
    BuildContext context,
    Ruta ruta,
    bool esGuia,
    bool estaInscrito,
  ) {
    final vmRutas = context.read<RutasVM>();

    // CASO 1: SOY EL GUÍA
    if (esGuia) {
      if (ruta.estado == 'convocatoria') {
        return _buildBottomBtn(
          "INICIAR AVENTURA",
          Colors.green,
          Icons.play_arrow,
          () {
            vmRutas.cambiarEstadoRuta(ruta.id, 'en_curso');
          },
        );
      } else if (ruta.estado == 'en_curso') {
        return _buildBottomBtn("FINALIZAR RUTA", Colors.red, Icons.stop, () {
          vmRutas.cambiarEstadoRuta(ruta.id, 'finalizada');
        });
      } else {
        return _buildBottomBtn(
          "RUTA FINALIZADA",
          Colors.grey,
          Icons.flag,
          null,
        );
      }
    }

    // CASO 2: SOY TURISTA INSCRITO
    if (estaInscrito) {
      if (ruta.estado == 'en_curso') {
        if (ruta.asistio) {
          return _buildBottomBtn(
            "📸 SUBIR RECUERDO",
            Colors.purple,
            Icons.camera_alt,
            () async {
              // 1. Capturar foto
              final imagenServicio = ImagenServicio(); // O inyectado
              final urlFoto = await imagenServicio.seleccionarYSubir(
                'recuerdos',
              );

              if (urlFoto != null && context.mounted) {
                // 2. Obtener ubicación actual
                final position = await Geolocator.getCurrentPosition();

                // 3. Guardar en BD (Usando el repositorio directamente o vía VM)
                // Aquí un ejemplo rápido accediendo al repo (idealmente vía RutasVM)
                final repo =
                    context.read<LugaresRepositorio>()
                        as LugaresRepositorioSupabase;

                await repo.crearRecuerdo(
                  rutaId: ruta.id,
                  fotoUrl: urlFoto,
                  latitud: position.latitude,
                  longitud: position.longitude,
                  comentario: "¡Recuerdo de ${ruta.nombre}!",
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("¡Recuerdo guardado en tu mapa!"),
                    ),
                  );

                  // Recargar para que aparezca en el mapa
                  context.read<LugaresVM>().cargarMisRecuerdos();
                }
              }
            },
          );
        } else {
          return _buildBottomBtn(
            "📍 MARCAR ASISTENCIA",
            Colors.orange,
            Icons.location_on,
            () {
              vmRutas.marcarAsistencia(ruta.id);
            },
          );
        }
      } else if (ruta.estado == 'finalizada') {
        return _buildBottomBtn(
          "VER RECUERDOS",
          Colors.blue,
          Icons.photo_album,
          () {
            // Ir al mapa filtrado
          },
        );
      } else {
        // Convocatoria
        return _buildBottomBtn(
          "YA ESTÁS INSCRITO",
          Colors.grey,
          Icons.check,
          null,
        ); // O botón salir
      }
    }

    // CASO 3: TURISTA NO INSCRITO
    if (ruta.estado != 'convocatoria') {
      return _buildBottomBtn(
        "INSCRIPCIONES CERRADAS",
        Colors.grey,
        Icons.block,
        null,
      );
    }

    // Botón normal de reservar (tu lógica anterior)
    return _buildRegisterButton(
      context,
      context.read<AutenticacionVM>(),
      ruta,
      estaInscrito: false,
      cuposDisponibles: 10,
      esPropietario: false,
      esModoPreview: false,
    );
  }

  Widget _buildBottomBtn(
    String text,
    Color color,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES REDISEÑADOS ---

  Widget _buildInfoCard(
    BuildContext context,
    Ruta ruta, {
    required int cuposDisponibles,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            Icons.monetization_on_outlined,
            'S/ ${ruta.precio.toStringAsFixed(0)}',
            'Por persona',
            Colors.green,
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildInfoItem(
            Icons.calendar_today_outlined,
            '${ruta.dias} Día(s)',
            'Duración',
            Colors.blue,
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildInfoItem(
            _getIconForCategory(ruta.categoria), // Icono dinámico
            ruta.categoria,
            'Categoría', // Cambiamos 'Nivel' por 'Categoría' que suena mejor
            _getColorCategoria(
              ruta.categoria,
            ), // Usamos el color de la categoría
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  Widget _buildGuideProfile(BuildContext context, Ruta ruta) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: (ruta.guiaFotoUrl.isNotEmpty)
              ? NetworkImage(ruta.guiaFotoUrl)
              : null,
          child: (ruta.guiaFotoUrl.isEmpty)
              ? Text(ruta.guiaNombre.substring(0, 1))
              : null,
        ),
        title: Text(
          ruta.guiaNombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.verified,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            const Text('Guía Certificado Haku'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () {},
        ),
      ),
    );
  }

  // --- ITINERARIO TIPO LÍNEA DE TIEMPO ---
  Widget _buildTimelineItinerary(List<String> lugares) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: List.generate(lugares.length, (index) {
          final isLast = index == lugares.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Container(width: 2, height: 50, color: Colors.grey[300]),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lugares[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Parada ${index + 1}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRegisterButton(
    BuildContext context,
    AutenticacionVM vmAuth,
    Ruta ruta, {
    required bool estaInscrito,
    required int cuposDisponibles,
    required bool esPropietario,
    required bool esModoPreview,
  }) {
    final bool isRouteFull = cuposDisponibles <= 0;
    final bool isUserLoggedIn = vmAuth.estaLogueado;

    String buttonText;
    Color buttonColor;
    Color textColor = Colors.white;
    VoidCallback? onPressed;

    if (esPropietario && esModoPreview) {
      buttonText = 'VOLVER A EDITAR';
      buttonColor = Colors.black87;
      onPressed = () => context.pop();
    } else if (esPropietario && !esModoPreview) {
      buttonText = 'GESTIONAR MI RUTA';
      buttonColor = Colors.black87;
      onPressed = () => context.push('/rutas/crear-ruta', extra: ruta);
    } else if (estaInscrito) {
      buttonText = 'CANCELAR RESERVA';
      buttonColor = Colors.white;
      textColor = Colors.red;
      onPressed = () => _handleRegistration(context);
    } else if (isRouteFull) {
      buttonText = 'AGOTADO';
      buttonColor = Colors.grey;
      onPressed = null;
    } else if (!isUserLoggedIn) {
      buttonText = 'INICIA SESIÓN PARA RESERVAR';
      buttonColor = Theme.of(context).colorScheme.primary;
      onPressed = () => _handleRegistration(context);
    } else {
      buttonText = 'RESERVAR AHORA';
      buttonColor = Theme.of(context).colorScheme.primary;
      onPressed = () => _handleRegistration(context);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          side: estaInscrito
              ? const BorderSide(color: Colors.red)
              : BorderSide.none,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: estaInscrito ? 0 : 4,
        ),
        child: Text(
          buttonText,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  void _showLoginRequiredModal(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Únete a Haku'),
          content: Text('Necesitas iniciar sesión para $action.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/login');
              },
              child: const Text('Iniciar Sesión'),
            ),
          ],
        );
      },
    );
  }

  void _showPreviewModeWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estás en modo vista previa.')),
    );
  }

  String _formatFechaCompleta(DateTime fecha) {
    final dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${dias[fecha.weekday % 7]}, ${fecha.day} de ${meses[fecha.month - 1]} ${fecha.year}';
  }

  String _formatHoraCompleta(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto hrs';
  }
}
