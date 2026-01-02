import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../vista_modelos/solicitudes_vm.dart';
import '../../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../../inicio/dominio/entidades/lugar.dart';
import '../../../dominio/entidades/solicitud_ruta.dart';

class CrearSolicitudPagina extends StatefulWidget {
  const CrearSolicitudPagina({Key? key}) : super(key: key);

  @override
  State<CrearSolicitudPagina> createState() => _CrearSolicitudPaginaState();
}

class _CrearSolicitudPaginaState extends State<CrearSolicitudPagina> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _presupuestoController = TextEditingController();
  final _grupoObjetivoController = TextEditingController();
  // Video controller removed
  final _notasController = TextEditingController();

  DateTime? _fechaSeleccionada;
  int _numeroPersonas = 1;
  String _preferenciaPrivacidad = 'publica';
  List<Lugar> _lugaresSeleccionados = [];
  bool _creando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _presupuestoController.dispose();
    _grupoObjetivoController.dispose();
    // Video controller disposed
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).primaryColor;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorPrimario.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, colorPrimario),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildSeccion('📝 Información Básica', [
                        _buildCampoTexto(
                          controller: _tituloController,
                          label: 'Título de la ruta',
                          hint: 'Ej: Tour Valle Sagrado',
                          icono: Icons.title,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 15),
                        _buildCampoTexto(
                          controller: _descripcionController,
                          label: 'Descripción',
                          hint: 'Describe qué te gustaría hacer...',
                          icono: Icons.description,
                          maxLineas: 4,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Campo requerido' : null,
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildSeccion('📍 Lugares a Visitar', [
                        _buildSelectorLugares(),
                      ]),
                      const SizedBox(height: 20),
                      _buildSeccion('📅 Detalles del Viaje', [
                        _buildSelectorFecha(),
                        const SizedBox(height: 15),
                        _buildSelectorPersonas(),
                        const SizedBox(height: 15),
                        _buildCampoTexto(
                          controller: _presupuestoController,
                          label: 'Presupuesto Máximo (Opcional)',
                          hint: 'Ej: 500',
                          icono: Icons.attach_money,
                          teclado: TextInputType.number,
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildSeccion('🔒 Privacidad', [
                        _buildSelectorPrivacidad(),
                      ]),
                      const SizedBox(height: 20),
                      _buildSeccion('📎 Información Adicional (Opcional)', [
                        // Video field removed
                        _buildCampoTexto(
                          controller: _notasController,
                          label: 'Notas Adicionales',
                          hint:
                              'Restricciones dietéticas, necesidades especiales, etc.', // More specific hint
                          icono: Icons.note,
                          maxLineas: 3,
                        ),
                      ]),
                      const SizedBox(height: 30),
                      _buildBotonCrear(colorPrimario),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color colorPrimario) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Crear Solicitud de Ruta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorPrimario,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icono,
    int maxLineas = 1,
    TextInputType teclado = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLineas,
      keyboardType: teclado,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icono),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildSelectorLugares() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _mostrarSelectorLugares,
          icon: const Icon(Icons.add_location),
          label: const Text('Agregar Lugares'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        if (_lugaresSeleccionados.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _lugaresSeleccionados.map((lugar) {
              return Chip(
                label: Text(lugar.nombre),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _lugaresSeleccionados.remove(lugar);
                  });
                },
              );
            }).toList(),
          ),
        ],
        if (_lugaresSeleccionados.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Selecciona al menos un lugar',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectorFecha() {
    return InkWell(
      onTap: _seleccionarFecha,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _fechaSeleccionada == null
                    ? 'Seleccionar fecha deseada'
                    : _formatearFecha(_fechaSeleccionada!),
                style: TextStyle(
                  color: _fechaSeleccionada == null
                      ? Colors.grey[600]
                      : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorPersonas() {
    return Row(
      children: [
        const Icon(Icons.people),
        const SizedBox(width: 15),
        const Text('Número de personas:'),
        const Spacer(),
        IconButton(
          onPressed: _numeroPersonas > 1
              ? () => setState(() => _numeroPersonas--)
              : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '$_numeroPersonas',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: () => setState(() => _numeroPersonas++),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _buildSelectorPrivacidad() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Pública'),
          subtitle: const Text('Cualquiera puede inscribirse'),
          value: 'publica',
          groupValue: _preferenciaPrivacidad,
          onChanged: (value) {
            setState(() => _preferenciaPrivacidad = value!);
          },
        ),
        RadioListTile<String>(
          title: const Text('Privada'),
          subtitle: const Text('Solo con código de acceso'),
          value: 'privada',
          groupValue: _preferenciaPrivacidad,
          onChanged: (value) {
            setState(() => _preferenciaPrivacidad = value!);
          },
        ),
        if (_preferenciaPrivacidad == 'privada') ...[
          const SizedBox(height: 10),
          _buildCampoTexto(
            controller: _grupoObjetivoController,
            label: '¿Quiénes conforman el grupo?', // Clearer label
            hint:
                'Ej: Familia con niños, Grupo de estudiantes, Pareja mayor...', // Clearer hint
            icono: Icons.group,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Se generará un código único que deberás compartir',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBotonCrear(Color colorPrimario) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _creando ? null : _crearSolicitud,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimario,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _creando
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Crear Solicitud',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _mostrarSelectorLugares() {
    final vmLugares = context.read<LugaresVM>();

    // Asegurarse de que los lugares estén cargados
    if (vmLugares.lugaresTotales.isEmpty) {
      vmLugares.cargarTodosLosLugares();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Seleccionar Lugares'),
              content: SizedBox(
                width: double.maxFinite,
                child: Consumer<LugaresVM>(
                  builder: (context, vm, _) {
                    if (vm.estaCargandoGestion) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (vm.lugaresTotales.isEmpty) {
                      return const Center(
                        child: Text('No hay lugares disponibles'),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: vm.lugaresTotales.length,
                      itemBuilder: (context, index) {
                        final lugar = vm.lugaresTotales[index];
                        final estaSeleccionado = _lugaresSeleccionados.any(
                          (l) => l.id == lugar.id,
                        );

                        return CheckboxListTile(
                          title: Text(lugar.nombre),
                          // Subtitle removed to avoid lint error (categoria not in Lugar)
                          value: estaSeleccionado,
                          onChanged: (bool? valor) {
                            setStateDialog(() {
                              if (valor == true) {
                                _lugaresSeleccionados.add(lugar);
                              } else {
                                _lugaresSeleccionados.removeWhere(
                                  (l) => l.id == lugar.id,
                                );
                              }
                            });
                            // Actualizar la vista principal también
                            setState(() {});
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Listo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now().add(const Duration(days: 2)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  Future<void> _crearSolicitud() async {
    if (!_formKey.currentState!.validate()) return;

    if (_lugaresSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un lugar')),
      );
      return;
    }

    if (_fechaSeleccionada == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una fecha')));
      return;
    }

    setState(() => _creando = true);

    final vmAuth = context.read<AutenticacionVM>();
    final vmSolicitudes = context.read<SolicitudesVM>();

    final solicitud = SolicitudRuta(
      id: '',
      turistaId: vmAuth.usuarioActual!.id,
      titulo: _tituloController.text,
      descripcion: _descripcionController.text,
      lugaresIds: _lugaresSeleccionados.map((l) => int.parse(l.id)).toList(),
      fechaDeseada: _fechaSeleccionada!,
      numeroPersonas: _numeroPersonas,
      presupuestoMaximo: _presupuestoController.text.isNotEmpty
          ? double.tryParse(_presupuestoController.text)
          : null,
      estado: 'buscando_guia',
      preferenciaPrivacidad: _preferenciaPrivacidad,
      grupoObjetivo: _grupoObjetivoController.text.isNotEmpty
          ? _grupoObjetivoController.text
          : null,
      fechaCreacion: DateTime.now(),
      // Video reference removed
      notasAdicionales: _notasController.text.isNotEmpty
          ? _notasController.text
          : null,
    );

    final exito = await vmSolicitudes.crearSolicitud(solicitud);

    setState(() => _creando = false);

    if (exito) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Solicitud creada exitosamente')),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Error al crear solicitud')),
        );
      }
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
}
