import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/api_constants.dart';
import 'dio_client.dart';

class FileRepository {
  FileRepository._();
  static final FileRepository instance = FileRepository._();

  final _dio = DioClient.instance;

  /// Seçilen görseli backend'e yükler, herkese açık URL'sini döner.
  Future<String> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    return uploadBytes(
      bytes,
      filename: file.name.isNotEmpty ? file.name : 'photo.jpg',
      contentType: _mediaTypeFor(file),
    );
  }

  /// Ham baytları yükler (kırpma sonrası kullanılır).
  Future<String> uploadBytes(
    Uint8List bytes, {
    String filename = 'photo.png',
    MediaType? contentType,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: contentType ?? MediaType('image', 'png'),
      ),
    });
    final response = await _dio.post(
      ApiConstants.files,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return (response.data as Map)['url'] as String;
  }

  MediaType _mediaTypeFor(XFile file) {
    final mime = file.mimeType;
    if (mime != null && mime.contains('/')) {
      final parts = mime.split('/');
      return MediaType(parts[0], parts[1]);
    }
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return MediaType('image', 'png');
    if (name.endsWith('.webp')) return MediaType('image', 'webp');
    if (name.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('image', 'jpeg');
  }
}
