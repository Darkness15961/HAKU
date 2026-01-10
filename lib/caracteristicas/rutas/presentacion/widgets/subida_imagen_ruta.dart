import 'package:flutter/material.dart';
import '../../../../core/servicios/imagen_servicio.dart';

class SubidaImagenRuta extends StatefulWidget {
  final TextEditingController urlImagenCtrl;

  const SubidaImagenRuta({
    super.key,
    required this.urlImagenCtrl,
  });

  @override
  State<SubidaImagenRuta> createState() => _SubidaImagenRutaState();
}

class _SubidaImagenRutaState extends State<SubidaImagenRuta> {
  final ImagenServicio _imagenServicio = ImagenServicio();
  bool _subiendoImagen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Imagen de Portada',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _subiendoImagen
              ? null
              : () async {
                  setState(() => _subiendoImagen = true);
                  // Usamos 'rutas' como carpeta en el bucket
                  final url = await _imagenServicio.seleccionarYSubir('rutas');
                  if (url != null) {
                    setState(() => widget.urlImagenCtrl.text = url);
                  }
                  setState(() => _subiendoImagen = false);
                },
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
              image: widget.urlImagenCtrl.text.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.urlImagenCtrl.text),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _subiendoImagen
                ? const Center(child: CircularProgressIndicator())
                : widget.urlImagenCtrl.text.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toca para subir una foto',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      )
                    : null,
          ),
        ),
        if (widget.urlImagenCtrl.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'URL: ${widget.urlImagenCtrl.text}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() {
                      widget.urlImagenCtrl.clear();
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
