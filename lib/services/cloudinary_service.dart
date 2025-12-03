import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  String get cloudName =>
      dotenv.isInitialized ? (dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '') : '';
  String get uploadPreset => dotenv.isInitialized
      ? (dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '')
      : '';

  Future<String> subirImagenNoFirmada(
    File file, {
    String folder = 'students',
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folder;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al subir imagen a Cloudinary: ${response.statusCode} ${response.body}',
      );
    }
    final Map<String, dynamic> data = json.decode(response.body);
    return data['secure_url'] as String;
  }
}
