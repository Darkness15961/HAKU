// --- PIEDRA 9 (RUTAS): EL "MENÚ" DE DETALLE DE RUTA (CONECTADO AL 100%) ---
//
// 1. Los botones AHORA llaman a los métodos correctos del RutasVM
//    (que a su vez llaman al AuthVM).
// 2. El estado (si está inscrito o favorito) se LEE
//    directamente del "Cerebro" (AuthVM).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM: IMPORTACIONES ---
import '../vista_modelos/rutas_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../dominio/entidades/ruta.dart';

class DetalleRutaPagina extends StatelessWidget {
  final Ruta ruta;

  const DetalleRutaPagina({
    super.key,
    required this.ruta,
  });

  // --- Lógica de Seguridad (Bloqueo Suave) ---
  bool _checkAndRedirect(BuildContext context, String action) {
    final authVM = context.read<AutenticacionVM>();
    if (!authVM.estaLogueado) {
      _showLoginRequiredModal(context, action);
      return false; // BLOQUEADO
    }
    return true; // PERMITIDO
  }

  // --- Lógica de Acciones (Conectadas al "Mesero") ---

  // --- ¡MÉTODO CORREGIDO! ---
  // El handler del botón "Inscribirse/Salir"
  void _handleRegistration(BuildContext context) {
    // 1. Llamamos al "Guardia"
    if (!_checkAndRedirect(context, 'inscribirte en esta ruta')) {
      return;
    }

    // 2. Si el "Guardia" da permiso...
    //    ...leemos el "Cerebro" (AuthVM) para saber el estado
    // --- ¡CONECTADO! Leemos del Cerebro, no de 'ruta' ---
    final vmAuth = context.read<AutenticacionVM>();
    final estaInscrito = vmAuth.rutasInscritasIds.contains(ruta.id);

    // 3. Le damos la "orden" al "Mesero de Rutas" (RutasVM)
    if (estaInscrito) {
      // 4. SÍ ESTÁ INSCRITO: Le damos la "ORDEN"
      context.read<RutasVM>().salirDeRuta(ruta.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has cancelado tu registro (Simulado)')),
      );
    } else {
      // 5. NO ESTÁ INSCRITO: Le damos la "ORDEN"
      context.read<RutasVM>().inscribirseEnRuta(ruta.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('¡Registro a la ruta exitoso! (Simulado)'),
            backgroundColor: Colors.green),
      );
    }
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext context) {
    // "Escuchamos" (watch) a AMBOS "Meseros"
    // final vmRutas = context.watch<RutasVM>(); // No necesitamos escuchar a RutasVM
    final vmAuth = context.watch<AutenticacionVM>(); // ¡El Cerebro!
    final colorPrimario = Theme.of(context).colorScheme.primary;

    // --- ¡LECTURA DE ESTADO DESDE EL CEREBRO! ---
    final bool esFavorita = vmAuth.rutasFavoritasIds.contains(ruta.id);
    final bool estaInscrito = vmAuth.rutasInscritasIds.contains(ruta.id);
    // --- FIN DE LECTURA DE ESTADO ---

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- 1. Tu SliverAppBar (Cabecera) ---
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            backgroundColor: colorPrimario,
            actions: [
              IconButton(
                  onPressed: () {
                    // 1. Verificamos si está logueado
                    if (_checkAndRedirect(context, 'guardar esta ruta')) {
                      // 2. Si SÍ, le damos la "ORDEN" al RutasVM
                      // (RutasVM llamará al Cerebro AuthVM)
                      context.read<RutasVM>().toggleFavoritoRuta(ruta.id);
                    }
                  },
                  // --- ¡CONECTADO AL CEREBRO! ---
                  icon: Icon(
                    esFavorita ? Icons.favorite : Icons.favorite_border,
                    color: esFavorita ? Colors.red : Colors.white,
                  )),
              IconButton(
                  onPressed: () {
                    /* Lógica de Compartir */
                  },
                  icon: const Icon(Icons.share, color: Colors.white)),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 20),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ruta.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // ¡Le pasamos el estado 'estaInscrito' del Cerebro!
                  _buildRouteMetrics(ruta, estaInscrito: estaInscrito),
                ],
              ),
              background: Image.network(
                ruta.urlImagenPrincipal,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.4),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: colorPrimario.withOpacity(0.1),
                  child: Center(
                    child: Icon(Icons.terrain, size: 80, color: colorPrimario),
                  ),
                ),
              ),
            ),
          ),

          // --- 2. Contenido de la Página (SliverList) ---
          SliverList(
            delegate: SliverChildListDelegate(
              [
                // --- Bloque 1: Info Clave (Precio y Cupos) ---
                // ¡Le pasamos el estado 'estaInscrito' del Cerebro!
                _buildPriceAndCapacityCard(context, ruta, estaInscrito: estaInscrito),

                // --- Bloque 2: Perfil del Guía ---
                _buildGuideProfile(context, ruta),

                // --- Bloque 3: Descripción ---
                _buildSectionTitle('Detalles de la Experiencia'),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(ruta.descripcion,
                      style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ),

                // --- Bloque 4: Itinerario (adaptado a nuestra "Receta") ---
                _buildSectionTitle('Itinerario y Lugares Incluidos'),
                _buildRouteStopsList(ruta.lugaresIncluidos),

                const SizedBox(height: 120), // Espacio para el botón inferior
              ],
            ),
          ),
        ],
      ),
      // --- 3. Botón Inferior (Tu diseño) ---
      bottomNavigationBar:
      // ¡Le pasamos el estado 'estaInscrito' del Cerebro!
      _buildRegisterButton(context, vmAuth, ruta, estaInscrito: estaInscrito),
    );
  }

  // --- WIDGETS AUXILIARES (CONECTADOS AL CEREBRO) ---

  // ¡Ahora recibe 'estaInscrito' del Cerebro!
  Widget _buildRouteMetrics(Ruta ruta, {required bool estaInscrito}) {
    Color difficultyColor = ruta.dificultad == 'facil'
        ? Colors.green
        : ruta.dificultad == 'dificil'
        ? Colors.red
        : Colors.orange;

    // Actualizamos el conteo de inscritos localmente si el usuario se inscribe
    int inscritosCount = ruta.inscritosCount;
    // Comparamos el estado "nuevo" (del Cerebro) con el "viejo" (del Mock)
    if (estaInscrito && !ruta.estaInscrito) {
      inscritosCount++;
    } else if (!estaInscrito && ruta.estaInscrito) {
      inscritosCount--;
    }


    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Chip(
          // ¡Usa el conteo actualizado!
          label: Text('$inscritosCount / ${ruta.cupos} Cupos',
              style: const TextStyle(fontSize: 12, color: Colors.white)),
          backgroundColor: Colors.black.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        ),
        const SizedBox(width: 8),
        Chip(
          label: Text(ruta.dificultad.toUpperCase(),
              style: const TextStyle(fontSize: 12)),
          backgroundColor: difficultyColor,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 14),
            Text(ruta.rating.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  // ¡Ahora recibe 'estaInscrito' del Cerebro!
  Widget _buildPriceAndCapacityCard(BuildContext context, Ruta ruta, {required bool estaInscrito}) {

    // (Misma lógica de conteo actualizado)
    int inscritosCount = ruta.inscritosCount;
    if (estaInscrito && !ruta.estaInscrito) {
      inscritosCount++;
    } else if (!estaInscrito && ruta.estaInscrito) {
      inscritosCount--;
    }

    final int availableSpots = ruta.cupos - inscritosCount;
    final bool isRouteFull = availableSpots <= 0;

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Costo
            Column(
              children: [
                const Icon(Icons.local_atm, color: Colors.green, size: 30),
                const SizedBox(height: 4),
                Text('S/ ${ruta.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
                const Text('Costo Total',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            // Cupos
            Column(
              children: [
                Icon(Icons.group,
                    color: isRouteFull ? Colors.red : Colors.indigo, size: 30),
                const SizedBox(height: 4),
                // ¡Usa el conteo actualizado!
                Text('$availableSpots',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isRouteFull ? Colors.red : Colors.indigo)),
                const Text('Cupos Disponibles',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // (El perfil de guía y los títulos no cambian)
  Widget _buildGuideProfile(BuildContext context, Ruta ruta) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(ruta.guiaFotoUrl),
        ),
        title: Text('Organizado por: ${ruta.guiaNombre}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle:
        const Text('Guía Oficial Certificado', style: TextStyle(color: Colors.green)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navegando a Perfil del Guía...')),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10.0),
        child: Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
  }

  Widget _buildRouteStopsList(List<String> lugaresIncluidos) {
    if (lugaresIncluidos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: List.generate(lugaresIncluidos.length, (index) {
          final lugarNombre = lugaresIncluidos[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.indigo,
                        child: Text('${index + 1}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12))),
                    if (index < lugaresIncluidos.length - 1)
                      Container(
                          width: 2, height: 40, color: Colors.indigo.shade200),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(lugarNombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- ¡WIDGET DEL BOTÓN INFERIOR CONECTADO AL CEREBRO! ---
  Widget _buildRegisterButton(
      BuildContext context,
      AutenticacionVM vmAuth,
      Ruta ruta, {
        required bool estaInscrito, // ¡Recibe el estado del Cerebro!
      }) {

    // (La lógica de cupos sigue siendo local)
    int inscritosCount = ruta.inscritosCount;
    if (estaInscrito && !ruta.estaInscrito) {
      inscritosCount++;
    } else if (!estaInscrito && ruta.estaInscrito) {
      inscritosCount--;
    }
    final bool isRouteFull = (ruta.cupos - inscritosCount) <= 0;

    // Leemos del "Mesero de Seguridad"
    final bool isUserLoggedIn = vmAuth.estaLogueado;

    String buttonText;
    Color buttonColor;
    VoidCallback? onPressed;

    // --- ¡LÓGICA DE ESTADO BASADA EN EL CEREBRO! ---
    if (estaInscrito) {
      // Flujo 1: Ya está registrado (según el Cerebro)
      buttonText = 'SALIR DE LA RUTA';
      buttonColor = Colors.red;
      onPressed = () => _handleRegistration(context);
    } else if (isRouteFull) {
      // Flujo 2: Cupos Llenos
      buttonText = 'RUTA LLENA (SIN CUPOS)';
      buttonColor = Colors.grey;
      onPressed = null;
    } else if (!isUserLoggedIn) {
      // Flujo 3: Anónimo (Requiere Login)
      buttonText = 'INICIA SESIÓN PARA UNIRTE';
      buttonColor = Colors.orange;
      onPressed = () => _handleRegistration(context);
    } else {
      // Flujo 4: Disponible y Logueado
      buttonText = 'REGISTRARSE (S/ ${ruta.precio.toStringAsFixed(2)})';
      buttonColor = Colors.indigo;
      onPressed = () => _handleRegistration(context);
    }
    // --- FIN DE LA LÓGICA DE ESTADO ---

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        // ¡Icono conectado al Cerebro!
        icon: Icon(estaInscrito ? Icons.close : Icons.how_to_reg,
            color: Colors.white),
        label: Text(buttonText,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: buttonColor,
          disabledBackgroundColor: Colors.grey.shade400,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 5,
        ),
      ),
    );
  }

  // --- WIDGET AUXILIAR: MODAL DE INVITACIÓN ---
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
}