import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para inputFormatters
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../inicio/dominio/entidades/lugar.dart';
import '../vista_modelos/rutas_vm.dart';
import '../widgets/subida_imagen_ruta.dart';
import '../widgets/selector_lugares_ruta.dart';
import '../widgets/route_location.dart'; // Restaurado
import '../widgets/formulario_logistica.dart'; // Importar widget logístico

import '../../dominio/entidades/ruta.dart'; // Import para usar la entidad

import '../../../notificaciones/dominio/repositorios/notificacion_repositorio.dart';
import '../../../notificaciones/datos/repositorios/notificacion_repositorio_mock.dart';
import '../../../notificaciones/presentacion/vista_modelos/notificaciones_vm.dart';

class CrearRutaSinGuiaPagina extends StatefulWidget {
  final Ruta? ruta; // Para editar

  const CrearRutaSinGuiaPagina({super.key, this.ruta});

  @override
  State<CrearRutaSinGuiaPagina> createState() => _CrearRutaSinGuiaPaginaState();
}

class _CrearRutaSinGuiaPaginaState extends State<CrearRutaSinGuiaPagina> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController(text: '0');
  final _puntoEncuentroController = TextEditingController();
  final _cuposController = TextEditingController(text: '1');
  final _diasController = TextEditingController(text: '1'); // Nuevo
  final _urlImagenCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController(); // Nuevo campo
  final _equipamientoCtrl = TextEditingController(); // Nuevo campo

  // Estado
  List<RouteLocation> _locations = [];
  String _preferenciaPrivacidad = 'publica';
  String _visibility = 'Publicada'; // Nuevo
  DateTime? _fechaEvento;
  DateTime? _fechaCierre; // Nuevo campo
  String _categoria = 'Familiar';
  bool _creando = false;

  final List<String> _categorias = [
    'Familiar',
    'Cultural',
    'Aventura',
    'Naturaleza',
    'Extrema',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       context.read<RutasVM>().cargarCategorias();
       if (widget.ruta != null) {
         _cargarDatosEdicion();
       }
    });
    // Listener para actualizar el footer en tiempo real
    _precioController.addListener(() {
      setState(() {});
    });
  }

  void _cargarDatosEdicion() {
    final r = widget.ruta!;
    
    _nombreController.text = r.nombre;
    _descripcionController.text = r.descripcion;
    _precioController.text = r.precio.toInt().toString(); // Asumiendo entero para simplificar visualmente
    _cuposController.text = r.cuposTotales.toString();
    _diasController.text = r.dias.toString();
    _urlImagenCtrl.text = r.urlImagenPrincipal;
    _categoria = r.categoria;
    
    // Logística
    _fechaEvento = r.fechaEvento;
    _fechaCierre = r.fechaCierre;
    _puntoEncuentroController.text = r.puntoEncuentro ?? '';
    _whatsappCtrl.text = r.enlaceWhatsapp ?? '';
    _equipamientoCtrl.text = r.equipamiento.join(', ');
    
    // Configuración
    _visibility = r.visible ? 'Publicada' : 'Borrador';
    _preferenciaPrivacidad = r.esPrivada ? 'privada' : 'publica';

    // Mapa
    setState(() {
      if (r.lugaresIncluidosCoords.isNotEmpty && r.lugaresIncluidos.isNotEmpty) { // Fixed property name
        _locations = List.generate(
          min(r.lugaresIncluidosCoords.length, r.lugaresIncluidos.length), 
          (i) => RouteLocation(
            lugar: Lugar(
              id: r.lugaresIncluidosIds.length > i ? r.lugaresIncluidosIds[i] : 'legacy_$i',
              nombre: r.lugaresIncluidos[i],
              descripcion: '',
              urlImagen: '',
              latitud: r.lugaresIncluidosCoords[i].latitude,
              longitud: r.lugaresIncluidosCoords[i].longitude,
              rating: 0.0,
              reviewsCount: 0,
              provinciaId: '0', // Fixed type to String
              usuarioId: 'unknown_legacy',
            )
          )
        );
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _puntoEncuentroController.dispose();
    _cuposController.dispose();
    _diasController.dispose();
    _urlImagenCtrl.dispose();
    _whatsappCtrl.dispose();
    _equipamientoCtrl.dispose();
    super.dispose();
  }

  // --- LÓGICA DE NEGOCIO ---

  String _generarCodigoAcceso() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  void _mostrarCodigoAcceso(String codigo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.green[700]),
            const SizedBox(width: 10),
            const Text('Ruta Privada Creada'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tu ruta ha sido creada exitosamente. Comparte este código con tus invitados:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[300]!, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    codigo,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: codigo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Código copiado al portapapeles'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar código'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Guarda este código, lo necesitarás para que otros se unan a tu ruta',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/rutas');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _crearRuta() async {
    if (!_formKey.currentState!.validate()) return;

    if (_locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes añadir al menos un lugar al itinerario.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_fechaEvento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar una fecha para el evento.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _creando = true);

    try {
      final vmAuth = context.read<AutenticacionVM>();
      final vmRutas = context.read<RutasVM>();

      // Validar autenticación
      if (vmAuth.usuarioActual == null) {
        throw Exception('Debes iniciar sesión para crear una ruta');
      }

      final userId = vmAuth.usuarioActual!.id;

      // Generar código para ruta privada
      String? codigoAcceso;
      if (_preferenciaPrivacidad == 'privada') {
        // Mantiene el código existente si ya tiene uno, sino genera uno nuevo
        if (widget.ruta != null && widget.ruta!.codigoAcceso != null) {
          codigoAcceso = widget.ruta!.codigoAcceso;
        } else {
          codigoAcceso = _generarCodigoAcceso();
        }
      }

      // Usar imagen subida o del primer lugar
      String urlImagen = _urlImagenCtrl.text;
      if (urlImagen.isEmpty && _locations.isNotEmpty) {
        urlImagen = _locations.first.lugar.urlImagen;
      }

      final int cupos = int.tryParse(_cuposController.text) ?? 10;
      final double precio = double.tryParse(_precioController.text) ?? 0.0;

      final datosRuta = {
        'nombre': _nombreController.text,
        'descripcion': _descripcionController.text,
        'categoria': _categoria,
        'categoriaId': vmRutas.categoriasDisponibles
            .firstWhereOrNull((c) => c['nombre'] == _categoria)?['id'],
        'precio': precio,
        'cupos': cupos,
        'dias': int.tryParse(_diasController.text) ?? 1,
        'visible': _visibility == 'Publicada',
        'es_privada': _preferenciaPrivacidad == 'privada',
        'guia_id': userId,
        'url_imagen_principal': urlImagen,
        'lugaresIds': _locations
            .map((l) => l.lugar.id)
            .where((id) => int.tryParse(id) != null) // Solo IDs numéricos válidos
            .toList(),
        'puntos_coordenadas': _locations
            .map((l) => LatLng(l.lugar.latitud, l.lugar.longitud))
            .toList(),
        'lugaresNombres': _locations.map((l) => l.lugar.nombre).toList(),
        'fechaEvento': _fechaEvento?.toIso8601String(),
        'fechaCierreInscripcion': _fechaCierre?.toIso8601String(),
        'puntoEncuentro': _puntoEncuentroController.text.isNotEmpty
            ? _puntoEncuentroController.text
            : null,
        'enlace_grupo_whatsapp': _whatsappCtrl.text,
        'equipamientoRuta': _equipamientoCtrl.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        'estado': 'convocatoria',
        if (codigoAcceso != null) 'codigo_acceso': codigoAcceso,
      };

      if (widget.ruta == null) {
        // MODO CREAR
        await vmRutas.crearRuta(datosRuta);
      } else {
        // MODO ACTUALIZAR
        await vmRutas.actualizarRuta(widget.ruta!.id, datosRuta);
      }

      setState(() => _creando = false);

      if (mounted) {
        if (codigoAcceso != null) {
          _mostrarCodigoAcceso(codigoAcceso);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.ruta == null ? '¡Ruta creada con éxito!' : '¡Ruta actualizada!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(); // Regresar
        }
      }
    } catch (e) {
      setState(() => _creando = false);
      if (mounted) {
        final errorMsg = e.toString().replaceFirst("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- UI HELPERS ---

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 4),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildStyledInput({
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? helperText, // Standard
    String? helpText,   // Alias for backward compatibility if I mixed them up
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    IconData? prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          helperText: helperText ?? helpText, // Use either
          helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          alignLabelWithHint: maxLines > 1,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.grey.shade600, size: 22)
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo gris muy suave
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.ruta == null ? 'Diseña tu Aventura' : 'Editar Aventura',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_creando)
            Container(
              margin: const EdgeInsets.only(right: 16),
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(strokeWidth: 2.5),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20, left: 4),
                    child: Text(
                      'Completa los detalles para publicar tu ruta personalizada.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),

                  // 1. TARJETA DE EXPERIENCIA (Info Básica)
                  _buildSectionTitle('La Experiencia', Icons.explore),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildStyledInput(
                          controller: _nombreController,
                          label: 'Nombre de la Ruta *',
                          hintText: 'Ej. Caminata al atardecer en Pisac',
                          prefixIcon: Icons.edit_location_alt,
                          validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                        ),
                        _buildStyledInput(
                          controller: _descripcionController,
                          label: 'Descripción *',
                          hintText: 'Describe qué hace especial a este recorrido...',
                          maxLines: 4,
                          validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                        ),
                        Consumer<RutasVM>(
                          builder: (context, vm, child) {
                            var items = <String>[];
                            if (vm.categoriasDisponibles.isNotEmpty) {
                              items = vm.categoriasDisponibles.map((c) => c['nombre'].toString()).toList();
                            } else {
                              items = _categorias; // Fallback
                            }
                            
                            // Asegurar integridad
                            if (!items.contains(_categoria)) {
                               if (items.isNotEmpty) _categoria = items.first;
                            }

                            return DropdownButtonFormField<String>(
                              value: _categoria,
                              decoration: InputDecoration(
                                labelText: 'Categoría',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                prefixIcon: Icon(Icons.category, color: Colors.grey.shade600, size: 22),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              items: items.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) => setState(() => _categoria = val!),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // 2. LOGÍSTICA (FormularioLogistica refactorizado visualmente via wrapper)
                  _buildSectionTitle('Logística', Icons.access_time_filled),
                  _buildCard(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                      child: FormularioLogistica(
                        fechaEvento: _fechaEvento,
                        fechaCierre: _fechaCierre,
                        puntoEncuentroCtrl: _puntoEncuentroController,
                        whatsappCtrl: _whatsappCtrl,
                        equipamientoCtrl: _equipamientoCtrl,
                        onFechaEventoChanged: (val) => setState(() => _fechaEvento = val),
                        onFechaCierreChanged: (val) => setState(() => _fechaCierre = val),
                      ),
                    ),
                  ),

                  // 3. DETALLES (Cupos, Precio, Imagen)
                  _buildSectionTitle('Detalles y Multimedia', Icons.image),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildStyledInput(
                          controller: _precioController,
                          label: 'Precio por Persona (S/)',
                          hintText: '0.00',
                          helperText: 'Costo en Soles por cada turista.',
                          prefixIcon: Icons.monetization_on_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                        ),
                        _buildStyledInput(
                          controller: _cuposController,
                          label: 'Cupos Totales',
                          helpText: 'Cantidad máxima de personas admitidas.', 
                          prefixIcon: Icons.group_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 1) return 'Mín 1';
                            return null;
                          },
                        ),
                        _buildStyledInput(
                          controller: _diasController,
                          label: 'Duración del Viaje',
                          helpText: 'Número de días que dura la experiencia.',
                          prefixIcon: Icons.timer_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 1) return 'Mín 1';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        SubidaImagenRuta(urlImagenCtrl: _urlImagenCtrl),
                      ],
                    ),
                  ),

                  // 4. MAPA
                  _buildSectionTitle('El Mapa', Icons.map),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         const Padding(
                          padding: EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            'Selecciona los puntos clave de tu ruta:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        SelectorLugaresRuta(
                          locations: _locations,
                          onLocationsChanged: (newList) => setState(() => _locations = newList),
                        ),
                      ],
                    ),
                  ),

                  // NEW: PUBLICATION STATUS
                  _buildSectionTitle('Estado de Publicación', Icons.visibility),
                  _buildCard(
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          activeColor: Theme.of(context).primaryColor,
                          title: const Text('Borrador', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Solo visible para ti (En desarrollo)'),
                          value: 'Borrador',
                          groupValue: _visibility,
                          onChanged: (val) => setState(() => _visibility = val!),
                        ),
                        const Divider(),
                        RadioListTile<String>(
                          activeColor: Theme.of(context).primaryColor,
                          title: const Text('Publicada', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Visible en el marketplace'),
                          value: 'Publicada',
                          groupValue: _visibility,
                          onChanged: (val) => setState(() => _visibility = val!),
                        ),
                      ],
                    ),
                  ),

                  // 5. PRIVACIDAD
                  _buildSectionTitle('Privacidad', Icons.lock_outline),
                  _buildCard(
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          activeColor: Theme.of(context).primaryColor,
                          title: const Text('Pública', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Visible para todos en la comunidad'),
                          secondary: const Icon(Icons.public),
                          value: 'publica',
                          groupValue: _preferenciaPrivacidad,
                          onChanged: (val) => setState(() => _preferenciaPrivacidad = val!),
                        ),
                        const Divider(),
                        RadioListTile<String>(
                          activeColor: Theme.of(context).primaryColor,
                          title: const Text('Privada', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Solo accesible con código de invitación'),
                          secondary: const Icon(Icons.vpn_key),
                          value: 'privada',
                          groupValue: _preferenciaPrivacidad,
                          onChanged: (val) => setState(() => _preferenciaPrivacidad = val!),
                        ),
                      ],
                    ),
                  ),

                  // 6. ZONA DE PELIGRO (Restaurada)
                  if (widget.ruta != null)
                     _buildDangerZone(context, widget.ruta!, (widget.ruta?.inscritosCount ?? 0) > 0),
                ],
              ),
            ),

            // FOOTER MODERNO
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total Estimado',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _precioController.text.isEmpty || _precioController.text == '0'
                                  ? 'Gratis'
                                  : 'S/ ${_precioController.text}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _crearRuta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        child: Text(widget.ruta == null ? 'CREAR RUTA' : 'GUARDAR'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // --- DANGER ZONE & HELPERS ---
  
  Widget _buildDangerZone(BuildContext context, Ruta ruta, bool hayInscritos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: buttonColor.withValues(alpha: 0.3)),
         boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: buttonColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: buttonColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: buttonColor, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(details, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoCancelarRuta(BuildContext context, Ruta ruta) {
    final vmRutas = context.read<RutasVM>();
    final navigator = GoRouter.of(context);
    // Usamos el Mock o la implementación real según lo configure el locator/provider
    // Aquí asumimos Mock por simplicidad como en el original
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
                      navigator.pop(); // Close dialog
                      navigator.pop(); // Exit screen
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
              navigator.pop(); // Close dialog
              navigator.pop(); // Exit screen
            },
          ),
        ],
      ),
    );
  }

}

extension _ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
