import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../vista_modelos/crear_hakuparada_vm.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/provincia.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';

class CrearHakuparadaPagina extends StatelessWidget {
  const CrearHakuparadaPagina({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CrearHakuparadaVM(),
      child: const _CuerpoWizard(),
    );
  }
}

class _CuerpoWizard extends StatefulWidget {
  const _CuerpoWizard();

  @override
  State<_CuerpoWizard> createState() => _CuerpoWizardState();
}

class _CuerpoWizardState extends State<_CuerpoWizard> {
  final PageController _pageController = PageController();
  int _pasoActual = 0;
  final MapController _mapController = MapController();

  void _siguientePaso() {
    if (_pasoActual < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _pasoActual++);
    }
  }

  void _pasoAnterior() {
    if (_pasoActual > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _pasoActual--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CrearHakuparadaVM>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_tituloSegunPaso(_pasoActual)),
        leading: _pasoActual > 0 
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _pasoAnterior)
            : IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Bloquear swipe manual
        children: [
          _VistaIntroduccion(onConfirm: _siguientePaso),
          _VistaMapa(
            mapController: _mapController,
            vm: vm,
            onConfirm: () {
              if (vm.ubicacionSeleccionada == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debes seleccionar un punto en el mapa")));
                return;
              }
              _siguientePaso();
            },
          ),
          _VistaFormulario(vm: vm),
        ],
      ),
    );
  }

  String _tituloSegunPaso(int paso) {
    switch (paso) {
      case 0: return "Bienvenido";
      case 1: return "Ubicación";
      case 2: return "Detalles";
      default: return "";
    }
  }
}

// --- PASO 1: INTRODUCCIÓN ---
class _VistaIntroduccion extends StatelessWidget {
  final VoidCallback onConfirm;
  const _VistaIntroduccion({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_location_alt_rounded, size: 80, color: Theme.of(context).primaryColor),
          const SizedBox(height: 24),
          const Text(
            "Sugerir Nueva Hakuparada",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            "Ayuda a otros viajeros a descubrir miradores, lugares de descanso o servicios útiles en la ruta.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("COMENZAR AVENTURA"),
            ),
          )
        ],
      ),
    );
  }
}

// --- PASO 2: MAPA FULLSCREEN ---
class _VistaMapa extends StatelessWidget {
  final MapController mapController;
  final CrearHakuparadaVM vm;
  final VoidCallback onConfirm;

  const _VistaMapa({
    required this.mapController,
    required this.vm,
    required this.onConfirm
  });

