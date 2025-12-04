import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImagenServicio {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. SELECCIONAR IMAGEN
  Future<File?> seleccionarImagen() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery, // O ImageSource.camera
      imageQuality: 80, // Primera compresión ligera nativa
    );
    
    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  // 2. COMPRIMIR IMAGEN (El truco para ahorrar espacio)
  Future<File> comprimirImagen(File archivo) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    // Creamos un nombre temporal único
    final targetPath = '$path/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';

    var result = await FlutterImageCompress.compressAndGetFile(
      archivo.absolute.path,
      targetPath,
      quality: 60, // Baja la calidad al 60% (casi imperceptible en móviles)
      minWidth: 1080, // Redimensiona si es muy grande (ej. fotos de 4000px)
      minHeight: 1080,
    );

    return File(result!.path);
  }

  // 3. SUBIR A SUPABASE (S3)
  Future<String?> subirImagen(File archivo, String carpeta) async {
    try {
      // Generamos un nombre único para el archivo en la nube
      final fileExt = p.extension(archivo.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final rutaNube = '$carpeta/$fileName'; // Ej: "lugares/123456789.jpg"

      // Subimos el archivo
      await _supabase.storage.from('imagenes').upload(
        rutaNube,
        archivo,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // Obtenemos la URL Pública
      final urlPublica = _supabase.storage
          .from('imagenes')
          .getPublicUrl(rutaNube);

      return urlPublica;
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }
  
  // MÉTODO TODO EN UNO (Para facilitar el uso en la UI)
  Future<String?> seleccionarYSubir(String carpeta) async {
    // a. Seleccionar
    File? original = await seleccionarImagen();
    if (original == null) return null; // Usuario canceló

    // b. Comprimir
    File comprimida = await comprimirImagen(original);

    // c. Subir
    String? url = await subirImagen(comprimida, carpeta);
    
    return url;
  }
}