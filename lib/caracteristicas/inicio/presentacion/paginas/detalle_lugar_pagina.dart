// --- PIEDRA 6.6: EL "MENÚ" DE DETALLE DE LUGAR (ACOMPLADO PARA NAVEGACIÓN) ---
//
// (...)
// 2. (¡FUNCIONAL!): El botón "Abrir en Mapas" ahora NAVEGA a una
//    nueva página de mapa simple ('/mapa-lugar') y pasa el lugar.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM: IMPORTACIONES ---
import '../vista_modelos/lugares_vm.dart';
import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/comentario.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';

// (La importación del MapaVM ya no es necesaria aquí)

class DetalleLugarPagina extends StatefulWidget {
  final Lugar lugar;
  const DetalleLugarPagina({super.key, required this.lugar});
  @override
  State<DetalleLugarPagina> createState() => _DetalleLugarPaginaState();
}

class _DetalleLugarPaginaState extends State<DetalleLugarPagina> {
  // (Tu código de initState, logic, etc., va aquí intacto...)
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final vmAuth = context.read<AutenticacionVM>();
      context.read<LugaresVM>().cargarDatosIniciales(vmAuth);
      context.read<LugaresVM>().cargarComentarios(widget.lugar.id);
    });
  }

  bool _checkAndRedirect(BuildContext context, String action) {
    final authVM = context.read<AutenticacionVM>();
    if (!authVM.estaLogueado) {
      _showLoginRequiredModal(context, action);
      return false;
    }
    return true;
  }

  void _onToggleFavorito(BuildContext context) {
    if (!_checkAndRedirect(context, 'guardar este lugar')) {
      return;
    }
    context.read<LugaresVM>().toggleLugarFavorito(widget.lugar.id);
  }

  void _mostrarDialogoComentario(BuildContext context) {
    if (!_checkAndRedirect(context, 'escribir una reseña')) {
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ChangeNotifierProvider.value(
          value: context.read<LugaresVM>(),
          child: _DialogoComentario(
            lugarId: widget.lugar.id,
            lugarNombre: widget.lugar.nombre,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // (Tu código de build() va aquí intacto...)
    final vm = context.watch<LugaresVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;
    final bool esFavorito = vm.esLugarFavorito(widget.lugar.id);

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
                onPressed: () => _onToggleFavorito(context),
                icon: Icon(
                  esFavorito ? Icons.favorite : Icons.favorite_border,
                  color: esFavorito ? Colors.red : Colors.white,
                ),
                tooltip: 'Guardar en Favoritos',
              ),
              IconButton(
                onPressed: () { /* Lógica de Compartir */ },
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
                _buildDescriptionSection(widget.lugar.descripcion),
                _buildSubPlacesSection(widget.lugar.puntosInteres),

                // --- ¡MODIFICADO! ---
                // Pasamos el context al widget
                _buildMapSection(context),
                // --- FIN DE LA MODIFICACIÓN ---

                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: _buildReviewsSummary(
                      widget.lugar, vm.comentarios.length),
                ),
                const Divider(height: 30, thickness: 1),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                  child: Text(
                    'Comentarios',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
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
                    _buildComentarioCard(vm.comentarios.first),
                    if (vm.comentarios.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 8.0, bottom: 16.0),
                        child: TextButton.icon(
                          onPressed: () {
                            context.push('/inicio/comentarios', extra: widget.lugar);
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
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoComentario(context),
        label: const Text('Añadir Reseña'),
        icon: const Icon(Icons.edit),
        backgroundColor: colorPrimario,
      ),
    );
  }

  // --- WIDGET AUXILIAR: MODAL DE INVITACIÓN (se mantiene) ---
  void _showLoginRequiredModal(BuildContext context, String action) {
    // (Tu código intacto aquí...)
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Seguir Explorando',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/login');
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

  // --- (Todos los demás widgets auxiliares se mantienen) ---

  Widget _buildInfoChip(IconData icon, String title, String value) {
    // (Tu código intacto aquí...)
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

  Widget _buildDescriptionSection(String fullDescription) {
    // (Tu código intacto aquí...)
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

  Widget _buildSubPlacesSection(List<String> subPlaces) {
    // (Tu código intacto aquí...)
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

  // --- ¡WIDGET MODIFICADO! ---
  Widget _buildMapSection(BuildContext context) { // <-- Ahora recibe context
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
                // --- ¡AQUÍ ESTÁ LA LÓGICA CORREGIDA! ---
                onPressed: () {
                  // Ya no necesitamos al MapaVM
                  // 1. Navegamos a la nueva página '/mapa-lugar'
                  // 2. Pasamos el 'lugar' actual como 'extra'
                  context.push('/mapa-lugar', extra: widget.lugar);
                },
                // --- FIN DE LA CORRECCIÓN ---
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
  // --- FIN DE LA MODIFICACIÓN ---

  Widget _buildReviewsSummary(Lugar lugar, int totalComentarios) {
    // (Tu código intacto aquí...)
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
                        double percentage = star / 5; // Simulación
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

  Widget _buildComentarioCard(Comentario comentario) {
    // (Tu código intacto aquí...)
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

  Widget _buildRatingStars(double rating, int reviews, {bool small = false}) {
    // (Tu código intacto aquí...)
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

  Widget _buildRatingStarsWithLikes(double rating, int reviews,
      {required int likes}) {
    // (Tu código intacto aquí...)
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
  // (Tu código intacto del diálogo va aquí...)
  final String lugarId;
  final String lugarNombre;
  const _DialogoComentario({required this.lugarId, required this.lugarNombre});
  @override
  State<_DialogoComentario> createState() => _DialogoComentarioState();
}

class _DialogoComentarioState extends State<_DialogoComentario> {
  // (Tu código intacto del estado del diálogo va aquí...)
  double _ratingSeleccionado = 0;
  final TextEditingController _tituloCtrl = TextEditingController();
  final TextEditingController _resenaCtrl = TextEditingController();
  bool _esAnonimo = false;
  bool _estaEnviando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _resenaCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarResena(BuildContext dialogContext) async {
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

    await context.read<LugaresVM>().enviarComentario(
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
    // (Tu código intacto del build del diálogo va aquí...)
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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

  Widget _buildStarRatingSelector() {
    // (Tu código intacto aquí...)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final rating = index + 1.0;
        return IconButton(
          icon: Icon(
            _ratingSeleccionado >= rating ? Icons.star : Icons.star_border,
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

  Widget _buildPhotoUploadArea() {
    // (Tu código intacto aquí...)
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