// --- PIEDRA 6.6: EL "MENÚ" DE DETALLE DE LUGAR (¡SEGURIDAD CONECTADA!) ---
//
// Esta es la versión FINAL y DEFINITIVA.
// 1. Conectada al "Mesero de Comida" (LugaresVM).
// 2. Conectada al "Mesero de Seguridad" (AutenticacionVM).
// 3. Implementa el "Bloqueo Suave" (Modal) para anónimos.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM: IMPORTACIONES ---
import '../vista_modelos/lugares_vm.dart'; // Mesero de Comida
import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/comentario.dart';

// --- ¡CONEXIÓN DE SEGURIDAD! ---
// 1. Importamos el "Mesero de Seguridad"
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';

class DetalleLugarPagina extends StatefulWidget {
  final Lugar lugar;
  const DetalleLugarPagina({super.key, required this.lugar});
  @override
  State<DetalleLugarPagina> createState() => _DetalleLugarPaginaState();
}

class _DetalleLugarPaginaState extends State<DetalleLugarPagina> {
  bool _isDescriptionExpanded = false; // Estado local para la "Cortina"

  @override
  void initState() {
    super.initState();
    // Le da la "orden" al "Mesero de Comida" de cargar los comentarios
    Future.microtask(() {
      context.read<LugaresVM>().cargarComentarios(widget.lugar.id);
    });
  }

  // --- Lógica de Seguridad (Bloqueo Suave) ---

  // --- ¡NUEVA FUNCIÓN DE SEGURIDAD! ---
  // Esta función es el "Guardia" de la página.
  // Revisa si el usuario está logueado ANTES de hacer una acción.
  bool _checkAndRedirect(BuildContext context, String action) {
    // 1. "Lee" (read) el estado del "Mesero de Seguridad"
    final authVM = context.read<AutenticacionVM>();

    // 2. Revisa si NO está logueado
    if (!authVM.estaLogueado) {
      // 3. Si es anónimo, muestra el "Modal de Invitación"
      _showLoginRequiredModal(context, action);
      return false; // Devuelve "false" (ACCIÓN BLOQUEADA)
    }
    // 4. Si está logueado, devuelve "true" (ACCIÓN PERMITIDA)
    return true;
  }

  // --- Lógica de Acciones (Conectadas al "Mesero") ---

