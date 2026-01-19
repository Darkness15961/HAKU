import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM ---
import '../vista_modelos/lugares_vm.dart';
import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/comentario.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';

class DetalleLugarPagina extends StatefulWidget {
  // AHORA ACEPTA UNO U OTRO (Objeto o ID)
  final Lugar? lugar;
  final String? lugarId;

  const DetalleLugarPagina({super.key, this.lugar, this.lugarId});

  @override
  State<DetalleLugarPagina> createState() => _DetalleLugarPaginaState();
}

class _DetalleLugarPaginaState extends State<DetalleLugarPagina> {
  bool _isDescriptionExpanded = false;

  // Getter inteligente: Saca el ID de donde venga
  String get _idLugar => widget.lugar?.id ?? widget.lugarId ?? '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final vmAuth = context.read<AutenticacionVM>();
      context.read<LugaresVM>().cargarDatosIniciales(vmAuth);
      // Usamos el ID seguro
      if (_idLugar.isNotEmpty) {
        context.read<LugaresVM>().cargarComentarios(_idLugar);
      }
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
    context.read<LugaresVM>().toggleLugarFavorito(_idLugar);
  }

  void _mostrarDialogoComentario(BuildContext context, String nombreLugar) {
    if (!_checkAndRedirect(context, 'escribir una reseña')) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ChangeNotifierProvider.value(
          value: context.read<LugaresVM>(),
          child: _DialogoComentario(
            lugarId: _idLugar,
            lugarNombre: nombreLugar,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LugaresVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    Lugar? lugarVivo;
    try {
      if (_idLugar.isNotEmpty) {
        lugarVivo = vm.lugaresTotales.firstWhere((l) => l.id == _idLugar);
      }
    } catch (_) {}
    lugarVivo ??= widget.lugar;

    if (lugarVivo == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: colorPrimario, leading: const BackButton(color: Colors.white)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool esFavorito = vm.esLugarFavorito(lugarVivo.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. HERO HEADER PREMIUM
          SliverAppBar(
            expandedHeight: 450.0, // Más alto para impacto visual
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: const BackButton(color: Colors.white),
              ),
            ),
            actions: [
              if (vm.estaCargandoGestion)
                const Center(child: CircularProgressIndicator(color: Colors.white))
              else if (lugarVivo.usuarioId == context.read<AutenticacionVM>().usuarioActual?.id ||
                  context.read<AutenticacionVM>().usuarioActual?.rol == 'admin')
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    tooltip: 'Editar Lugar',
                    onPressed: () => context.push('/admin/crear-lugar', extra: lugarVivo),
                  ),
                ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                child: IconButton(
                  onPressed: () => _onToggleFavorito(context),
                  icon: Icon(
                    esFavorito ? Icons.favorite : Icons.favorite_border,
                    color: esFavorito ? const Color(0xFFFF6B6B) : Colors.white,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'lugar_imagen_${lugarVivo.id}',
                    child: Image.network(
                      lugarVivo.urlImagen,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                    ),
                  ),
                  // Gradiente cinemático
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40, // Dejar espacio para el container superpuesto
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Rating ${lugarVivo.rating.toStringAsFixed(1)}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lugarVivo.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            // Si tuvieras provincia nombre aquí sería genial, si no:
                            Text("Cusco, Perú", style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. CONTENIDO SCROLLABLE (Overlapping)
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20), // Efecto de solapamiento
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Row con estilo
                    _buildPremiumInfoRow(context, lugarVivo),
                    const SizedBox(height: 32),

                    // Descripción
                    Text("Sobre este lugar", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
                    const SizedBox(height: 12),
                    Text(
                      lugarVivo.descripcion,
                      style: TextStyle(fontSize: 16, height: 1.6, color: Colors.blueGrey[700]),
                    ),
                    const SizedBox(height: 32),

                    // Mapa Preview Mejorado
                    _buildPremiumMapPreview(context, lugarVivo),
                    const SizedBox(height: 32),

                    // Reseñas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Reseñas", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
                        Text("${vm.comentarios.length} comentarios", style: TextStyle(color: Colors.blueGrey[400])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (vm.estaCargandoComentarios)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (vm.comentarios.isEmpty)
                      _buildEmptyState("Sé el primero en compartir tu experiencia.")
                    else
                      ...vm.comentarios.map((c) => _buildPremiumCommentCard(c)),
                    
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoComentario(context, lugarVivo!.nombre),
        backgroundColor: const Color(0xFF00BCD4),
        elevation: 4,
        icon: const Icon(Icons.edit_note),
        label: const Text("Escribir Reseña", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- WIDGETS PREMIUM ---

  Widget _buildPremiumInfoRow(BuildContext context, Lugar lugar) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueGrey[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(Icons.access_time_filled, lugar.horario.isNotEmpty ? lugar.horario : "Todo el día", "Horario", Colors.blue),
          Container(width: 1, height: 40, color: Colors.blueGrey[200]),
          _buildInfoItem(Icons.reviews, "${lugar.reviewsCount} Reseñas", "Popularidad", Colors.orange),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildPremiumMapPreview(BuildContext context, Lugar lugar) {
    return GestureDetector(
      onTap: () => context.push('/mapa-lugar', extra: lugar),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.grey[200],
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
          image: const DecorationImage(
            image: NetworkImage("https://mt1.google.com/vt/lyrs=m&x=0&y=0&z=1"), // Placeholder genérico de mapa o usar asset
            fit: BoxFit.cover,
            opacity: 0.6,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
             Container(
               decoration: BoxDecoration(
                 gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.5)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                 borderRadius: BorderRadius.circular(24),
               ),
             ),
             Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Icon(Icons.map_outlined, color: Colors.white, size: 40),
                 const SizedBox(height: 8),
                 const Text("Ver Ubicación en Mapa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                 Text("Toca para explorar", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
               ],
             )
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCommentCard(Comentario c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Fondo limpio
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: c.usuarioFotoUrl.isNotEmpty ? NetworkImage(c.usuarioFotoUrl) : null,
                backgroundColor: Colors.indigo.shade50,
                child: c.usuarioFotoUrl.isEmpty ? Text(c.usuarioNombre[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.usuarioNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(c.fecha, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [const Icon(Icons.star, size: 14, color: Colors.amber), const SizedBox(width: 4), Text(c.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber))]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(c.texto, style: TextStyle(fontSize: 14, color: Colors.blueGrey[800], height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[500]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showLoginRequiredModal(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF00BCD4),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Acción Requerida',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00BCD4),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Necesitas iniciar sesión o crear una cuenta para $action.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Seguir Explorando',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Iniciar Sesión',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        );
      },
    );
  }
}

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
      title: Text('Calificar ${widget.lugarNombre}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: List.generate(5, (i) => IconButton(icon: Icon(i < _rating ? Icons.star : Icons.star_border, color: Colors.amber), onPressed: () => setState(() => _rating = i + 1.0)))),
        TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Comentario')),
      ]),
      actions: [
        ElevatedButton(onPressed: () async {
          if (_rating > 0) { await context.read<LugaresVM>().enviarComentario(widget.lugarId, _ctrl.text, _rating); if(mounted) Navigator.pop(context); }
        }, child: const Text('Enviar'))
      ],
    );
  }
}