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

    // LÓGICA DE SEGURIDAD: Buscamos el lugar en memoria
    Lugar? lugarVivo;

    // 1. Intentamos buscarlo en la lista cargada (lo más fresco)
    try {
      if (_idLugar.isNotEmpty) {
        lugarVivo = vm.lugaresTotales.firstWhere((l) => l.id == _idLugar);
      }
    } catch (_) {}

    // 2. Si falló, usamos el que nos pasaron por parámetro
    lugarVivo ??= widget.lugar;

    // 3. Si sigue siendo nulo (ej: recarga de página web o link directo), mostramos carga
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
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            backgroundColor: colorPrimario,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: const BoxDecoration(
                  color: Colors.white24,
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
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    lugarVivo.urlImagen,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lugarVivo.nombre,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.1),
                      ),
                      const SizedBox(height: 24),
                      _buildModernInfoRow(context, lugarVivo),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      Text('Descripción', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                        child: Text(
                          lugarVivo.descripcion,
                          style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
                          maxLines: _isDescriptionExpanded ? null : 4,
                          overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        ),
                      ),
                      if (lugarVivo.descripcion.length > 150)
                        TextButton(
                          onPressed: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                          child: Text(_isDescriptionExpanded ? "Leer menos" : "Leer más", style: TextStyle(color: colorPrimario)),
                        ),
                      const SizedBox(height: 24),
                      _buildMapSection(context, lugarVivo),
                      const SizedBox(height: 24),
                      _buildReviewsSummary(context, lugarVivo, vm.comentarios),
                      const SizedBox(height: 24),
                      Text('Comentarios (${vm.comentarios.length})', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (vm.estaCargandoComentarios)
                        const Center(child: CircularProgressIndicator())
                      else if (vm.comentarios.isEmpty)
                        Container(padding: const EdgeInsets.all(20), child: const Center(child: Text("Sé el primero en comentar.", style: TextStyle(color: Colors.grey))))
                      else
                        ...vm.comentarios.map((c) => _buildComentarioCard(c)),
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
        onPressed: () => _mostrarDialogoComentario(context, lugarVivo!.nombre),
        label: const Text('Escribir Reseña'),
        icon: const Icon(Icons.create),
        backgroundColor: colorPrimario,
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  Widget _buildModernInfoRow(BuildContext context, Lugar lugar) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfoItem(Icons.access_time_filled_rounded, lugar.horario, "Horario", Theme.of(context).colorScheme.primary),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildInfoItem(Icons.star_rounded, lugar.rating > 0 ? lugar.rating.toStringAsFixed(1) : "Nuevo", "Rating", Colors.amber),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label, Color color) {
    return Column(children: [Icon(icon, color: color), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))]);
  }

  Widget _buildMapSection(BuildContext context, Lugar lugar) {
    return Container(
      height: 180,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () => context.push('/mapa-lugar', extra: lugar),
          icon: const Icon(Icons.map),
          label: const Text('Ver ubicación'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
        ),
      ),
    );
  }

  Widget _buildReviewsSummary(BuildContext context, Lugar lugar, List<Comentario> comentarios) {
    // Resumen simplificado para evitar errores
    return Row(children: [
      Text(lugar.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
      const SizedBox(width: 10),
      const Text("Promedio de reseñas", style: TextStyle(color: Colors.grey)),
    ]);
  }

  Widget _buildComentarioCard(Comentario c) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: c.usuarioFotoUrl.isNotEmpty ? NetworkImage(c.usuarioFotoUrl) : null, child: c.usuarioFotoUrl.isEmpty ? Text(c.usuarioNombre[0]) : null),
      title: Text(c.usuarioNombre),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.texto), Text(c.fecha, style: const TextStyle(fontSize: 10))]),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, color: Colors.amber, size: 16), Text(c.rating.toString())]),
    );
  }

  void _showLoginRequiredModal(BuildContext context, String action) {
    // Implementación simple
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