  // ¡ACCIÓN ACTUALIZADA CON SEGURIDAD!
  void _marcarFavorito(BuildContext context) {
    // 1. Llama al "Guardia"
    if (!_checkAndRedirect(context, 'guardar este lugar')) {
      return; // Si el "Guardia" devuelve "false", se detiene aquí.
    }

    // 2. Si el "Guardia" da permiso (devuelve "true")...
    //    ...le damos la orden al "Mesero de Comida"
    context.read<LugaresVM>().marcarFavorito(widget.lugar.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Guardado en favoritos! (Simulado)'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // ¡ACCIÓN ACTUALIZADA CON SEGURIDAD!
  void _mostrarDialogoComentario(BuildContext context) {
    // 1. Llama al "Guardia"
    if (!_checkAndRedirect(context, 'escribir una reseña')) {
      return; // Si es anónimo, se detiene aquí.
    }

    // 2. Si el "Guardia" da permiso (está logueado)...
    //    ...mostramos el diálogo
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _DialogoComentario(
          lugarId: widget.lugar.id,
          lugarNombre: widget.lugar.nombre,
        );
      },
    );
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext context) {
    // "Escuchamos" al "Mesero de Comida"
    final vm = context.watch<LugaresVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- 1. La Barra de App (SliverAppBar) ---
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            stretch: true,
            backgroundColor: colorPrimario,
            actions: [
              IconButton(
                // ¡CONECTADO A LA SEGURIDAD!
                onPressed: () => _marcarFavorito(context),
                icon: const Icon(Icons.favorite_border), // TODO: Lógica de estado fav
                tooltip: 'Guardar en Favoritos',
              ),
              IconButton(
                onPressed: () {
                  /* Lógica de Compartir */
                },
                icon: const Icon(Icons.share, color: Colors.white),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 20),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lugar.nombre,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 4.0, color: Colors.black54)],
                    ),
                  ),
                  _buildRatingStarsWithLikes(
                      widget.lugar.rating, widget.lugar.reviewsCount,
                      likes: widget.lugar.reviewsCount ~/ 2),
                ],
              ),
              background: Hero(
                tag: 'lugar_imagen_${widget.lugar.id}',
                child: Image.network(
                  widget.lugar.urlImagen,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.4),
                  colorBlendMode: BlendMode.darken,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colorPrimario.withOpacity(0.1),
                    child: Center(
                      child: Icon(Icons.image_search,
                          size: 60, color: colorPrimario),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- 2. Contenido del Cuerpo (SliverList) ---
          SliverList(
            delegate: SliverChildListDelegate(
              [
                // Bloque 1: Info Clave (Corregido)
                Padding(
                  padding:
                  const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildInfoChip(Icons.schedule, 'Horario', widget.lugar.horario),
                      _buildInfoChip(
                          Icons.local_atm, 'Costo', widget.lugar.costoEntrada),
                      _buildInfoChip(
                          Icons.landscape, 'Tipo', widget.lugar.categoria),
                    ],
                  ),
                ),

                // Bloque 2: Descripción (con "Cortina")
                _buildDescriptionSection(widget.lugar.descripcion),

                // Bloque 3: Puntos de Interés
                _buildSubPlacesSection(widget.lugar.puntosInteres),

                // Bloque 4: Mapa
                _buildMapSection(),

                // Bloque 5: Resumen de Opiniones
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: _buildReviewsSummary(
                      widget.lugar, vm.comentarios.length),
                ),

                const Divider(height: 30, thickness: 1),

                // Bloque 6: Comentarios
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                  child: Text(
                    'Comentarios',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

                // Lista de Comentarios (con "Ver Todas")
                vm.estaCargandoComentarios
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
                    : (vm.comentarios.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Text('Aún no hay reseñas. ¡Sé el primero!'),
                  ),
                )
                    : Column(
                  children: [
                    // 1. Mostrar 1 Destacado
                    _buildComentarioCard(vm.comentarios.first),

                    // 2. Botón "Ver todas" (si hay más de 1)
                    if (vm.comentarios.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 8.0, bottom: 16.0),
                        child: TextButton.icon(
                          onPressed: () {
                            // ¡Esto ahora funciona!
                            context.push('/comentarios');
                          },
                          icon: const Icon(Icons.arrow_right_alt),
                          label: Text(
                              'Ver todas las ${vm.comentarios.length} reseñas',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                      )
                  ],
                )),
                const SizedBox(height: 100), // Espacio para el Botón Flotante
              ],
            ),
          ),
        ],
      ),

      // --- Botón Flotante (CON SEGURIDAD) ---
      floatingActionButton: FloatingActionButton.extended(
        // ¡CONECTADO A LA SEGURIDAD!
        onPressed: () => _mostrarDialogoComentario(context),
        label: const Text('Añadir Reseña'),
        icon: const Icon(Icons.edit),
        backgroundColor: colorPrimario,
      ),
    );
  }

  // --- WIDGET AUXILIAR: MODAL DE INVITACIÓN (Bloqueo Suave) ---
  void _showLoginRequiredModal(BuildContext context, String action) {
    final colorPrimario = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Acción Requerida 🔒'),
          content:
          Text('Necesitas iniciar sesión o crear una cuenta para $action.'),
          actions: [
            // Botón para que NO se sienta atrapado
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Seguir Explorando',
                  style: TextStyle(color: Colors.grey)),
            ),
            // Botón de Conversión (a Login)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/login'); // Usamos el GPS para ir al Login
              },
              style: ElevatedButton.styleFrom(backgroundColor: colorPrimario),
              child: const Text('Iniciar Sesión',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- WIDGETS AUXILIARES (Expandidos) ---

  // 1. Grilla de Info Clave
  Widget _buildKeyInfoGrid(Lugar lugar) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _buildInfoChip(Icons.schedule, 'Horario', lugar.horario),
          _buildInfoChip(Icons.local_atm, 'Costo', lugar.costoEntrada),
          _buildInfoChip(Icons.landscape, 'Tipo', lugar.categoria),
        ],
      ),
    );
  }

  // 2. Chip de Información
  Widget _buildInfoChip(IconData icon, String title, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.indigo, size: 24),
            const SizedBox(height: 4),
            Text(value,
                style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            Text(title,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 1),
          ],
        ),
      ),
    );
  }

  // 3. Sección de Descripción (La "Cortina")
  Widget _buildDescriptionSection(String fullDescription) {
    const int thresholdLength = 200;
    final bool needsExpansion = fullDescription.length > thresholdLength;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen / Qué ver',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            fullDescription,
            style: const TextStyle(fontSize: 16, height: 1.4, color: Colors.black87),
            maxLines: _isDescriptionExpanded ? null : 4,
            overflow: _isDescriptionExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
          if (needsExpansion)
            TextButton(
              onPressed: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Text(
                _isDescriptionExpanded ? 'Ver menos' : 'Ver más',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
        ],
      ),
    );
  }

  // 4. Puntos de Interés
  Widget _buildSubPlacesSection(List<String> subPlaces) {
    if (subPlaces.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Puntos de Interés en el Complejo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: subPlaces
                .map((place) => Chip(
              label:
              Text(place, style: const TextStyle(fontSize: 14)),
              backgroundColor: Colors.indigo.shade50,
              labelStyle: const TextStyle(color: Colors.indigo),
              avatar: const Icon(Icons.check_circle,
                  size: 16, color: Colors.indigo),
              padding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // 5. Sección de Mapa
  Widget _buildMapSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ubicación en el Mapa',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[200],
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Abriendo ubicación en el mapa...')),
                  );
                },
                icon: const Icon(Icons.map, color: Colors.white),
                label: const Text('Abrir en Mapas',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Resumen de Opiniones
  Widget _buildReviewsSummary(Lugar lugar, int totalComentarios) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    children: [
                      Text(lugar.rating.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary)),
                      Text('($totalComentarios reseñas)',
                          style:
                          TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: List.generate(5, (index) {
                        int star = 5 - index;
                        double percentage = star / 5;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Text('$star★',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  backgroundColor: Colors.grey[200],
                                  color: Colors.indigo,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 7. Tarjeta de Comentario
  Widget _buildComentarioCard(Comentario comentario) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(comentario.usuarioFotoUrl),
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comentario.usuarioNombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(comentario.fecha,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Icon(Icons.star,
                          color: Colors.amber.shade600, size: 16),
                      const SizedBox(width: 4),
                      Text(comentario.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                comentario.texto,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 8. Estrellas de Rating
  Widget _buildRatingStars(double rating, int reviews, {bool small = false}) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    double size = small ? 14 : 18;

    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            if (index < fullStars) {
              return Icon(Icons.star, color: Colors.amber, size: size);
            } else if (index == fullStars && hasHalfStar) {
              return Icon(Icons.star_half, color: Colors.amber, size: size);
            } else {
              return Icon(Icons.star_border, color: Colors.amber, size: size);
            }
          }),
        ),
        if (!small) ...[
          const SizedBox(width: 4),
          Text(
            '$rating ($reviews)',
            style: const TextStyle(
                fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ]
      ],
    );
  }

  // 9. Nuevo Widget para Rating en AppBar (con Likes)
  Widget _buildRatingStarsWithLikes(double rating, int reviews,
      {required int likes}) {
    double size = 14;
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(5, (index) {
              if (index < rating.floor()) {
                return Icon(Icons.star,
                    color: Colors.amber.shade400, size: size);
              } else if (index == rating.floor() &&
                  (rating - rating.floor()) >= 0.5) {
                return Icon(Icons.star_half,
                    color: Colors.amber.shade400, size: size);
              } else {
                return Icon(Icons.star_border,
                    color: Colors.amber.shade400, size: size);
              }
            }),
          ),
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 4.0, color: Colors.black54)]),
          ),
          const SizedBox(width: 12),
          Icon(Icons.favorite, color: Colors.red.shade300, size: size),
          const SizedBox(width: 4),
          Text(
            '${(likes / 1000).toStringAsFixed(1)}k',
            style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 4.0, color: Colors.black54)]),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET DE DIÁLOGO (Separado y con estado propio) ---

