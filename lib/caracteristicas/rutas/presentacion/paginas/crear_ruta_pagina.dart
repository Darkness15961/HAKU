import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math'; 

import '../vista_modelos/rutas_vm.dart';
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../dominio/entidades/ruta.dart';

import '../../../notificaciones/dominio/repositorios/notificacion_repositorio.dart';
import '../../../notificaciones/datos/repositorios/notificacion_repositorio_mock.dart';
import '../../../notificaciones/presentacion/vista_modelos/notificaciones_vm.dart';


import 'package:latlong2/latlong.dart';

import '../widgets/subida_imagen_ruta.dart';
import '../widgets/formulario_info_basica.dart';
import '../widgets/selector_lugares_ruta.dart';
import '../widgets/route_location.dart';
import '../widgets/formulario_logistica.dart'; // <--- NUEVO IMPORT

class CrearRutaPagina extends StatefulWidget {
  final Ruta? ruta;

  const CrearRutaPagina({
    super.key,
    this.ruta,
  });

  @override
  State<CrearRutaPagina> createState() => _CrearRutaPaginaState();
}

class _CrearRutaPaginaState extends State<CrearRutaPagina> {
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();
  final TextEditingController _precioCtrl = TextEditingController(text: '0');
  final TextEditingController _diasCtrl = TextEditingController(text: '1');
  final TextEditingController _cuposCtrl = TextEditingController(text: '10');
  final TextEditingController _urlImagenCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String _selectedDifficulty = 'Familiar';
  String _visibility = 'Publicada';
  bool _esPrivada = false;
  String? _codigoAccesoGenerado;
  bool _estaGuardando = false;

  // --- NUEVOS CONTROLADORES ---
  final TextEditingController _whatsappCtrl = TextEditingController();
  final TextEditingController _puntoEncuentroCtrl = TextEditingController();
  final TextEditingController _equipamientoCtrl = TextEditingController();
  
  DateTime? _fechaEvento;
  DateTime? _fechaCierre;
  // ---------------------------

  List<RouteLocation> _locations = [];

  Future<void> _submitCrearRuta() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes añadir al menos un lugar al itinerario.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validar Fechas (Básico)
    if (_fechaEvento == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La fecha del evento es obligatoria.'), backgroundColor: Colors.orange));
      return;
    }
    if (_fechaCierre != null && _fechaEvento != null && _fechaCierre!.isAfter(_fechaEvento!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El cierre de inscripción no puede ser después del evento.'), backgroundColor: Colors.orange));
      return;
    }

    final vmAuth = context.read<AutenticacionVM>();
    if (vmAuth.usuarioActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo identificar al guía.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _estaGuardando = false);
      return;
    }