  void _mostrarDialogoBusqueda(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Buscar por Coordenadas"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "-13.512, -71.987",
            labelText: "Latitud, Longitud",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.datetime, // Para permitir comas y puntos
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.buscarPorCoordenadas(controller.text);
              if (vm.ubicacionSeleccionada != null) {
                mapController.move(vm.ubicacionSeleccionada!, 16);
              } else if (vm.error != null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error!)));
                }
              }
            },
            child: const Text("BUSCAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: vm.ubicacionSeleccionada ?? const LatLng(-13.5319, -71.9675),
            initialZoom: 13.0,
            onTap: (_, punto) => vm.seleccionarUbicacion(punto),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.xplore.cusco',
            ),
            if (vm.ubicacionSeleccionada != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: vm.ubicacionSeleccionada!,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 50),
                  ),
                ],
              ),
          ],
        ),
        
        // Herramientas Superiores (Dirección y Buscador)
        Positioned(
          top: 50, // Más abajo para no chocar con Status Bar
          left: 16,
          right: 16,
          child: Column(
            children: [
              // CARD FLOTANTE DE DIRECCIÓN
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _mostrarDialogoBusqueda(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF00BCD4)), // Cyan
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vm.direccionDetectada.isEmpty ? "Detectando..." : vm.direccionDetectada,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  "Toca para buscar por coordenadas",
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                )
                              ],
                            ),
                          ),
                          const Icon(Icons.search, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Botones Flotantes (GPS)
        Positioned(
          bottom: 140, // Encima del panel inferior
          right: 16,
          child: FloatingActionButton(
             heroTag: "btn_gps_wizard",
             onPressed: () async {
                 await vm.usarMiUbicacion();
                 if (vm.ubicacionSeleccionada != null) {
                   mapController.move(vm.ubicacionSeleccionada!, 16);
                 }
             },
             backgroundColor: Colors.white,
             child: const Icon(Icons.my_location, color: Colors.black87),
          ),
        ),

        // PANEL INFERIOR DE CONFIRMACIÓN
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: const BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
               boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (vm.provinciaSeleccionada != null)
                   Container(
                     margin: const EdgeInsets.only(bottom: 16),
                     padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                     decoration: BoxDecoration(
                       color: Colors.green.shade50,
                       borderRadius: BorderRadius.circular(10),
                       border: Border.all(color: Colors.green.shade200)
                     ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         const Icon(Icons.check_circle, size: 18, color: Colors.green),
                         const SizedBox(width: 8),
                         Text(
                           "Provincia: ${vm.provinciaSeleccionada!.nombre}", 
                           style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)
                         ),
                       ],
                     ),
                   ),
                ElevatedButton(
                  onPressed: vm.ubicacionSeleccionada == null ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("CONFIRMAR UBICACIÓN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- PASO 3: FORMULARIO DETALLES ---
class _VistaFormulario extends StatelessWidget {
  final CrearHakuparadaVM vm;
  const _VistaFormulario({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PROVINCIA (Bloqueada/Visible)
          DropdownButtonFormField<Provincia>(
            decoration: const InputDecoration(labelText: 'Provincia *', border: OutlineInputBorder()),
            value: vm.provinciaSeleccionada,
            items: vm.provincias.map<DropdownMenuItem<Provincia>>((Provincia p) => DropdownMenuItem(value: p, child: Text(p.nombre))).toList(),
            onChanged: vm.seleccionarProvincia, // Permitimos cambiar si falló la detección
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<Lugar?>(
            decoration: const InputDecoration(labelText: 'Lugar Cercano (Referencia)', border: OutlineInputBorder()),
            value: vm.lugarSeleccionado,
            items: [
              const DropdownMenuItem<Lugar?>(value: null, child: Text("Ninguno / De paso")),
              ...vm.lugaresFiltrados.map<DropdownMenuItem<Lugar?>>((Lugar l) => DropdownMenuItem(value: l, child: Text(l.nombre))),
            ],
            onChanged: vm.provinciaSeleccionada == null ? null : vm.seleccionarLugar, 
          ),
          const SizedBox(height: 24),

          const Text("Categoría *", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: ['Mirador', 'Descanso', 'Servicios Higiénicos', 'Tienda/Kiosko', 'Dato Curioso'].map((cat) {
              return ChoiceChip(
                label: Text(cat),
                selected: vm.categoriaSeleccionada == cat,
                onSelected: (bool selected) {
                  if (selected) vm.seleccionarCategoria(cat);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: vm.nombreController,
            decoration: const InputDecoration(labelText: 'Nombre corto *', border: OutlineInputBorder(), hintText: "Ej: Mirador de curva 5"),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: vm.descripcionController,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Descripción / Dato Útil', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),

          // FOTO
          GestureDetector(
            onTap: () async {
              if (vm.fotoSeleccionada != null) return; // Si ya hay foto, el boton X la quita
              
              final ImagePicker picker = ImagePicker();
              // Mostrar dialogo para elegir camara o galeria
              showModalBottomSheet(context: context, builder: (ctx) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(leading: const Icon(Icons.camera_alt), title: const Text("Cámara"), onTap: () async {
                     Navigator.pop(ctx);
                     final img = await picker.pickImage(source: ImageSource.camera);
                     if (img != null) vm.setFoto(File(img.path));
                  }),
                  ListTile(leading: const Icon(Icons.photo), title: const Text("Galería"), onTap: () async {
                     Navigator.pop(ctx);
                     final img = await picker.pickImage(source: ImageSource.gallery);
                     if (img != null) vm.setFoto(File(img.path));
                  }),
                ],
              ));
            },
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade100
              ),
              child: vm.fotoSeleccionada == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 60, color: Colors.blueGrey),
                        SizedBox(height: 12),
                        Text("Toca para agregar foto *", style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(vm.fotoSeleccionada!, fit: BoxFit.cover)),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => vm.limpiarFoto(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle
                              ),
                              child: const Icon(Icons.close, color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 40),

          // BOTON FINAL
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: vm.estaCargando ? null : () async {
                final exito = await vm.guardarHakuparada();
                if (exito && context.mounted) {
                   _mostrarDialogoExito(context);
                } else if (vm.error != null && context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.error!), backgroundColor: Colors.red));
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                elevation: 4
              ),
              child: vm.estaCargando 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("PUBLICAR HAKUPARADA"),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _mostrarDialogoExito(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("¡Publicación Exitosa! 🎉"),
        content: const Text(
          "Tu aporte ha sido enviado a revisión.\n\n"
          "Puedes ver el estado en 'Mis Hakuparadas'."
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // Close Dialog
              context.go('/perfil/mis-hakuparadas'); // Go to list
            },
            child: const Text("VER MIS APORTES"),
          )
        ],
      ),
    );
  }
}
