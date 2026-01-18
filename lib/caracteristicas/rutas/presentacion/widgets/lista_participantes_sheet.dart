import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dominio/entidades/ruta.dart';
import '../../dominio/entidades/participante_ruta.dart';
import '../vista_modelos/rutas_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart'; // <--- CORREGIDO (3 niveles)

class ListaParticipantesSheet extends StatefulWidget {
  final Ruta ruta;

  const ListaParticipantesSheet({
    super.key,
    required this.ruta,
  });

  @override
  State<ListaParticipantesSheet> createState() => _ListaParticipantesSheetState();
}

class _ListaParticipantesSheetState extends State<ListaParticipantesSheet> {
  @override
  void initState() {
    super.initState();
    // Cargar participantes al abrir el sheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RutasVM>().cargarParticipantes(widget.ruta.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rutasVM = context.watch<RutasVM>();
    final authVM = context.read<AutenticacionVM>();
    
    // Identificar si soy el guía
    final bool soyElGuia = widget.ruta.guiaId == authVM.usuarioActual?.id;

    return Container(
      height: MediaQuery.of(context).size.height * 0.60,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // --- HEADER HACIA ABAJO ---
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Participantes (${rutasVM.participantes.length}/${widget.ruta.cuposTotales})",
                  style: const TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87
                  ),
                ),
                if (rutasVM.cargandoParticipantes)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 30),

          // --- LISTA ---
          Expanded(
            child: rutasVM.participantes.isEmpty && !rutasVM.cargandoParticipantes
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: rutasVM.participantes.length,
                  itemBuilder: (context, index) {
                    final participante = rutasVM.participantes[index];
                    return _buildParticipanteTile(
                      context, 
                      participante, 
                      soyElGuia, 
                      rutasVM
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipanteTile(BuildContext context, ParticipanteRuta p, bool soyElGuia, RutasVM vm) {
    // Si soy yo, muestro switch (Lógica: TURISTA (YO))
    // Si soy guía, veo todo (Lógica: GUÍA)
    
    String titulo = p.tituloAMostrar;
    String subtitulo = p.subtituloAMostrar;

    // Lógica para el GUÍA: Siempre ve la verdad
    if (soyElGuia) {
      titulo = p.nombreCompleto;
      subtitulo = "DNI: ${p.dni}"; // OJO: El guía ve esto siempre como base
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: p.soyYo ? Colors.deepPurple.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: p.soyYo ? Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)) : null,
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey[200],
          backgroundImage: p.urlFotoPerfil.isNotEmpty ? NetworkImage(p.urlFotoPerfil) : null,
          child: p.urlFotoPerfil.isEmpty 
              ? Text(titulo.isNotEmpty ? titulo[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)) 
              : null,
        ),
        title: Text(
          titulo, 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: p.soyYo ? Colors.deepPurple : Colors.black87,
          )
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitulo, style: const TextStyle(fontSize: 12)),
            // Si soy guía, muestro DNI si está disponible
            if (soyElGuia && p.dni.isNotEmpty)
               Text("DNI: ${p.dni}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: p.soyYo 
          ? Transform.scale(
              scale: 0.8,
              child: Switch(
                value: p.mostrarNombreReal, 
                onChanged: (val) {
                  vm.togglePrivacidad(widget.ruta.id, val);
                },
                activeColor: Colors.deepPurple,
              ),
            )
          : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text("Aún no hay participantes inscritos.", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
