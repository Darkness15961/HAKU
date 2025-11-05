// --- PIEDRA 9 (RUTAS): EL "MENÚ" DE DETALLE DE RUTA ---
//
// Esta es la pantalla que muestra el detalle de una Ruta.
//
// Está basada 100% en tu "molde" de diseño
// (SliverAppBar, grilla de info, itinerario, etc.)
//
// Se conecta a DOS "Meseros":
// 1. "RutasVM" (para dar las "órdenes" de inscribirse o salir)
// 2. "AutenticacionVM" (para saber si el usuario está logueado)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM: IMPORTACIONES ---
// 1. Importamos el "Mesero de Rutas"
import '../vista_modelos/rutas_vm.dart';
// 2. Importamos el "Mesero de Seguridad"
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
// 3. Importamos la "Receta" (Entidad)
import '../../dominio/entidades/ruta.dart';

// 1. El "Edificio" (La Pantalla)
//    Recibe la "Receta" Ruta completa,
//    tal como lo definimos en nuestro "GPS" (app_rutas.dart).
class DetalleRutaPagina extends StatelessWidget {
  final Ruta ruta;

  const DetalleRutaPagina({
    super.key,
    required this.ruta,
  });

  // --- Lógica de Seguridad (Bloqueo Suave) ---
  //
  // Esta es la misma función "Guardia" que usamos en el Menú 1.
  // Revisa si el usuario está logueado ANTES de hacer una acción.
  bool _checkAndRedirect(BuildContext context, String action) {
    // "context.read" (leer) es para dar una orden o leer un estado
    // una sola vez. No "escucha" cambios.
    final authVM = context.read<AutenticacionVM>();
    if (!authVM.estaLogueado) {
      // Si no está logueado, muestra el Modal de Invitación
      _showLoginRequiredModal(context, action);
      return false; // BLOQUEADO
    }
    return true; // PERMITIDO
  }

  // --- Lógica de Acciones (Conectadas al "Mesero") ---
  //
  // Esta es la lógica de tu botón "Registrarse/Salir"
  // (Basado en tu función _handleRegistration)
  void _handleRegistration(BuildContext context) {
    // 1. Primero, llamamos al "Guardia"
    if (!_checkAndRedirect(context, 'inscribirte en esta ruta')) {
      return; // Si es anónimo, el Modal aparece y la función se detiene.
    }

    // 2. Si el "Guardia" da permiso (está logueado)...
    //    ...leemos el "Mesero de Rutas"
    final vmRutas = context.read<RutasVM>();

    // 3. Revisamos el estado de la ruta (de la "Receta")
    if (ruta.estaInscrito) {
      // 4. SÍ ESTÁ INSCRITO: Le damos la "ORDEN 5" al "Mesero"
      vmRutas.salirDeRuta(ruta.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has cancelado tu registro (Simulado)')),
      );
    } else {
      // 5. NO ESTÁ INSCRITO: Le damos la "ORDEN 4" al "Mesero"
      vmRutas.inscribirseEnRuta(ruta.id);
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
    // --- MVVM: Conexión con los "Meseros" ---
    // "Escuchamos" (watch) a AMBOS "Meseros"
    final vmRutas = context.watch<RutasVM>();
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

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
                    // --- MVVM: ORDEN AL "MESERO" ---
                    // 1. Verificamos si está logueado
                    if (_checkAndRedirect(context, 'guardar esta ruta')) {
                      // 2. Si SÍ, le damos la "ORDEN 6"
                      context.read<RutasVM>().toggleFavoritoRuta(ruta.id);
                    }
                  },
                  // --- MVVM: LECTURA DE ESTADO ---
                  // Leemos el estado de la "Receta"
                  icon: Icon(
                    ruta.esFavorita ? Icons.favorite : Icons.favorite_border,
                    color: ruta.esFavorita ? Colors.red : Colors.white,
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
              // Usamos los datos de nuestra "Receta" (Ruta)
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
                  _buildRouteMetrics(ruta), // Tu widget de métricas
                ],
              ),
              background: Image.network(
                ruta.urlImagenPrincipal,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.4),
                colorBlendMode: BlendMode.darken,
                // (El "fallback amigable" que te gustó)
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
                _buildPriceAndCapacityCard(context, ruta),

                // --- Bloque 2: Perfil del Guía ---
                _buildGuideProfile(context, ruta),

                // --- Bloque 3: Descripción ---
                _buildSectionTitle('Detalles de la Experiencia'),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  // Usamos la descripción de la "Receta"
                  child: Text(ruta.descripcion,
                      style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ),

                // --- Bloque 4: Itinerario (adaptado a nuestra "Receta") ---
                _buildSectionTitle('Itinerario y Lugares Incluidos'),
                _buildRouteStopsList(ruta.lugaresIncluidos),

                // (Omitimos la sección de Comentarios por ahora,
                // como hablamos, para no mezclar lógicas)

