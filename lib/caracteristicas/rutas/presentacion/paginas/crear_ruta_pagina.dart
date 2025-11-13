// --- PIEDRA 10 (RUTAS): EL "MENÚ" DE CREAR RUTA (VERSIÓN ELEGANTE Y SIMPLIFICADA) ---
//
// 1. (LÓGICA DE NEGOCIO CORREGIDA): El toggle de 'Visibilidad' (Público/Privado)
//    ahora se deshabilita si hay turistas inscritos.
// 2. (LÓGICA DE NEGOCIO CORREGIDA): El botón 'Cancelar Ruta' (que pide un
//    mensaje) solo aparece si hay inscritos.
// 3. (LÓGICA DE NEGOCIO CORREGIDA): El botón 'Eliminar Ruta' solo aparece
//    si NO hay turistas inscritos.
// 4. (LÓGICA DE NEGOCIO CORREGIDA): El diálogo de 'Cancelar Ruta' ahora
//    obliga al guía a escribir un mensaje de disculpa.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

// --- MVVM: IMPORTACIONES ---
import '../vista_modelos/rutas_vm.dart';
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../inicio/dominio/entidades/lugar.dart';
// ¡Importamos la Receta para el 'extra' en app_rutas.dart!
import '../../dominio/entidades/ruta.dart';

// Helper: Clase simple para representar un Lugar en la Ruta
// --- ¡SIMPLIFICADO! Ya no tiene 'durationMinutes' ---
class RouteLocation {
  final Lugar lugar;
  RouteLocation({ required this.lugar });
}

// 1. El "Edificio" (La Pantalla)
class CrearRutaPagina extends StatefulWidget {
  // --- ¡ACOMPLADO! Acepta la ruta para "Editar" ---
  final Ruta? ruta;

  const CrearRutaPagina({
    super.key,
    this.ruta, // <-- Acepta la ruta (nulable)
  });

  @override
  State<CrearRutaPagina> createState() => _CrearRutaPaginaState();
}

class _CrearRutaPaginaState extends State<CrearRutaPagina> {
  // --- Estado Local de la UI ---
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();
  final TextEditingController _precioCtrl = TextEditingController(text: '0');
  final TextEditingController _diasCtrl = TextEditingController(text: '1');
  final TextEditingController _cuposCtrl = TextEditingController(text: '10');

  final _formKey = GlobalKey<FormState>();

  String _selectedDifficulty = 'medio';
  String _visibility = 'Privada';
  bool _estaGuardando = false;

  List<RouteLocation> _locations = [];

  // --- Lógica de Envío de Formulario (¡CORREGIDA PARA UPDATE!) ---
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

    setState(() { _estaGuardando = true; });

    // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
    // 1. Leemos el VM de Autenticación para obtener los datos del guía
    final vmAuth = context.read<AutenticacionVM>();
    if (vmAuth.usuarioActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se pudo identificar al guía.'), backgroundColor: Colors.red)
      );
      setState(() { _estaGuardando = false; });
      return;
    }
    // --- FIN DE CORRECCIÓN ---

    final String diasText = _diasCtrl.text.isEmpty ? '1' : _diasCtrl.text;
    final String cuposText = _cuposCtrl.text.isEmpty ? '10' : _cuposCtrl.text;

    final Map<String, dynamic> datosRuta = {
      'nombre': _nombreCtrl.text,
      'descripcion': _descripcionCtrl.text,
      'precio': double.tryParse(_precioCtrl.text) ?? 0.0,
      'cupos': int.tryParse(cuposText) ?? 10,
      'dificultad': _selectedDifficulty,
      'visible': _visibility == 'Pública',
      'dias': int.tryParse(diasText) ?? 1,
      'lugaresIds': _locations.map((loc) => loc.lugar.id).toList(),
      'lugaresNombres': _locations.map((loc) => loc.lugar.nombre).toList(),

      // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
      // 2. Pasamos los datos REALES del guía al mapa
      'guiaId': vmAuth.usuarioActual!.id,
      'guiaNombre': vmAuth.usuarioActual!.nombre,
      'guiaFotoUrl': vmAuth.usuarioActual!.urlFotoPerfil ?? '',
      // --- FIN DE CORRECCIÓN ---
    };

    try {
      if (!mounted) return;

      String mensajeExito = '';

      // --- ¡AQUÍ ESTÁ LA LÓGICA DE CREAR VS ACTUALIZAR! ---
      if (widget.ruta == null) {
        // MODO CREAR
        await context.read<RutasVM>().crearRuta(datosRuta);
        mensajeExito = '¡Ruta creada con éxito!';
      } else {
        // MODO ACTUALIZAR
        await context.read<RutasVM>().actualizarRuta(widget.ruta!.id, datosRuta);
        mensajeExito = '¡Ruta actualizada con éxito!';
      }
      // --- FIN DE LA LÓGICA ---

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeExito),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(); // Sale de la pág. de edición
        if (widget.ruta != null) {
          context.pop(); // Sale también de la pág. de detalle
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if(mounted) {
        setState(() { _estaGuardando = false; });
      }
    }
  }

  // --- ¡FUNCIÓN DE PREVISUALIZACIÓN CORREGIDA! ---
  void _previsualizarRuta(BuildContext context) {
    // 1. Leemos el VM de Autenticación para los datos del guía
    final vmAuth = context.read<AutenticacionVM>();
    if (vmAuth.usuarioActual == null) return; // Seguridad

    // 2. Recogemos los datos del formulario
    final int cuposTotales = int.tryParse(_cuposCtrl.text) ?? 10;

    // 3. Creamos el objeto Ruta temporal con TODOS los campos
    final Ruta rutaTemporal = Ruta(
      // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
      // Usamos SIEMPRE 'preview_id' para forzar el modo previsualización
      id: 'preview_id',
      // --- FIN DE LA CORRECCIÓN ---

      nombre: _nombreCtrl.text.isEmpty ? 'Nombre de tu Ruta' : _nombreCtrl.text,
      descripcion: _descripcionCtrl.text.isEmpty ? 'Descripción de tu ruta...' : _descripcionCtrl.text,
      precio: double.tryParse(_precioCtrl.text) ?? 0.0,
      cuposTotales: cuposTotales,
      dias: int.tryParse(_diasCtrl.text) ?? 1,
      dificultad: _selectedDifficulty,
      visible: _visibility == 'Pública',
      urlImagenPrincipal: _locations.isNotEmpty
          ? _locations.first.lugar.urlImagen
          : 'https://via.placeholder.com/400x300.png?text=Ruta+sin+Imagen',

      lugaresIncluidos: _locations.map((loc) => loc.lugar.nombre).toList(),
      lugaresIncluidosIds: _locations.map((loc) => loc.lugar.id).toList(),

      // --- Datos del Guía (Leídos del VM) ---
      guiaId: vmAuth.usuarioActual!.id,
      guiaNombre: vmAuth.usuarioActual!.nombre,
      guiaFotoUrl: vmAuth.usuarioActual!.urlFotoPerfil ?? '',

      // --- Valores por Defecto para la Previsualización ---
      rating: widget.ruta?.rating ?? 0.0, // Usa el rating real si estamos editando
      reviewsCount: widget.ruta?.reviewsCount ?? 0,
      inscritosCount: widget.ruta?.inscritosCount ?? 0,
      estaInscrito: false,
      esFavorita: false,
      cuposDisponibles: cuposTotales - (widget.ruta?.inscritosCount ?? 0),
    );

    // 4. Navegamos a la página de detalle, pasando la ruta temporal
    context.push('/rutas/detalle-ruta', extra: rutaTemporal);
  }


  // --- MÉTODO DEL SELECTOR (Corregido y Simplificado) ---
  void _mostrarSelectorLugares() {
    final vmLugares = context.read<LugaresVM>();
    final lugaresDisponibles = vmLugares.lugaresTotales;
    List<String> idsSeleccionados = _locations.map((rl) => rl.lugar.id).toList();

    Set<String> seleccionTemporal = idsSeleccionados.toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  // Header del Modal
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Seleccione Lugares', style: Theme.of(context).textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(modalContext).pop(),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: lugaresDisponibles.length,
                      itemBuilder: (context, index) {
                        final lugar = lugaresDisponibles[index];
                        final estaSeleccionado = seleccionTemporal.contains(lugar.id);
                        return CheckboxListTile(
                          title: Text(lugar.nombre),
                          subtitle: Text(lugar.categoria),
                          value: estaSeleccionado,
                          onChanged: (bool? seleccionado) {
                            setModalState(() {
                              if (seleccionado == true) {
                                seleccionTemporal.add(lugar.id);
                              } else {
                                seleccionTemporal.remove(lugar.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  // Footer del Modal
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: Offset(0, -2))]
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Confirmar (${seleccionTemporal.length}) Lugares'),
                      onPressed: () {
                        setState(() {
                          _locations = seleccionTemporal.map((id) {
                            final lugarEncontrado = lugaresDisponibles.firstWhere((l) => l.id == id);
                            // ¡SIMPLIFICADO! Ya no pasamos 'durationMinutes'
                            return RouteLocation(lugar: lugarEncontrado);
                          }).toList();
                        });
                        Navigator.of(modalContext).pop();
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Métodos de UI (se mantienen) ---
  @override
  void initState() {
    super.initState();
    _nombreCtrl.addListener(() => setState(() {}));
    _descripcionCtrl.addListener(() => setState(() {}));
    _precioCtrl.addListener(() => setState(() {}));
    _diasCtrl.addListener(() => setState(() {}));
    _cuposCtrl.addListener(() => setState(() {}));

    // (Lógica para "Editar Ruta")
    if (widget.ruta != null) {
      _nombreCtrl.text = widget.ruta!.nombre;
      _descripcionCtrl.text = widget.ruta!.descripcion;
      _precioCtrl.text = widget.ruta!.precio.toString();
      _diasCtrl.text = widget.ruta!.dias.toString();
      _cuposCtrl.text = widget.ruta!.cuposTotales.toString();
      _selectedDifficulty = widget.ruta!.dificultad;
      _visibility = widget.ruta!.visible ? 'Pública' : 'Privada';

      // (Pre-cargamos los lugares si estamos editando)
      // (Necesitamos el LugaresVM para esto)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vmLugares = context.read<LugaresVM>();
        // --- ¡LÓGICA CORREGIDA! ---
        // Asumimos que 'lugaresIncluidosIds' SÍ son IDs.
        _locations = widget.ruta!.lugaresIncluidosIds.map((id) {
          final lugar = vmLugares.lugaresTotales.firstWhereOrNull((l) => l.id == id);
          if (lugar != null) {
            return RouteLocation(lugar: lugar);
          }
          return null;
        })
            .whereType<RouteLocation>() // Filtra los nulos
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
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final RouteLocation item = _locations.removeAt(oldIndex);
      _locations.insert(newIndex, item);
    });
  }

  bool _canSave(RutasVM vmRutas) {
    if (vmRutas.estaCargando) return false;
    return _nombreCtrl.text.isNotEmpty &&
        _descripcionCtrl.text.isNotEmpty &&
        _locations.isNotEmpty &&
        (double.tryParse(_precioCtrl.text) ?? 0.0) >= 0;
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext context) {
    final vmRutas = context.watch<RutasVM>();
    final canSave = _canSave(vmRutas);
    final bool modoEdicion = widget.ruta != null;

    // --- ¡LÓGICA DE NEGOCIO IMPLEMENTADA! ---
    final int inscritosCount = widget.ruta?.inscritosCount ?? 0;
    final bool hayInscritos = inscritosCount > 0;

    return Scaffold(
      appBar: AppBar(
        title:
        Text(modoEdicion ? 'Editar Ruta' : 'Crear Ruta', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _estaGuardando
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))),
          )

          // --- ¡AQUÍ ESTÁ LA CORRECCIÓN PROFESIONAL! ---
              : Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: FilledButton(
              onPressed: canSave ? _submitCrearRuta : null,
              style: ButtonStyle(
                // El color de fondo (el botón)
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.white.withOpacity(0.3); // Deshabilitado: Blanco transparente
                    }
                    return Colors.white; // Habilitado: Blanco sólido
                  },
                ),
                // El color del texto (adentro)
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.white.withOpacity(0.7); // Deshabilitado: Texto blanco opaco
                    }
                    // Habilitado: Texto azul (color primario)
                    return Theme.of(context).colorScheme.primary;
                  },
                ),
                textStyle: MaterialStateProperty.all<TextStyle>(
                  const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              child: const Text('Guardar'),
            ),
          ),
          // --- FIN DE LA CORRECCIÓN ---
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 8.0, bottom: 120.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRouteDetailsInputs(),
                  const Divider(height: 32),
                  _buildRouteProperties(context), // <-- ¡Le pasamos el context!
                  const Divider(height: 32),
                  _buildLocationList(),
                  const Divider(height: 32),
                  _buildVisibilityTools(context, hayInscritos), // <-- ¡Corregido!

                  // --- ¡NUEVA SECCIÓN DE GESTIÓN! ---
                  if (modoEdicion)
                    _buildDangerZone(context, widget.ruta!, hayInscritos), // <-- ¡Corregido!
                  // --- FIN DE NUEVA SECCIÓN ---

                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFixedFooter(context), // <-- ¡Añadido context!
            ),
          ],
        ),
      ),
    );
  }

  // --- TUS WIDGETS AUXILIARES (¡Adaptados!) ---
  // (Omitidos por brevedad, son idénticos a tu archivo)

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildRouteDetailsInputs() {
    // (Sin cambios)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('Nombre de la ruta *'),
        TextFormField(
          controller: _nombreCtrl,
          decoration: InputDecoration(
            hintText: 'Ej. Valle Sagrado - 1 día',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) =>
          (v == null || v.isEmpty) ? 'El nombre es obligatorio' : null,
        ),
        const SizedBox(height: 16),
        _buildInputLabel('Descripción *'),
        TextFormField(
          controller: _descripcionCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Detalles sobre la experiencia, qué incluye, etc.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (v) =>
          (v == null || v.isEmpty) ? 'La descripción es obligatoria' : null,
        ),
      ],
    );
  }

  // --- ¡WIDGET ACTUALIZADO! ---
  Widget _buildRouteProperties(BuildContext context) { // <-- ¡Recibe context!
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildNumericInput('Precio (S/) *', _precioCtrl,
                  Icons.monetization_on, isInteger: false),
            ),
            const SizedBox(width: 16),

            // --- ¡AQUÍ ESTÁ LA NUEVA LÓGICA DE VALIDACIÓN! ---
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Cupos *'),
                  TextFormField(
                    controller: _cuposCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.people, color: Theme.of(context).colorScheme.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Requerido';
                      }
                      final int? nuevosCupos = int.tryParse(v);
                      if (nuevosCupos == null) {
                        return 'Inválido';
                      }
                      if (nuevosCupos <= 0) {
                        return 'Debe ser > 0';
                      }

                      // ¡Validación de Inscritos (Modo Edición)!
                      if (widget.ruta != null) {
                        final int inscritosActuales = widget.ruta!.inscritosCount;
                        if (nuevosCupos < inscritosActuales) {
                          // Error con el número exacto de inscritos
                          return 'Min: $inscritosActuales (ya inscritos)';
                        }
                      }
                      return null; // Todo OK
                    },
                  ),
                ],
              ),
            ),
            // --- FIN DE LA LÓGICA DE VALIDACIÓN ---

          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildNumericInput(
                  'Días *', _diasCtrl, Icons.calendar_today, isInteger: true),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Dificultad *'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDifficulty,
                          isExpanded: true,
                          items: ['facil', 'medio', 'dificil'].map((String value) {
                            return DropdownMenuItem<String>(
                                child: Text(value[0].toUpperCase() + value.substring(1)),
                                value: value);
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDifficulty = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumericInput(String label, TextEditingController controller,
      IconData icon, {required bool isInteger}) {
    // (Sin cambios)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: isInteger
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: isInteger
              ? [FilteringTextInputFormatter.digitsOnly]
              : [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) =>
          (v == null || v.isEmpty) ? 'Requerido' : null,
        ),
      ],
    );
  }

  // --- WIDGET DE LISTA DE LUGARES (Sin cambios) ---
  Widget _buildLocationList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('Lugares del Itinerario (${_locations.length}) *'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Añadir / Editar Lugares de la Lista'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          ),
          onPressed: _mostrarSelectorLugares,
        ),
        const SizedBox(height: 16),
        if (_locations.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text('Aún no has añadido lugares.',
                  style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _locations.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              final location = _locations[index];
              return Dismissible(
                key: ValueKey(location.lugar.id + index.toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  setState(() {
                    _locations.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${location.lugar.nombre} eliminado.')));
                },
                background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red.shade400,
                    child: const Icon(Icons.delete, color: Colors.white)),
                child: _buildLocationCard(context, location),
              );
            },
          ),
      ],
    );
  }

  // --- WIDGET DE TARJETA DE LUGAR (¡SIMPLIFICADO!) ---
  Widget _buildLocationCard(BuildContext context, RouteLocation routeLocation) {
    final lugar = routeLocation.lugar;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ReorderableDragStartListener(
                index: _locations.indexOf(routeLocation),
                child: Icon(Icons.drag_indicator, color: Colors.grey.shade600)),
            const SizedBox(width: 8),
            ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                    lugar.urlImagen,
                    width: 60, height: 50, fit: BoxFit.cover,
                    errorBuilder: (_,__,___) => Container(
                        width: 60, height: 50, color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 24, color: Colors.grey)
                    )
                )),
            const SizedBox(width: 12),
            // --- ¡SIMPLIFICADO! Se quitó el campo de minutos ---
            Expanded(
              child: Text(lugar.nombre,
                  style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DE VISIBILIDAD (¡CORREGIDO CON LÓGICA DE NEGOCIO!) ---
  Widget _buildVisibilityTools(BuildContext context, bool hayInscritos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('Visibilidad de la Ruta'),
        const SizedBox(height: 8),
        // Absorbe los toques si hay inscritos
        AbsorbPointer(
          absorbing: hayInscritos,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: hayInscritos ? Colors.grey.shade300 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(child: _buildVisibilityButton('Privada', hayInscritos)),
                Expanded(child: _buildVisibilityButton('Pública', hayInscritos)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // --- ¡NUEVO TEXTO DE AYUDA! ---
        if (hayInscritos)
          Text(
            'No puedes cambiar la visibilidad mientras haya turistas inscritos. Debes "Cancelar la Ruta" primero.',
            style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.bold),
          )
        else
          Text(
              _visibility == 'Pública'
                  ? 'Las rutas públicas requieren aprobación del administrador.'
                  : 'Solo tú puedes ver esta ruta.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildVisibilityButton(String label, bool isDisabled) {
    final bool isSelected = _visibility == label;

    // Define el color del texto cuando está deshabilitado
    Color disabledForegroundColor = isSelected
        ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
        : Colors.grey.shade500;

    return Expanded(
      child: ElevatedButton(
        onPressed: () { // El AbsorbPointer se encarga de deshabilitar
          setState(() {
            _visibility = label;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.white : Colors.transparent,
          // Color del texto (delante)
          foregroundColor: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade600,
          // Color cuando está deshabilitado (por el AbsorbPointer)
          disabledForegroundColor: disabledForegroundColor,
          elevation: isSelected ? 2 : 0,
          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- WIDGET DE FOOTER (¡ACTUALIZADO!) ---
  Widget _buildFixedFooter(BuildContext context) { // <-- ¡Recibe context!

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Días
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Días',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('${_diasCtrl.text.isEmpty ? '0' : _diasCtrl.text} día(s)',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          // Cupos
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cupos',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('${_cuposCtrl.text.isEmpty ? '0' : _cuposCtrl.text} pers.',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          // Botón Previsualizar
          ElevatedButton(
            // --- ¡AQUÍ ESTÁ LA NUEVA LÓGICA! ---
            onPressed: () {
              // Llama a la nueva función de previsualización
              _previsualizarRuta(context);
            },
            // --- FIN DE LA CORRECCIÓN ---
            child: const Icon(Icons.visibility, color: Colors.white),
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    );
  }

  // --- ¡ZONA DE PELIGRO ACTUALIZADA! ---

  Widget _buildDangerZone(BuildContext context, Ruta ruta, bool hayInscritos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        const Text(
          'Zona de Peligro',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 16),

        // --- 1. Botón Cancelar Ruta (SOLO SI HAY INSCRITOS) ---
        if (hayInscritos)
          _buildDangerButton(
            context: context,
            icon: Icons.warning_amber_rounded,
            label: 'Cancelar esta Ruta',
            details: 'Esto notificará y expulsará a ${ruta.inscritosCount} turista(s) inscrito(s). Esta acción es reversible si vuelves a publicar la ruta.',
            onPressed: () {
              _mostrarDialogoCancelarRuta(context, ruta.inscritosCount);
            },
          )
        else
        // --- 2. Botón Eliminar Ruta (SOLO SI NO HAY INSCRITOS) ---
          _buildDangerButton(
            context: context,
            icon: Icons.delete_forever,
            label: 'Eliminar Ruta Permanentemente',
            details: 'Esta acción no se puede deshacer. La ruta se borrará de la base de datos.',
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
        side: BorderSide(color: buttonColor.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      // --- LÓGICA DE PRE-CONFIRMACIÓN CAMBIADA A DIÁLOGO DIRECTO ---
      onPressed: onPressed,
    );
  }

  // --- ¡NUEVOS DIÁLOGOS DE CONFIRMACIÓN! ---

  void _mostrarDialogoCancelarRuta(BuildContext context, int inscritosCount) {
    // Guardamos el VM y el Navigator ANTES del 'await'
    final vmRutas = context.read<RutasVM>();
    final navigator = GoRouter.of(context);

    // Controladores para el nuevo formulario de disculpa
    final TextEditingController mensajeCtrl = TextEditingController();
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (dialogContext) {
        // Usamos StatefulBuilder para que el diálogo maneje su propio estado
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
                    Text('Estás a punto de cancelar esta ruta y expulsar a $inscritosCount turista(s) inscrito(s).'),
                    const SizedBox(height: 16),
                    Text(
                      'Por favor, escribe un mensaje de disculpa o el motivo de la cancelación. Este mensaje se enviará a todos los inscritos.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: mensajeCtrl,
                      autofocus: true,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Ej. "Lamentamos informar que la ruta se cancela por motivos de..."',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Debes escribir un motivo.';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Actualiza el estado del diálogo para habilitar el botón
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('No, volver'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Sí, Cancelar'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  // Se deshabilita si el formulario no es válido
                  onPressed: (mensajeCtrl.text.trim().isEmpty) ? null : () async {
                    if (dialogFormKey.currentState!.validate()) {

                      // ¡Llamamos a la nueva función del VM con el mensaje!
                      await vmRutas.cancelarRuta(widget.ruta!.id, mensajeCtrl.text);

                      if (!context.mounted) return;

                      Navigator.of(dialogContext).pop(); // Cierra el diálogo

                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ruta cancelada y turistas notificados (Simulado).'), backgroundColor: Colors.green)
                      );

                      // Regresa a la página anterior (detalle de ruta)
                      navigator.pop();
                      navigator.pop(); // Y a la lista de rutas
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
    // Guardamos el VM y el Navigator ANTES del 'await'
    final vmRutas = context.read<RutasVM>();
    final navigator = GoRouter.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar Permanentemente?'),
        content: const Text('Esta acción no se puede deshacer. La ruta se borrará de la base de datos.\n\n¿Estás seguro?'),
        actions: [
          TextButton(
            child: const Text('No, volver'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text('Sí, Eliminar'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {

              await vmRutas.eliminarRuta(widget.ruta!.id);

              if (!context.mounted) return;

              Navigator.of(dialogContext).pop(); // Cierra el diálogo

              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ruta eliminada permanentemente (Simulado).'), backgroundColor: Colors.green)
              );

              // Regresa dos páginas (a la lista de rutas)
              navigator.pop();
              navigator.pop();
            },
          ),
        ],
      ),
    );
  }
}

// Extensión (se mantiene)
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}