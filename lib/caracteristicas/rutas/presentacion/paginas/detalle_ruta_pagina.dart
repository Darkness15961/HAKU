// --- PIEDRA 9 (RUTAS): EL "MENÚ" DE DETALLE DE RUTA (REGLA DE GUÍA ACOMPLADA) ---
//
// 1. (REGLA DE NEGOCIO ACOMPLADA): El botón inferior ahora comprueba si
//    el usuario actual es el 'guiaId' de la ruta.
// 2. (UX CORREGIDA): Si es el propietario, muestra "Gestionar Ruta".
// 3. (LÓGICA): Mantiene la lógica del "Cerebro" (AuthVM) para todo lo demás.

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
  void _handleRegistration(BuildContext context) {
    if (!_checkAndRedirect(context, 'inscribirte en esta ruta')) {
      return;
    }
    final vmAuth = context.read<AutenticacionVM>();
    final estaInscrito = vmAuth.rutasInscritasIds.contains(ruta.id);

    if (estaInscrito) {
      context.read<RutasVM>().salirDeRuta(ruta.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has cancelado tu registro (Simulado)')),
      );
    } else {
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
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    // --- ¡LECTURA DE ESTADO DESDE EL CEREBRO! ---
    final bool esFavorita = vmAuth.rutasFavoritasIds.contains(ruta.id);
    final bool estaInscrito = vmAuth.rutasInscritasIds.contains(ruta.id);

    // --- ¡REGLA DE NEGOCIO ACOMPLADA! ---
    final String? usuarioIdActual = vmAuth.usuarioActual?.id;
    // Es propietario si el ID del usuario logueado es el mismo que el ID del guía de la ruta
    final bool esPropietario = (vmAuth.estaLogueado && usuarioIdActual == ruta.guiaId);
    // --- FIN DE REGLA ---

    // --- ¡LÓGICA ACOMPLADA! ---
    int inscritosCount = ruta.inscritosCount;
    if (estaInscrito && !ruta.estaInscrito) {
      inscritosCount++;
    } else if (!estaInscrito && ruta.estaInscrito) {
      inscritosCount--;
    }
    final int cuposDisponibles = ruta.cuposTotales - inscritosCount;
    // --- FIN DE LÓGICA ---

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
                    if (_checkAndRedirect(context, 'guardar esta ruta')) {
                      context.read<RutasVM>().toggleFavoritoRuta(ruta.id);
                    }
                  },
                  icon: Icon(
                    esFavorita ? Icons.favorite : Icons.favorite_border,
                    color: esFavorita ? Colors.red : Colors.white,
                  )),
              IconButton(
                  onPressed: () { /* Lógica de Compartir */ },
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
                  _buildRouteMetrics(ruta, cuposDisponibles: cuposDisponibles),
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
                _buildInfoCard(context, ruta, cuposDisponibles: cuposDisponibles),
                _buildGuideProfile(context, ruta),
                _buildSectionTitle('Detalles de la Experiencia'),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(ruta.descripcion,
                      style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ),
                _buildSectionTitle('Itinerario y Lugares Incluidos'),
                _buildRouteStopsList(ruta.lugaresIncluidosIds), // <-- Usamos IDs

                const SizedBox(height: 120), // Espacio para el botón inferior
              ],
            ),
          ),
        ],
      ),
      // --- 3. Botón Inferior (¡ACOMPLADO CON REGLA!) ---
      bottomNavigationBar:
      _buildRegisterButton(context, vmAuth, ruta,
          estaInscrito: estaInscrito,
          cuposDisponibles: cuposDisponibles,
          esPropietario: esPropietario // <-- ¡Regla Acoplada!
      ),
    );
  }

  // --- WIDGETS AUXILIARES (ACOMPLADOS Y MEJORADOS) ---

  Widget _buildRouteMetrics(Ruta ruta, {required int cuposDisponibles}) {
    Color difficultyColor = ruta.dificultad == 'facil'
        ? Colors.green
        : ruta.dificultad == 'dificil'
        ? Colors.red
        : Colors.orange;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Chip(
          label: Text('$cuposDisponibles / ${ruta.cuposTotales} Cupos',
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

  Widget _buildInfoCard(BuildContext context, Ruta ruta, {required int cuposDisponibles}) {
    final bool isRouteFull = cuposDisponibles <= 0;

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
            // Días
            Column(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 30),
                const SizedBox(height: 4),
                Text('${ruta.dias} Día(s)',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent)),
                const Text('Duración',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            // Cupos
            Column(
              children: [
                Icon(Icons.group,
                    color: isRouteFull ? Colors.red : Colors.indigo, size: 30),
                const SizedBox(height: 4),
                Text('$cuposDisponibles',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isRouteFull ? Colors.red : Colors.indigo)),
                const Text('Cupos Disp.',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

    // ¡ACOMPLADO! Leemos los Nombres (lugaresIncluidos)
    // (La lógica de IDs es solo para el mapa, la UI muestra los nombres)
    final lugaresNombres = lugaresIncluidos;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: List.generate(lugaresNombres.length, (index) {
          final lugarNombre = lugaresNombres[index];
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
                    if (index < lugaresNombres.length - 1)
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

  // --- ¡WIDGET DEL BOTÓN INFERIOR ACOMPLADO CON REGLA! ---
  Widget _buildRegisterButton(
      BuildContext context,
      AutenticacionVM vmAuth,
      Ruta ruta, {
        required bool estaInscrito,
        required int cuposDisponibles,
        required bool esPropietario, // <-- ¡Regla Acoplada!
      }) {

    final bool isRouteFull = cuposDisponibles <= 0;
    final bool isUserLoggedIn = vmAuth.estaLogueado;

    String buttonText;
    Color buttonColor;
    VoidCallback? onPressed;
    IconData buttonIcon; // <-- ¡Icono dinámico!

    // --- ¡REGLA DE NEGOCIO IMPLEMENTADA! ---
    if (esPropietario) {
      // Flujo 1: Es el Guía Propietario
      buttonText = 'GESTIONAR MI RUTA';
      buttonColor = Colors.blueGrey; // Un color de "gestión"
      buttonIcon = Icons.edit_note;
      onPressed = () {
        // TODO: Navegar a /editar-ruta (futuro)
        context.push('/crear-ruta', extra: ruta); // Reutilizamos la página de crear
      };
    } else if (estaInscrito) {
      // Flujo 2: Ya está registrado
      buttonText = 'SALIR DE LA RUTA';
      buttonColor = Colors.red;
      buttonIcon = Icons.close;
      onPressed = () => _handleRegistration(context);
    } else if (isRouteFull) {
      // Flujo 3: Cupos Llenos
      buttonText = 'RUTA LLENA (SIN CUPOS)';
      buttonColor = Colors.grey;
      buttonIcon = Icons.group_off;
      onPressed = null;
    } else if (!isUserLoggedIn) {
      // Flujo 4: Anónimo (Requiere Login)
      buttonText = 'INICIA SESIÓN PARA UNIRTE';
      buttonColor = Colors.orange.shade700;
      buttonIcon = Icons.login;
      onPressed = () => _handleRegistration(context);
    } else {
      // Flujo 5: Disponible y Logueado
      buttonText = 'REGISTRARSE (S/ ${ruta.precio.toStringAsFixed(2)})';
      buttonColor = Theme.of(context).colorScheme.primary; // Color principal
      buttonIcon = Icons.how_to_reg;
      onPressed = () => _handleRegistration(context);
    }
    // --- FIN DE LA REGLA DE NEGOCIO ---

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
        icon: Icon(buttonIcon, // <-- Icono dinámico
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