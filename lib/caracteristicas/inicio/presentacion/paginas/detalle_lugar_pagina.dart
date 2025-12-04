import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM: IMPORTACIONES ---
import '../vista_modelos/lugares_vm.dart';
import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/comentario.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';

class DetalleLugarPagina extends StatefulWidget {
  final Lugar lugar;
  const DetalleLugarPagina({super.key, required this.lugar});

  @override
  State<DetalleLugarPagina> createState() => _DetalleLugarPaginaState();
}

class _DetalleLugarPaginaState extends State<DetalleLugarPagina> {
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
    if (!_checkAndRedirect(context, 'guardar este lugar')) return;
    context.read<LugaresVM>().toggleLugarFavorito(widget.lugar.id);
  }

  void _mostrarDialogoComentario(BuildContext context) {
    if (!_checkAndRedirect(context, 'escribir una reseña')) return;

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
    final vm = context.watch<LugaresVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    // LUGAR VIVO (Datos actualizados en tiempo real)
    final lugarVivo = vm.lugaresTotales.firstWhere(
      (l) => l.id == widget.lugar.id,
      orElse: () => widget.lugar,
    );

    final bool esFavorito = vm.esLugarFavorito(lugarVivo.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- 1. HEADER CINEMÁTICO ---
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            backgroundColor: colorPrimario,
            actions: [
              // Botón de Favorito con fondo para que se vea sobre cualquier foto
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: const BoxDecoration(
                  color: Colors.white24, // Semi-transparente
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _onToggleFavorito(context),
                  icon: Icon(
                    esFavorito ? Icons.favorite : Icons.favorite_border,
                    color: esFavorito ? Colors.red : Colors.white,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              // El título se mueve al cuerpo para un diseño más limpio,
              // aquí dejamos solo la imagen.
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    lugarVivo.urlImagen,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                  ),
                  // Gradiente inferior para transición suave
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 2. CUERPO DE LA PÁGINA ---
          SliverList(
            delegate: SliverChildListDelegate([
              // Contenedor principal que "sube" un poco sobre la imagen (Efecto Tarjeta)
              Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TÍTULO Y CATEGORÍA
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lugarVivo.nombre,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // --- INFO ROW (NUEVO DISEÑO ESTILO AIRBNB) ---
                      _buildModernInfoRow(context, lugarVivo),

                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),

                      Text(
                        'Descripción',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Descripción
                      GestureDetector(
                        onTap: () => setState(
                          () =>
                              _isDescriptionExpanded = !_isDescriptionExpanded,
                        ),
                        child: Text(
                          lugarVivo.descripcion,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          maxLines: _isDescriptionExpanded ? null : 4,
                          overflow: _isDescriptionExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ),
                      if (lugarVivo.descripcion.length > 150)
                        TextButton(
                          onPressed: () => setState(
                            () => _isDescriptionExpanded =
                                !_isDescriptionExpanded,
                          ),
                          child: Text(
                            _isDescriptionExpanded ? "Leer menos" : "Leer más",
                            style: TextStyle(color: colorPrimario),
                          ),
                        ),

                      const SizedBox(height: 24),
                      _buildMapSection(context, lugarVivo),

                      const SizedBox(height: 24),

                      // Gráfica
                      _buildReviewsSummary(context, lugarVivo, vm.comentarios),

                      const SizedBox(height: 24),
                      Text(
                        'Comentarios (${vm.comentarios.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (vm.estaCargandoComentarios)
                        const Center(child: CircularProgressIndicator())
                      else if (vm.comentarios.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              "Aún no hay reseñas. ¡Sé el primero!",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else ...[
                        for (var c in vm.comentarios) _buildComentarioCard(c),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoComentario(context),
        label: const Text('Escribir Reseña'),
        icon: const Icon(Icons.create),
        backgroundColor: colorPrimario,
      ),
    );
  }

  // --- NUEVO DISEÑO DE LA FILA DE INFORMACIÓN ---
  Widget _buildModernInfoRow(BuildContext context, Lugar lugar) {
    final color = Theme.of(context).colorScheme.primary;

    // Formateo del rating
    String ratingStr = lugar.rating > 0
        ? lugar.rating.toStringAsFixed(1)
        : "Nuevo";

    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfoItem(
            Icons.access_time_filled_rounded,
            lugar.horario,
            "Horario Recomendado",
            color,
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]), // Separador
          _buildInfoItem(
            Icons.star_rounded,
            ratingStr,
            "Calificación",
            Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  // --- GRÁFICA DE BARRAS (IGUAL QUE ANTES) ---
  Widget _buildReviewsSummary(
    BuildContext context,
    Lugar lugar,
    List<Comentario> comentarios,
  ) {
    Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var c in comentarios) {
      int star = c.rating.round().clamp(1, 5);
      counts[star] = (counts[star] ?? 0) + 1;
    }
    int total = comentarios.length;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                lugar.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Row(
                children: [
                  for (int i = 0; i < 5; i++)
                    Icon(
                      i < lugar.rating.round() ? Icons.star : Icons.star_border,
                      size: 12,
                      color: Colors.amber,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "$total reseñas",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                int count = counts[star] ?? 0;
                double pct = total == 0 ? 0 : count / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        "$star",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.grey[300],
                          color: Colors.amber,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(BuildContext context, Lugar lugar) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[200],
        image: const DecorationImage(
          image: AssetImage(
            'assets/imagenes/mapa_textura.png',
          ), // Textura de fondo si tienes
          fit: BoxFit.cover,
          opacity: 0.5,
        ),
      ),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () => context.push('/mapa-lugar', extra: lugar),
          icon: const Icon(Icons.map),
          label: const Text('Ver ubicación exacta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildComentarioCard(Comentario c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
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
                radius: 16,
                backgroundImage: (c.usuarioFotoUrl.isNotEmpty)
                    ? NetworkImage(c.usuarioFotoUrl)
                    : null,
                backgroundColor: Colors.grey[300],
                child: (c.usuarioFotoUrl.isEmpty)
                    ? Text(
                        c.usuarioNombre.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.usuarioNombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      c.fecha,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      c.rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            c.texto,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredModal(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Únete a nosotros!'),
        content: Text('Para $action necesitas una cuenta. Es gratis y rápido.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Quizás luego',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/login');
            },
            child: const Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }
}

// --- DIÁLOGO INTERNO (Sin cambios funcionales) ---
class _DialogoComentario extends StatefulWidget {
  final String lugarId;
  final String lugarNombre;
  const _DialogoComentario({required this.lugarId, required this.lugarNombre});
  @override
  State<_DialogoComentario> createState() => _DialogoComentarioState();
}

class _DialogoComentarioState extends State<_DialogoComentario> {
  final _ctrl = TextEditingController();
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Califica ${widget.lugarNombre}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "¿Qué te pareció esta experiencia?",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                icon: Icon(
                  i < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () => setState(() => _rating = i + 1.0),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Cuéntanos más (opcional)...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            if (_rating > 0) {
              await context.read<LugaresVM>().enviarComentario(
                widget.lugarId,
                _ctrl.text,
                _rating,
              );
              if (mounted) Navigator.pop(context);
            }
          },
          child: const Text('Publicar'),
        ),
      ],
    );
  }
}
