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

class CrearRutaSinGuiaPagina extends StatefulWidget {
  const CrearRutaSinGuiaPagina({super.key});

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
  final _urlImagenCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController(); // Nuevo campo
  final _equipamientoCtrl = TextEditingController(); // Nuevo campo

  // Estado
  List<RouteLocation> _locations = [];
  String _preferenciaPrivacidad = 'publica';
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
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _puntoEncuentroController.dispose();
    _cuposController.dispose();
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
        codigoAcceso = _generarCodigoAcceso();
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
        'precio': precio,
        'cupos': cupos,
        'dias': 1,
        'visible': true,
        'es_privada': _preferenciaPrivacidad == 'privada',
        'guia_id': userId,
        'url_imagen_principal': urlImagen,
        'lugaresIds': _locations.map((l) => l.lugar.id).toList(),
        'puntos_coordenadas': _locations
            .map((l) => LatLng(l.lugar.latitud, l.lugar.longitud))
            .toList(),
        'lugaresNombres': _locations.map((l) => l.lugar.nombre).toList(),
        'fecha_evento': _fechaEvento?.toIso8601String(),
        'fechaCierreInscripcion': _fechaCierre?.toIso8601String(),
        'punto_encuentro': _puntoEncuentroController.text.isNotEmpty
            ? _puntoEncuentroController.text
            : null,
        'enlace_grupo_whatsapp': _whatsappCtrl.text,
        'equipamientoRuta': _equipamientoCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'estado': 'convocatoria',
        if (codigoAcceso != null) 'codigo_acceso': codigoAcceso,
      };

      await vmRutas.crearRuta(datosRuta);

      setState(() => _creando = false);

      if (mounted) {
        if (codigoAcceso != null) {
          _mostrarCodigoAcceso(codigoAcceso);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Ruta creada con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/rutas');
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
        title: const Text(
          'Diseña tu Aventura',
          style: TextStyle(
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
                        DropdownButtonFormField<String>(
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
                          items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) => setState(() => _categoria = val!),
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildStyledInput(
                                controller: _precioController,
                                label: 'Precio (S/)',
                                prefixIcon: Icons.attach_money,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStyledInput(
                                controller: _cuposController,
                                label: 'Cupos',
                                prefixIcon: Icons.group,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) {
                                  final n = int.tryParse(v ?? '');
                                  if (n == null || n < 1) return 'Mín 1';
                                  return null;
                                },
                              ),
                            ),
                          ],
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
                        child: const Text('CREAR RUTA'),
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
}
