// --- PIEDRA 6.5: PÁGINA DE LUGARES POR PROVINCIA (FINAL Y ESTÉTICO) ---
//
// (...)
// 5. (¡DISEÑO ELEGANTE!): Se rediseñó _buildLugaresList para mover
//    el chip de categoría a la imagen.
// 6. (¡DISEÑO ELEGANTE 2.0!): Se cambió el chip de categoría por un
//    contenedor con gradiente para un look más profesional.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM: IMPORTACIONES ---
import '../vista_modelos/lugares_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/provincia.dart';
import '../../dominio/entidades/categoria.dart';


class ProvinciaLugaresPagina extends StatefulWidget {
  final Provincia provincia;

  const ProvinciaLugaresPagina({super.key, required this.provincia});

  @override
  State<ProvinciaLugaresPagina> createState() => _ProvinciaLugaresPaginaState();
}

class _ProvinciaLugaresPaginaState extends State<ProvinciaLugaresPagina> {
  final TextEditingController _searchCtrl = TextEditingController();

  // --- Lógica de Carga Inicial ---
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // 1. Pedimos al Mesero de Lugares que cargue solo los datos de esta provincia.
      context
          .read<LugaresVM>()
          .cargarLugaresPorProvincia(widget.provincia.id);
    });
    // Sincronizamos la búsqueda con el VM
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Esto dispara la lógica de filtro dentro del getter lugaresFiltradosDeProvincia
    context.read<LugaresVM>().buscarEnProvincia(_searchCtrl.text);
  }

  // --- Lógica de Seguridad (El Guardia) ---
  bool _checkAndRedirect(BuildContext context, String action) {
    final authVM = context.read<AutenticacionVM>();

    if (!authVM.estaLogueado) {
      _showLoginRequiredModal(context, action);
      return false; // BLOQUEADO
    }
    return true; // PERMITIDO
  }

  // --- Lógica de Toggle Favorito (Conectada y Protegida) ---
  void _onToggleFavorito(BuildContext context, Lugar lugar) {
    // 1. Llama al "Guardia"
    if (!_checkAndRedirect(context, 'guardar este lugar')) {
      return; // Si es anónimo, se detiene aquí.
    }
    // 2. Si el "Guardia" da permiso, llama al VM
    context.read<LugaresVM>().toggleLugarFavorito(lugar.id);
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext contex) {
    // Escuchamos a los dos ViewModels
    final vmLugares = context.watch<LugaresVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    // Lista ya filtrada y buscada (usa el getter)
    final List<Lugar> lugares = vmLugares.lugaresFiltradosDeProvincia;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.provincia.nombre),
        foregroundColor: Colors.white,
        backgroundColor: colorPrimario,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Búsqueda y Filtros
          _buildSearchAndFilterRow(context, vmLugares),

          // 2. Contenido Principal
          Expanded(
            child: vmLugares.estaCargandoLugaresDeProvincia
                ? const Center(child: CircularProgressIndicator())
                : lugares.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 50, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text('No se encontraron lugares con esos filtros.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
                : _buildLugaresList(context, vmLugares, lugares),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Diseño Profesional) ---

  Widget _buildSearchAndFilterRow(BuildContext context, LugaresVM vmLugares) {
    // (Tu código intacto aquí...)
    final List<Categoria> categorias = [
      Categoria(id: '1', nombre: 'Todos', urlImagen: ''),
      ...vmLugares.categorias.where((c) => c.id != '1').toList()
    ];

    final String selectedCategoryId = vmLugares.categoriaSeleccionadaIdProvincia;
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar lugar...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ]
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategoryId,
                icon: Icon(Icons.filter_list, color: colorPrimario),
                items: categorias.map((Categoria c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.nombre, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    vmLugares.seleccionarCategoriaEnProvincia(newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ¡WIDGET REDISEÑADO PARA SER MÁS ELEGANTE! ---
  Widget _buildLugaresList(BuildContext context, LugaresVM vmLugares, List<Lugar> lugares) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: lugares.length,
      itemBuilder: (context, index) {
        final lugar = lugares[index];
        final bool esFavorito = vmLugares.esLugarFavorito(lugar.id);
        // final colorPrimario = Theme.of(context).colorScheme.primary; // Ya no lo usamos aquí

        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 6,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Imagen y Botón de Favorito
              Stack(
                children: [
                  // Imagen (Navega al Detalle)
                  InkWell(
                    onTap: () {
                      context.push('/inicio/detalle-lugar', extra: lugar);
                    },
                    child: Hero(
                      tag: 'lugar_imagen_${lugar.id}_provincia',
                      child: Image.network(
                        lugar.urlImagen,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Center(child: Icon(Icons.place_outlined, size: 50, color: Colors.grey[400])),
                        ),
                      ),
                    ),
                  ),

                  // Botón de Favorito (Protegido)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          esFavorito ? Icons.favorite : Icons.favorite_border,
                          color: esFavorito ? Colors.red : Colors.white,
                          size: 28,
                        ),
                        onPressed: () => _onToggleFavorito(context, lugar),
                      ),
                    ),
                  ),

                  // --- ¡CORRECCIÓN DE DISEÑO! (No más "azul feo") ---
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    // Usamos un gradiente negro para asegurar legibilidad
                    child: Container(
                      height: 60, // Altura del gradiente
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        lugar.categoria,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // --- FIN DE LA CORRECCIÓN DE DISEÑO ---
                ],
              ),

              // 2. Contenido de Texto
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título y Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            lugar.nombre,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildRating(lugar.rating),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Text(lugar.descripcion,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // --- FIN DEL REDISEÑO ---

  Widget _buildRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Colors.amber, size: 18),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  // --- WIDGET AUXILIAR: MODAL DE INVITACIÓN (Bloqueo Suave) ---
  void _showLoginRequiredModal(BuildContext context, String action) {
    // (Tu código intacto aquí...)
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
}