                const SizedBox(height: 120), // Espacio para el botón inferior
              ],
            ),
          ),
        ],
      ),
      // --- 3. Botón Inferior (Tu diseño) ---
      // (Conectado a nuestra lógica MVVM)
      bottomNavigationBar:
      _buildRegisterButton(context, vmRutas, vmAuth, ruta),
    );
  }

  // --- WIDGETS AUXILIARES (¡Tu diseño, adaptado a MVVM!) ---

  // (Tu widget de métricas, conectado a la "Receta" Ruta)
  Widget _buildRouteMetrics(Ruta ruta) {
    Color difficultyColor = ruta.dificultad == 'facil'
        ? Colors.green
        : ruta.dificultad == 'dificil'
        ? Colors.red
        : Colors.orange;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Chip(
          // Usamos los datos de la "Receta"
          label: Text('${ruta.inscritosCount} / ${ruta.cupos} Cupos',
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

  // (Tu grilla de info, conectada a la "Receta" Ruta)
  Widget _buildPriceAndCapacityCard(BuildContext context, Ruta ruta) {
    // Calculamos los cupos (de la "Receta")
    final int availableSpots = ruta.cupos - ruta.inscritosCount;
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
                // (Usamos el ícono "amigable" que te gustó)
                const Icon(Icons.local_atm, color: Colors.green, size: 30),
                const SizedBox(height: 4),
                // Usamos el precio de la "Receta"
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

  // (Tu perfil de guía, conectado a la "Receta" Ruta)
  Widget _buildGuideProfile(BuildContext context, Ruta ruta) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          // Usamos la foto del guía de la "Receta"
          backgroundImage: NetworkImage(ruta.guiaFotoUrl),
        ),
        title: Text('Organizado por: ${ruta.guiaNombre}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle:
        const Text('Guía Oficial Certificado', style: TextStyle(color: Colors.green)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          // TODO: Navegar al perfil público del Guía
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navegando a Perfil del Guía...')),
          );
        },
      ),
    );
  }

  // (Tu título de sección)
  Widget _buildSectionTitle(String title) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10.0),
        child: Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
  }

  // (Tu itinerario, ADAPTADO a nuestra "Receta" simple)
  Widget _buildRouteStopsList(List<String> lugaresIncluidos) {
    if (lugaresIncluidos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: List.generate(lugaresIncluidos.length, (index) {
          // Leemos el nombre del lugar de la "Receta"
          final lugarNombre = lugaresIncluidos[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // La línea de tiempo de tu diseño
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
                // El nombre del lugar (de nuestra "Receta")
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

  // (Tu botón inferior, CONECTADO a los "Meseros")
  Widget _buildRegisterButton(
      BuildContext context,
      RutasVM vmRutas,
      AutenticacionVM vmAuth,
      Ruta ruta,
      ) {
    // --- ¡LÓGICA MVVM! ---
    //
    // Leemos el estado de nuestros "Meseros" y "Recetas"
    // para decidir qué botón mostrar.
    // (Esta es la lógica de tu diseño,
    // pero conectada a nuestra arquitectura).

    // Leemos de la "Receta"
    final bool isTouristRegistered = ruta.estaInscrito;
    final bool isRouteFull = (ruta.cupos - ruta.inscritosCount) <= 0;
    // Leemos del "Mesero de Seguridad"
    final bool isUserLoggedIn = vmAuth.estaLogueado;

    String buttonText;
    Color buttonColor;
    VoidCallback? onPressed; // "null" deshabilita el botón

    if (isTouristRegistered) {
      // Flujo 1: Ya está registrado
      buttonText = 'SALIR DE LA RUTA';
      buttonColor = Colors.red;
      // Le damos la "orden" a nuestra función de manejo
      onPressed = () => _handleRegistration(context);
    } else if (isRouteFull) {
      // Flujo 2: Cupos Llenos
      buttonText = 'RUTA LLENA (SIN CUPOS)';
      buttonColor = Colors.grey;
      onPressed = null; // Botón deshabilitado
    } else if (!isUserLoggedIn) {
      // Flujo 3: Anónimo (Requiere Login)
      buttonText = 'INICIA SESIÓN PARA UNIRTE';
      buttonColor = Colors.orange;
      // Le damos la "orden" a nuestra función de manejo
      onPressed = () => _handleRegistration(context);
    } else {
      // Flujo 4: Disponible y Logueado
      buttonText = 'REGISTRARSE (S/ ${ruta.precio.toStringAsFixed(2)})';
      buttonColor = Colors.indigo;
      // Le damos la "orden" a nuestra función de manejo
      onPressed = () => _handleRegistration(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: ElevatedButton.icon(
        // "onPressed" es "null" si está deshabilitado
        onPressed: onPressed,
        icon: Icon(isTouristRegistered ? Icons.close : Icons.how_to_reg,
            color: Colors.white),
        label: Text(buttonText,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: buttonColor,
          disabledBackgroundColor: Colors.grey.shade400, // Color si está deshab.
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 5,
        ),
      ),
    );
  }

  // --- WIDGET AUXILIAR: MODAL DE INVITACIÓN ---
  // (Este es el "Bloqueo Suave" que te da una buena experiencia)
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