    if (!vmAuth.tieneNombreCompleto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '⚠️ Debes validar tu nombre completo en Ajustes de Cuenta',
          ),
          backgroundColor: Colors.orange[900],
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Ir a Ajustes',
            textColor: Colors.white,
            onPressed: () => context.push('/perfil/ajustes-cuenta'),
          ),
        ),
      );
      setState(() => _estaGuardando = false);
      return;
    }

    final String diasText = _diasCtrl.text.isEmpty ? '1' : _diasCtrl.text;
    final String cuposText = _cuposCtrl.text.isEmpty ? '10' : _cuposCtrl.text;

    String? codigoFinal;
    if (_esPrivada) {
      if (widget.ruta != null &&
          widget.ruta!.esPrivada &&
          widget.ruta!.codigoAcceso != null) {
        codigoFinal = widget.ruta!.codigoAcceso;
        _codigoAccesoGenerado = codigoFinal;
      } else {
        _codigoAccesoGenerado ??= _generarCodigoAcceso();
        codigoFinal = _codigoAccesoGenerado;
      }
    } else {
      _codigoAccesoGenerado = null;
    }

    // Convertir equipamiento string a list
    List<String> listaEquipamiento = _equipamientoCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final Map<String, dynamic> datosRuta = {
      'nombre': _nombreCtrl.text,
      'descripcion': _descripcionCtrl.text,
      'precio': double.tryParse(_precioCtrl.text) ?? 0.0,
      'cupos': int.tryParse(cuposText) ?? 10,
      'categoria': _selectedDifficulty,
      'categoriaId': context.read<RutasVM>().categoriasDisponibles
          .firstWhereOrNull((c) => c['nombre'].toString().toLowerCase() == _selectedDifficulty.toLowerCase())?['id'], // Validacion Robustez
      'visible': _visibility == 'Publicada',
      'es_privada': _esPrivada,
      'codigo_acceso': codigoFinal,
      'dias': int.tryParse(diasText) ?? 1,
      'lugaresIds': _locations.map((loc) => loc.lugar.id).toList(),
      'puntos_coordenadas': _locations.map((loc) => LatLng(loc.lugar.latitud, loc.lugar.longitud)).toList(),
      'lugaresNombres': _locations.map((loc) => loc.lugar.nombre).toList(),
      'guiaId': vmAuth.usuarioActual!.id,
      'guiaNombre': vmAuth.usuarioActual!.seudonimo,
      'guiaFotoUrl': vmAuth.usuarioActual!.urlFotoPerfil ?? '',
      'url_imagen_principal': _urlImagenCtrl.text.isNotEmpty
          ? _urlImagenCtrl.text
          : (_locations.isNotEmpty ? _locations.first.lugar.urlImagen : ''),
      // --- CAMPOS NUEVOS ---
      'enlace_grupo_whatsapp': _whatsappCtrl.text,
      'puntoEncuentro': _puntoEncuentroCtrl.text,
      'equipamientoRuta': listaEquipamiento,
      'fechaEvento': _fechaEvento?.toIso8601String(),
      'fechaCierreInscripcion': _fechaCierre?.toIso8601String(),
    };

    try {
      if (!mounted) return;
      String mensajeExito = '';

      if (widget.ruta == null) {
        await context.read<RutasVM>().crearRuta(datosRuta);
        mensajeExito = '¡Ruta creada con éxito!';
      } else {
        await context.read<RutasVM>().actualizarRuta(
          widget.ruta!.id,
          datosRuta,
        );
        mensajeExito = '¡Ruta actualizada con éxito!';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeExito), backgroundColor: Colors.green),
        );

        if (_esPrivada &&
            _codigoAccesoGenerado != null &&
            (widget.ruta == null || !widget.ruta!.esPrivada)) {
          await _mostrarDialogoCodigoAcceso(_codigoAccesoGenerado!);
        }

        if (!mounted) return;
        context.pop(); 
        if (widget.ruta != null) {
          context.pop(); 
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _estaGuardando = false);
      }
    }
  }

  void _previsualizarRuta(BuildContext context) {
    final vmAuth = context.read<AutenticacionVM>();
    if (vmAuth.usuarioActual == null) return; 

    final int cuposTotales = int.tryParse(_cuposCtrl.text) ?? 10;
    
    // Convertir equipamiento string a list para preview
    List<String> listaEquipamiento = _equipamientoCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final Ruta rutaTemporal = Ruta(
      id: 'preview_id',
      nombre: _nombreCtrl.text.isEmpty ? 'Nombre de tu Ruta' : _nombreCtrl.text,
      descripcion: _descripcionCtrl.text.isEmpty
          ? 'Descripción de tu ruta...'
          : _descripcionCtrl.text,
      precio: double.tryParse(_precioCtrl.text) ?? 0.0,
      cuposTotales: cuposTotales,
      dias: int.tryParse(_diasCtrl.text) ?? 1,
      categoria: _selectedDifficulty,
      visible: _visibility == 'Pública',
      urlImagenPrincipal: _locations.isNotEmpty
          ? _locations.first.lugar.urlImagen
          : 'https://via.placeholder.com/400x300.png?text=Ruta+sin+Imagen',

      lugaresIncluidos: _locations.map((loc) => loc.lugar.nombre).toList(),
      lugaresIncluidosIds: _locations.map((loc) => loc.lugar.id).toList(),

      guiaId: vmAuth.usuarioActual!.id,
      guiaNombre: vmAuth.usuarioActual!.seudonimo,
      guiaFotoUrl: vmAuth.usuarioActual!.urlFotoPerfil ?? '',
      guiaRating: widget.ruta?.guiaRating ?? 5.0, 
      rating: widget.ruta?.rating ?? 0.0,
      reviewsCount: widget.ruta?.reviewsCount ?? 0,
      inscritosCount: widget.ruta?.inscritosCount ?? 0,
      estaInscrito: false,
      esFavorita: false,
      cuposDisponibles: cuposTotales - (widget.ruta?.inscritosCount ?? 0),
      // Nuevos campos para preview
      puntoEncuentro: _puntoEncuentroCtrl.text,
      enlaceWhatsapp: _whatsappCtrl.text,
      equipamiento: listaEquipamiento,
      fechaEvento: _fechaEvento,
      fechaCierre: _fechaCierre,
    );

    context.push('/rutas/detalle-ruta', extra: rutaTemporal);
  }


  @override
  void initState() {
    super.initState();
    // Listeners opcionales si necesitamos redibujar UI compleja al cambiar texto
    _nombreCtrl.addListener(() => setState(() {}));
    _descripcionCtrl.addListener(() => setState(() {}));
    _precioCtrl.addListener(() => setState(() {}));
    _diasCtrl.addListener(() => setState(() {}));
    _cuposCtrl.addListener(() => setState(() {}));
    _urlImagenCtrl.addListener(() => setState(() {}));
    
    if (widget.ruta != null) {
      _nombreCtrl.text = widget.ruta!.nombre;
      _descripcionCtrl.text = widget.ruta!.descripcion;
      _precioCtrl.text = widget.ruta!.precio.toString();
      _diasCtrl.text = widget.ruta!.dias.toString();
      _cuposCtrl.text = widget.ruta!.cuposTotales.toString();

      // Nuevos campos
      _whatsappCtrl.text = widget.ruta!.enlaceWhatsapp ?? '';
      _puntoEncuentroCtrl.text = widget.ruta!.puntoEncuentro ?? '';
      _equipamientoCtrl.text = widget.ruta!.equipamiento.join(', ');
      _fechaEvento = widget.ruta!.fechaEvento;
      _fechaCierre = widget.ruta!.fechaCierre;

      const opcionesValidas = ['Familiar', 'Cultural', 'Aventura', '+18', 'Naturaleza', 'Extrema'];
      final categoriaGuardada = widget.ruta!.categoria;

      _selectedDifficulty = opcionesValidas.firstWhere(
        (op) => op.toLowerCase() == categoriaGuardada.toLowerCase(),
        orElse: () => 'Familiar',
      );

      _visibility = widget.ruta!.visible ? 'Publicada' : 'Borrador';
      _esPrivada = widget.ruta!.esPrivada;
      _urlImagenCtrl.text = widget.ruta!.urlImagenPrincipal;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final vmLugares = context.read<LugaresVM>();
        final vmRutas = context.read<RutasVM>(); // <--- Reference
        
        // 1. Cargar Categorías
        vmRutas.cargarCategorias();

        // 2. Cargar Lugares
        if (vmLugares.lugaresTotales.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cargando datos...'), duration: Duration(seconds: 1)),
          );
          await vmLugares.cargarTodosLosLugares();
        }

        if (!mounted) return;

        _locations = widget.ruta!.lugaresIncluidosIds
            .map((id) {
              final lugar = vmLugares.lugaresTotales.firstWhereOrNull((l) => l.id == id);
              if (lugar != null) {
                return RouteLocation(lugar: lugar);
              }
              return null;
            })
            .whereType<RouteLocation>()
            .toList();
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    _diasCtrl.dispose();
    _cuposCtrl.dispose();
    _urlImagenCtrl.dispose();
    // Nuevos
    _whatsappCtrl.dispose();
    _puntoEncuentroCtrl.dispose();
    _equipamientoCtrl.dispose();
    super.dispose();
  }

  bool _canSave(RutasVM vmRutas) {
    if (vmRutas.estaCargando) return false;
    return _nombreCtrl.text.isNotEmpty &&
        _descripcionCtrl.text.isNotEmpty &&
        _locations.isNotEmpty &&
        // Validación básica de nuevos campos obligatorios si se desea
        _fechaEvento != null &&
        _puntoEncuentroCtrl.text.isNotEmpty &&
        (double.tryParse(_precioCtrl.text) ?? 0.0) >= 0;
  }

  @override
  Widget build(BuildContext context) {
    final vmRutas = context.watch<RutasVM>();
    final canSave = _canSave(vmRutas);
    final bool modoEdicion = widget.ruta != null;
    final int inscritosCount = widget.ruta?.inscritosCount ?? 0;
    final bool hayInscritos = inscritosCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          modoEdicion ? 'Editar Ruta' : 'Crear Ruta',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          _estaGuardando
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: FilledButton(
                    onPressed: canSave ? _submitCrearRuta : null,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (states) => states.contains(MaterialState.disabled) ? Colors.white.withValues(alpha: 0.3) : Colors.white
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (states) => states.contains(MaterialState.disabled) ? Colors.white.withValues(alpha: 0.7) : Theme.of(context).colorScheme.primary
                      ),
                      textStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    child: const Text('Guardar'),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. INFO BÁSICA Y FORMULARIO
                  FormularioInfoBasica(
                    nombreCtrl: _nombreCtrl,
                    descripcionCtrl: _descripcionCtrl,
                    precioCtrl: _precioCtrl,
                    cuposCtrl: _cuposCtrl,
                    diasCtrl: _diasCtrl,
                    selectedDifficulty: _selectedDifficulty,
                    onDifficultyChanged: (val) => setState(() => _selectedDifficulty = val),
                    minCupos: widget.ruta?.inscritosCount ?? 0,
                  ),
                  const SizedBox(height: 24),
                  
                  // --- NUEVO: FORMULARIO LOGÍSTICA ---
                  FormularioLogistica(
                    whatsappCtrl: _whatsappCtrl,
                    puntoEncuentroCtrl: _puntoEncuentroCtrl,
                    equipamientoCtrl: _equipamientoCtrl,
                    fechaEvento: _fechaEvento,
                    fechaCierre: _fechaCierre,
                    onFechaEventoChanged: (d) => setState(() => _fechaEvento = d),
                    onFechaCierreChanged: (d) => setState(() => _fechaCierre = d),
                  ),
                  const SizedBox(height: 24),
                  
                  // 2. SUBIDA IMAGEN
                  SubidaImagenRuta(urlImagenCtrl: _urlImagenCtrl),

                  const Divider(height: 32),
                  
                  // 3. SELECTOR DE LUGARES
                  SelectorLugaresRuta(
                    locations: _locations,
                    onLocationsChanged: (newList) => setState(() => _locations = newList),
                  ),

                  const Divider(height: 32),

                  // 4. VISIBILIDAD Y EXTRA (Mantenido)
                  _buildVisibilityTools(context, hayInscritos),

                  if (modoEdicion)
                    _buildDangerZone(context, widget.ruta!, hayInscritos),
                ],
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildFixedFooter(context),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE VISIBILIDAD Y FOOTER (Preservados con lógica intacta) ---

  Widget _buildVisibilityTools(BuildContext context, bool hayInscritos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Estado de Publicación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
        AbsorbPointer(
          absorbing: hayInscritos,
          child: Container(
            decoration: BoxDecoration(
              color: hayInscritos ? Colors.grey.shade300 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Borrador'),
                  subtitle: const Text('Solo tú puedes verla (en desarrollo)'),
                  value: 'Borrador',
                  groupValue: _visibility,
                  onChanged: (val) => setState(() => _visibility = val!),
                ),
                RadioListTile<String>(
                  title: const Text('Publicada'),
                  subtitle: const Text('Visible en el marketplace'),
                  value: 'Publicada',
                  groupValue: _visibility,
                  onChanged: (val) => setState(() => _visibility = val!),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Tipo de Ruta (Acceso)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              RadioListTile<bool>(
                title: const Text('Acceso Libre'),
                subtitle: const Text('Cualquier turista puede inscribirse'),
                value: false,
                groupValue: _esPrivada,
                onChanged: (val) => setState(() => _esPrivada = val!),
              ),
              RadioListTile<bool>(
                title: const Text('Privada con Código'),
                subtitle: const Text('Solo con código de invitación'),
                value: true,
                groupValue: _esPrivada,
                onChanged: (val) => setState(() => _esPrivada = val!),
              ),
            ],
          ),
        ),

        if (hayInscritos)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'No puedes cambiar el estado mientras haya turistas inscritos.',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildFixedFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _footerItem('Días', '${_diasCtrl.text.isEmpty ? '0' : _diasCtrl.text} día(s)'),
          _footerItem('Cupos', '${_cuposCtrl.text.isEmpty ? '0' : _cuposCtrl.text} pers.'),
          ElevatedButton(
            onPressed: () => _previsualizarRuta(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Icon(Icons.visibility, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _footerItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context, Ruta ruta, bool hayInscritos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        const Text('Zona de Peligro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 16),
        if (hayInscritos)
          _buildDangerButton(
            context: context,
            icon: Icons.warning_amber_rounded,
            label: 'Cancelar esta Ruta',
            details: 'Esto notificará y expulsará a ${ruta.inscritosCount} turista(s) inscrito(s).',
            onPressed: () => _mostrarDialogoCancelarRuta(context, ruta),
          )
        else
          _buildDangerButton(
            context: context,
            icon: Icons.delete_forever,
            label: 'Eliminar Ruta Permanentemente',
            details: 'Esta acción no se puede deshacer.',
            onPressed: () => _mostrarDialogoEliminarRuta(context),
          ),
      ],
    );
  }

  Widget _buildDangerButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String details,
    required VoidCallback? onPressed,
  }) {
    final Color buttonColor = (onPressed != null) ? Colors.red.shade700 : Colors.grey;
    return OutlinedButton.icon(
      icon: Icon(icon, color: buttonColor),
      label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: buttonColor)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: BorderSide(color: buttonColor.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      onPressed: onPressed,
    );
  }

  void _mostrarDialogoCancelarRuta(BuildContext context, Ruta ruta) {
    final vmRutas = context.read<RutasVM>();
    final navigator = GoRouter.of(context);
    final repoNotificaciones = context.read<NotificacionRepositorio>() as NotificacionRepositorioMock;
    final vmNotificaciones = context.read<NotificacionesVM>();

    final TextEditingController mensajeCtrl = TextEditingController();
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('¿Cancelar esta Ruta?'),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estás a punto de cancelar esta ruta y expulsar a ${ruta.inscritosCount} turista(s).'),
                    const SizedBox(height: 16),
                    Text('Por favor, escribe un motivo. Se enviará a todos los inscritos.', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: mensajeCtrl,
                      autofocus: true, maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Ej. "Cancelamos por lluvia..."', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido.' : null,
                      onChanged: (_) => setDialogState((){}),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(child: const Text('Volver'), onPressed: () => Navigator.of(dialogContext).pop()),
                FilledButton.icon(
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Sí, Cancelar'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: (mensajeCtrl.text.trim().isEmpty) ? null : () async {
                    if (dialogFormKey.currentState!.validate()) {
                      await vmRutas.cambiarEstadoRuta(widget.ruta!.id, 'cancelada');
                      await repoNotificaciones.simularEnvioDeNotificacion(titulo: 'Ruta Cancelada: ${widget.ruta!.nombre}', cuerpo: mensajeCtrl.text);
                      
                      if (!context.mounted) return;
                      vmNotificaciones.cargarNotificaciones();
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ruta cancelada y notificada.'), backgroundColor: Colors.green));
                      navigator.pop(); navigator.pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoEliminarRuta(BuildContext context) {
    final vmRutas = context.read<RutasVM>();
    final navigator = GoRouter.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar Permanentemente?'),
        content: const Text('Esta acción no se puede deshacer.\n\n¿Estás seguro?'),
        actions: [
          TextButton(child: const Text('Volver'), onPressed: () => Navigator.of(dialogContext).pop()),
          FilledButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text('Sí, Eliminar'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await vmRutas.eliminarRuta(widget.ruta!.id);
              if (!context.mounted) return;
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ruta eliminada.'), backgroundColor: Colors.green));
              navigator.pop(); navigator.pop();
            },
          ),
        ],
      ),
    );
  }

  String _generarCodigoAcceso() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> _mostrarDialogoCodigoAcceso(String codigo) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Ruta Privada Creada!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_person, size: 48, color: Colors.purple),
            const SizedBox(height: 16),
            const Text('Comparte este código:', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SelectableText(codigo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.purple)),
          ],
        ),
        actions: [FilledButton(child: const Text('Entendido'), onPressed: () => Navigator.of(ctx).pop())],
      ),
    );
  }
}

// Extensión para firstWhereOrNull sin depender de package:collection
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
