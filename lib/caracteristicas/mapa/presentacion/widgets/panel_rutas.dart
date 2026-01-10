
import 'package:flutter/material.dart';
import '../../../rutas/dominio/entidades/ruta.dart';
import 'indicador_scroll.dart';

class PanelRutas extends StatefulWidget {
  final List<Ruta> rutas;
  final bool isExpanded;
  final Function(bool) onExpandChanged;
  final int subFiltro;
  final Function(int) onSubFiltroChanged;
  final Function() onLimpiarRuta;
  final bool isLimpiarVisible;
  final Function(Ruta) onRutaSelected;
  final double viewportFraction;

  const PanelRutas({
    super.key,
    required this.rutas,
    required this.isExpanded,
    required this.onExpandChanged,
    required this.subFiltro,
    required this.onSubFiltroChanged,
    required this.onLimpiarRuta,
    required this.isLimpiarVisible,
    required this.onRutaSelected,
    this.viewportFraction = 0.85,
  });

  @override
  State<PanelRutas> createState() => _PanelRutasState();
}

class _PanelRutasState extends State<PanelRutas> {
  late PageController _pageController;
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: widget.viewportFraction);
    _pageController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(PanelRutas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.viewportFraction - widget.viewportFraction).abs() > 0.01) {
      final int currentPage = _pageController.hasClients ? (_pageController.page?.round() ?? 0) : 0;
      _pageController.removeListener(_onScroll);
      _pageController.dispose();
      _pageController = PageController(viewportFraction: widget.viewportFraction, initialPage: currentPage);
      _pageController.addListener(_onScroll);
      _currentPageValue = currentPage.toDouble();
    }
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _currentPageValue = _pageController.page ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double screenHeight = constraints.maxHeight;
        final isLandscape = screenWidth > screenHeight;
        final size = Size(screenWidth, screenHeight); // Tamaño del layout (generalmente pantalla completa o stack)



        // --- POSICIONAMIENTO DEL PANEL ---
        final double collapsedHeight = isLandscape ? 100 : 120;
        final double expandedHeight = screenHeight * 0.7;
        final double height = widget.isExpanded ? expandedHeight : collapsedHeight;

        // Posición del Switch (Flotante encima del panel)
        final double switchBottom = widget.isExpanded 
              ? (size.height * 0.7) - 50 
              : (isLandscape ? 110 : 130);

        return Stack(
          alignment: Alignment.bottomCenter, // Importante para el Stack
          children: [
            // 1. EL PANEL (Fondo y Contenido)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              bottom: 0,
              left: 0,
              right: isLandscape ? 60 : 0, // Respetar botones laterales en landscape
              height: height,
              child: Stack(
                children: [
                   // Fondo (Solo visible expandido)
                   if (widget.isExpanded)
                    GestureDetector(
                      onTap: () => widget.onExpandChanged(false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 5)]
                        ),
                      ),
                    ),
                  
                  // Contenido (Lista o Carrusel)
                   Column(
                    children: [
                      const SizedBox(height: 10),
                      Expanded(
                        child: widget.isExpanded
                            ? _buildListaExpandida(isLandscape)
                            : IndicadorScroll(
                                scrollController: _pageController,
                                showArrows: true,
                                child: _buildCarruselRutasAnimado(isLandscape),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. EL SWITCH (Flotante)
            AnimatedPositioned(
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeOutCubic,
               bottom: switchBottom,
               left: isLandscape ? 20 : 0,
               right: isLandscape ? null : 0,
               child: Container(
                 alignment: isLandscape ? Alignment.bottomLeft : Alignment.center,
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     _buildSwitchModerno(),
                     if (widget.isLimpiarVisible) ...[
                       const SizedBox(width: 8),
                       GestureDetector(
                         onTap: widget.onLimpiarRuta,
                         child: Container(
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(
                               color: Colors.redAccent,
                               shape: BoxShape.circle,
                               boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]
                           ),
                           child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                         ),
                       ),
                     ]
                   ],
                 ),
               ),
            ),
          ],
        );
      },
    );
  }

  // --- WIDGETS INTERNOS ---

   Widget _buildSwitchModerno() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => widget.onExpandChanged(!widget.isExpanded),
            child: Container(
              color: Colors.transparent, 
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              child: Icon(
                widget.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                color: Colors.black87,
                size: 22,
              ),
            ),
          ),
          _buildSwitchOption("Inscritas", 0),
          const SizedBox(width: 2),
          _buildSwitchOption("Creadas", 1),
        ],
      ),
    );
  }

  Widget _buildSwitchOption(String label, int index) {
    final isSelected = widget.subFiltro == index;
    return GestureDetector(
      onTap: () => widget.onSubFiltroChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black87 : Colors.transparent, 
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCarruselRutasAnimado(bool isLandscape) {
    // Si la fracción cambia, necesitamos un controller nuevo. 
    // Comprobación rápida:

    final double carruselHeight = isLandscape ? 90 : 110;

    if (widget.rutas.isEmpty) {
      return Container(
        alignment: Alignment.bottomCenter,
        margin: const EdgeInsets.only(bottom: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(30), 
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                widget.subFiltro == 0 ? "No tienes rutas inscritas" : "No has creado rutas",
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: carruselHeight,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.rutas.length,
        itemBuilder: (context, index) {
          final ruta = widget.rutas[index];
          
          double scale = 1.0;
          if (_pageController.hasClients && _pageController.position.haveDimensions) {
            double page = _pageController.page ?? 0;
            double diff = (page - index).abs();
            scale = (1 - (diff * 0.15)).clamp(0.85, 1.0);
          } else {
             scale = (index == _currentPageValue.round()) ? 1.0 : 0.85;
          }

          return Transform.scale(
            scale: scale,
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () => widget.onRutaSelected(ruta),
              child: Container(
                margin: const EdgeInsets.only(bottom: 15, left: 5, right: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      // Imagen (40%)
                      Expanded(
                        flex: 4, 
                        child: Image.network(
                          ruta.urlImagenPrincipal,
                          fit: BoxFit.cover,
                          height: double.infinity,
                          errorBuilder: (_,__,___) => Container(color: Colors.grey.shade100, child: const Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ),
                      // Info (60%)
                      Expanded(
                        flex: 6,
                        child: Row(
                          children: [
                            Expanded(child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(ruta.nombre, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w800, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(3), border: Border.all(color: Colors.grey.shade300)),
                                    child: Text(ruta.categoria.toUpperCase(), style: TextStyle(fontSize: 8, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Icon(Icons.directions_walk, size: 10, color: Colors.blueGrey.shade400),
                                    const SizedBox(width: 2),
                                    Text("${(ruta.distanciaMetros / 1000).toStringAsFixed(1)}km", style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 10, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    Icon(Icons.schedule, size: 10, color: Colors.blueGrey.shade400),
                                    const SizedBox(width: 2),
                                    Text(_formatearDuracion(ruta.duracionSegundos), style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 10, fontWeight: FontWeight.w600)),
                                  ]),
                                ],
                              ),
                            )),
                            Padding(padding: const EdgeInsets.only(right: 8), child: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListaExpandida(bool isLandscape) {
    if (widget.rutas.isEmpty) return const SizedBox();
    
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 60, 16, MediaQuery.of(context).padding.bottom + 20),
      physics: const BouncingScrollPhysics(),
      itemCount: widget.rutas.length,
      itemBuilder: (context, index) {
        final ruta = widget.rutas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                ruta.urlImagenPrincipal,
                width: 60, height: 60, fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(color: Colors.grey.shade200, width: 60, height: 60),
              ),
            ),
            title: Text(ruta.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
               children: [
                 Icon(Icons.directions_walk, size: 14, color: Colors.grey),
                 Text(" ${(ruta.distanciaMetros/1000).toStringAsFixed(1)}km ", style: const TextStyle(fontSize: 12)),
               ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.map, color: Colors.blueAccent),
              onPressed: () => widget.onRutaSelected(ruta),
            ),
            onTap: () => widget.onRutaSelected(ruta),
          ),
        );
      },
    );
  }

  String _formatearDuracion(double segundos) {
    if (segundos <= 0) return "-- min";
    final int minutes = (segundos / 60).round();
    if (minutes < 60) {
      return "$minutes min";
    } else {
      final int hours = (minutes / 60).floor();
      final int mins = minutes % 60;
      return "${hours}h ${mins}m";
    }
  }
}
