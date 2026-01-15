import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class ImagenServicio {
  final ImagePicker _picker = ImagePicker();

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
    final targetPath =
        '$path/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';

    var result = await FlutterImageCompress.compressAndGetFile(
      archivo.absolute.path,
      targetPath,
      quality: 60, // Baja la calidad al 60% (casi imperceptible en móviles)
      minWidth: 1080, // Redimensiona si es muy grande (ej. fotos de 4000px)
      minHeight: 1080,
    );

    return File(result!.path);
  }

  // 3. SUBIR A S3 VÍA N8N (UPLOAD PROXY)
  Future<String?> subirImagen(File archivo, String carpeta) async {
    try {
      final fileExt = p.extension(archivo.path).replaceAll('.', ''); // ej: jpg
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // 1. Preparar la petición Multipart
      final n8nUrl = Uri.parse(
        'https://n8n.premiospapicho.com/webhook/get-upload-url',
      );

      var request = http.MultipartRequest('POST', n8nUrl);

      // Adjuntar campos de texto
      request.fields['filename'] = fileName;
      request.fields['folder'] = carpeta;

      // Adjuntar el archivo real
      var pic = await http.MultipartFile.fromPath(
        'file', // Nombre del campo binario que espera n8n
        archivo.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(pic);

      // Enviar
      print('Enviando imagen a n8n...');
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('Status n8n: ${response.statusCode}');
      print('Body n8n: $responseBody');

      if (response.statusCode != 200) {
        print('Error n8n (${response.statusCode}): $responseBody');
        return null;
      }

      // Decodificar respuesta
      final data = jsonDecode(responseBody);
      final mapData = data is List ? data.first : data;

      // Ahora esperamos la URL pública directamente
      // Soportamos tanto 'publicUrl' (nuestra respuesta custom) como 'Location' (respuesta raw de S3)
      final publicUrl = mapData['publicUrl'] ?? mapData['Location'];

      print('✅ Imagen subida via n8n: $publicUrl');
      return publicUrl?.toString();
    } catch (e) {
      print('Excepción al subir imagen: $e');
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
