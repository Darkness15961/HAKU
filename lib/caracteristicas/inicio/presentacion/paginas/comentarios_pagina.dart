// --- PIEDRA 7.2: EL "MENÚ" DE LISTA DE COMENTARIOS (ACOMPLADO Y CORREGIDO) ---
//
// 1. (BUG PROVIDER CORREGIDO): Se cambió 'Provider.value' por
//    'ChangeNotifierProvider.value' en '_mostrarDialogoComentario'
//    para pasar correctamente el VM (un ChangeNotifier) al diálogo.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM: IMPORTACIONES ---
import '../vista_modelos/lugares_vm.dart';
import '../../dominio/entidades/comentario.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../dominio/entidades/lugar.dart';

// 1. El "Edificio" (La Pantalla)
class ComentariosPagina extends StatefulWidget {
  // --- ¡ACOMPLADO! ---
  // Ahora recibe el 'Lugar' desde el 'extra' de GoRouter
  final Lugar lugar;

  const ComentariosPagina({
    super.key,
    required this.lugar, // <-- AHORA REQUIERE EL LUGAR
  });
  // --- FIN DE ACOMPLE ---

  @override
  State<ComentariosPagina> createState() => _ComentariosPaginaState();
}

class _ComentariosPaginaState extends State<ComentariosPagina> {

  // --- ¡ACOMPLADO! Lógica de Seguridad ---
  bool _checkAndRedirect(BuildContext context, String action) {
    final authVM = context.read<AutenticacionVM>();
    if (!authVM.estaLogueado) {
      _showLoginRequiredModal(context, action);
      return false;
    }
    return true;
  }

  // --- ¡ACOMPLADO! Lógica de Acciones ---
  void _mostrarDialogoComentario(BuildContext context) {
    if (!_checkAndRedirect(context, 'escribir una reseña')) {
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {

        // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
        // Usamos ChangeNotifierProvider.value porque LugaresVM es un ChangeNotifier
        return ChangeNotifierProvider.value(
          value: context.read<LugaresVM>(), // Pasa el VM existente
          child: _DialogoComentarioPagina(
            lugarId: widget.lugar.id,
            lugarNombre: widget.lugar.nombre,
          ),
        );
        // --- FIN DE CORRECCIÓN ---
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LugaresVM>();

    // --- ¡BUG CORREGIDO! ---
    // Ya no "adivinamos" el lugar, usamos el 'widget.lugar'
    // que recibimos en el constructor.
    // --- FIN DE CORRECCIÓN ---

    return Scaffold(
      appBar: AppBar(
        // Usamos el 'lugar' que recibimos
        title: Text('Reseñas de ${widget.lugar.nombre} (${vm.comentarios.length})'),
      ),

      // --- ¡BOTÓN ACOMPLADO! ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _mostrarDialogoComentario(context);
        },
        label: const Text('Añadir Reseña'),
        icon: const Icon(Icons.edit),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      // --- FIN DE BOTÓN ---

      body: ListView.builder(
        itemCount: vm.comentarios.length,
        itemBuilder: (context, index) {
          final comentario = vm.comentarios[index];
          return _buildComentarioCard(comentario);
        },
      ),
    );
  }

  // --- Widget de Tarjeta de Comentario (¡ACOMPLADO!) ---
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
                    // --- ¡ACOMPLADO! (Maneja foto nula) ---
                    backgroundImage: (comentario.usuarioFotoUrl != null && comentario.usuarioFotoUrl!.isNotEmpty)
                        ? NetworkImage(comentario.usuarioFotoUrl!)
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: (comentario.usuarioFotoUrl == null || comentario.usuarioFotoUrl!.isEmpty)
                        ? Text(comentario.usuarioNombre.substring(0,1).toUpperCase())
                        : null,
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

  // --- ¡ACOMPLADO! Modal de Invitación (se mantiene) ---
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
} // <-- Fin de _ComentariosPaginaState

// --- ¡BUG CORREGIDO! ---
// Se renombró la clase a '_DialogoComentarioPagina'
class _DialogoComentarioPagina extends StatefulWidget {
  final String lugarId;
  final String lugarNombre;
  const _DialogoComentarioPagina({required this.lugarId, required this.lugarNombre});
  @override
  State<_DialogoComentarioPagina> createState() => _DialogoComentarioPaginaState();
}

class _DialogoComentarioPaginaState extends State<_DialogoComentarioPagina> {
  // Estado local para el formulario del diálogo
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

  // Función de envío (ACOMPLADA)
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

    // --- MVVM: ORDEN AL "MESERO" ---
    await context.read<LugaresVM>().enviarComentario(
      widget.lugarId,
      _resenaCtrl.text,
      _ratingSeleccionado,
    );
    // (El 'lugares_vm.dart' ya está "acoplado")

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
            // --- HEADER ---
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

  // (Widget de estrellas)
  Widget _buildStarRatingSelector() {
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

  // (Widget de subir fotos)
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