class _DialogoComentario extends StatefulWidget {
  final String lugarId;
  final String lugarNombre;
  const _DialogoComentario({required this.lugarId, required this.lugarNombre});
  @override
  State<_DialogoComentario> createState() => _DialogoComentarioState();
}

class _DialogoComentarioState extends State<_DialogoComentario> {
  // Estado local para el formulario del diálogo
  double _ratingSeleccionado = 0; // 0 = no seleccionado
  final TextEditingController _tituloCtrl = TextEditingController();
  final TextEditingController _resenaCtrl = TextEditingController();
  bool _esAnonimo = false;
  bool _estaEnviando = false; // Para mostrar un spinner en el botón

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _resenaCtrl.dispose();
    super.dispose();
  }

  // Función de envío (conectada al "Mesero")
  Future<void> _enviarResena(BuildContext dialogContext) async {
    // Validación simple
    if (_ratingSeleccionado == 0) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(
          content: Text('Por favor, selecciona una calificación de estrellas.'),
          backgroundColor: Colors.red));
      return;
    }
    if (_resenaCtrl.text.isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(
          content: Text('Por favor, escribe tu reseña.'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _estaEnviando = true);

    // --- MVVM: ORDEN AL "MESERO" ---
    await dialogContext.read<LugaresVM>().enviarComentario(
      widget.lugarId,
      _resenaCtrl.text,
      _ratingSeleccionado,
    );

    if (mounted) {
      setState(() => _estaEnviando = false);
    }

    if (mounted) {
      Navigator.of(dialogContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('¡Gracias! Tu reseña fue enviada.'),
            backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- HEADER (Tu diseño) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Tu reseña de ${widget.lugarNombre}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00569A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // --- CUERPO DEL FORMULARIO (Scrollable) ---
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Tu calificación general',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    // --- ¡ARREGLO DE DISEÑO (Tu Petición)! ---
                    // Estrellas ahora son doradas
                    _buildStarRatingSelector(),
                    const SizedBox(height: 16),
                    const Text('Título de tu reseña (opcional)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const TextField(
                        decoration: InputDecoration(
                          hintText: '¿Qué fue lo más destacado?',
                          border: OutlineInputBorder(),
                          isDense: true,
                        )),
                    const SizedBox(height: 16),
                    const Text('Tu reseña',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                        controller: _resenaCtrl,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                          'Comparte los detalles de tu propia experiencia...',
                          border: OutlineInputBorder(),
                        )),
                    const SizedBox(height: 16),
                    const Text('Añadir fotos (Próximamente)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildPhotoUploadArea(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                            value: _esAnonimo,
                            onChanged: (val) {
                              setState(() => _esAnonimo = val ?? false);
                            },
                            activeColor: Colors.indigo),
                        const Text('Publicar como anónimo',
                            style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // --- FOOTER (Botón de Enviar) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _estaEnviando ? null : () => _enviarResena(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _estaEnviando
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                      CircularProgressIndicator(color: Colors.white),
                    )
                        : const Text('Enviar Reseña',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Al publicar, aceptas nuestras políticas de la comunidad.',
                    style:
                    TextStyle(fontSize: 10, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // (Tu widget de estrellas, ahora con estado)
  Widget _buildStarRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final rating = index + 1.0;
        return IconButton(
          icon: Icon(
            _ratingSeleccionado >= rating ? Icons.star : Icons.star_border,
            // --- ¡ARREGLO DE DISEÑO (Tu Petición)! ---
            // El color siempre es dorado, no plomo
            color: Colors.amber.shade600,
            size: 40,
          ),
          onPressed: () {
            setState(() {
              _ratingSeleccionado = rating;
            });
          },
        );
      }),
    );
  }

  // (Tu widget de subir fotos)
  Widget _buildPhotoUploadArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 1.0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Arrastra y suelta o ',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              children: const [
                TextSpan(
                  text: 'pulsa para seleccionar',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text('(Próximamente)',
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

