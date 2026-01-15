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
import '../widgets/route_location.dart';

class CrearRutaSinGuiaPagina extends StatefulWidget {
  const CrearRutaSinGuiaPagina({Key? key}) : super(key: key);

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

  // Estado
  List<RouteLocation> _locations = [];
  String _preferenciaPrivacidad = 'publica';
  DateTime? _fechaEvento;
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
        'punto_encuentro': _puntoEncuentroController.text.isNotEmpty
            ? _puntoEncuentroController.text
            : null,
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

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStyledInput({
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    IconData? prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Theme.of(context).primaryColor)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha != null) {
      setState(() => _fechaEvento = fecha);
    }
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear Ruta Personalizada',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          _creando
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: FilledButton(
                    onPressed: _crearRuta,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.white),
                      foregroundColor: MaterialStateProperty.all(
                        Theme.of(context).primaryColor,
                      ),
                      textStyle: MaterialStateProperty.all(
                        const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                  // 1. INFO BÁSICA ESTILO UNIFICADO
                  _buildInputLabel('Nombre de la ruta *'),
                  _buildStyledInput(
                    controller: _nombreController,
                    hintText: 'Ej. Tour por el Valle Sagrado',
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel('Descripción *'),
                  _buildStyledInput(
                    controller: _descripcionController,
                    hintText: 'Detalles sobre la experiencia...',
                    maxLines: 4,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 24),

                  // PRECIO Y CUPOS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Precio (S/)'),
                            _buildStyledInput(
                              controller: _precioController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'),
                                ),
                              ],
                              prefixIcon: Icons.monetization_on,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Cupos *'),
                            _buildStyledInput(
                              controller: _cuposController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              prefixIcon: Icons.people,
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                if (n == null || n < 1) return 'Mín 1';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // FECHA Y CATEGORÍA
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Fecha *'),
                            InkWell(
                              onTap: _seleccionarFecha,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 20,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _fechaEvento == null
                                            ? 'Seleccionar'
                                            : _formatearFecha(_fechaEvento!),
                                        style: _fechaEvento == null
                                            ? TextStyle(
                                                color: Colors.grey.shade600,
                                              )
                                            : null,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Categoría *'),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _categoria,
                                  isExpanded: true,
                                  items: _categorias.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    if (newValue != null) {
                                      setState(() => _categoria = newValue);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel('Punto de Encuentro'),
                  _buildStyledInput(
                    controller: _puntoEncuentroController,
                    hintText: 'Ej: Plaza de Armas',
                    prefixIcon: Icons.location_on,
                  ),
                  const SizedBox(height: 24),

                  // 2. SUBIDA IMAGEN (Reutilizado)
                  SubidaImagenRuta(urlImagenCtrl: _urlImagenCtrl),

                  const Divider(height: 32),

                  // 3. SELECTOR DE LUGARES (Reutilizado)
                  SelectorLugaresRuta(
                    locations: _locations,
                    onLocationsChanged: (newList) =>
                        setState(() => _locations = newList),
                  ),

                  const Divider(height: 32),

                  // 4. PRIVACIDAD (Estilo Local Guide)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Tipo de Ruta (Acceso)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Pública'),
                          subtitle: const Text(
                            'Cualquier usuario puede inscribirse',
                          ),
                          value: 'publica',
                          groupValue: _preferenciaPrivacidad,
                          onChanged: (val) =>
                              setState(() => _preferenciaPrivacidad = val!),
                        ),
                        RadioListTile<String>(
                          title: const Text('Privada con Código'),
                          subtitle: const Text('Solo con invitación'),
                          value: 'privada',
                          groupValue: _preferenciaPrivacidad,
                          onChanged: (val) =>
                              setState(() => _preferenciaPrivacidad = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // FOOTER FIJO
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Precio',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _precioController.text.isEmpty ||
                                  _precioController.text == '0'
                              ? 'Gratis'
                              : 'S/ ${_precioController.text}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cupos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${_cuposController.text} pers.',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _crearRuta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Crear Ruta',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
