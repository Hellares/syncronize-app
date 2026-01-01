import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:http_parser/http_parser.dart';
import '../network/dio_client.dart';

/// Modelo de respuesta de archivo subido
class ArchivoResponse {
  final String id;
  final String url;
  final String? urlThumbnail;
  final String nombreOriginal;
  final String mimeType;
  final int tamanoBytes;

  ArchivoResponse({
    required this.id,
    required this.url,
    this.urlThumbnail,
    required this.nombreOriginal,
    required this.mimeType,
    required this.tamanoBytes,
  });

  factory ArchivoResponse.fromJson(Map<String, dynamic> json) {
    return ArchivoResponse(
      id: json['id'] as String,
      url: json['url'] as String,
      urlThumbnail: json['urlThumbnail'] as String?,
      nombreOriginal: json['nombreOriginal'] as String,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      tamanoBytes: json['tamanoBytes'] as int,
    );
  }
}

/// Servicio para gestionar archivos/imágenes en el backend
@lazySingleton
class StorageService {
  final DioClient _dioClient;

  StorageService(this._dioClient);

  /// Sube un archivo al backend
  ///
  /// [file] - Archivo a subir
  /// [empresaId] - ID de la empresa
  /// [entidadTipo] - Tipo de entidad (opcional): PRODUCTO, CATEGORIA, etc.
  /// [entidadId] - ID de la entidad (opcional)
  /// [categoria] - Categoría del archivo (opcional)
  /// [orden] - Orden del archivo (opcional)
  /// [onProgress] - Callback para progreso de subida (0.0 a 1.0)
  Future<ArchivoResponse> uploadFile({
    required File file,
    required String empresaId,
    String? entidadTipo,
    String? entidadId,
    String? categoria,
    int? orden,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();

      // Determinar MIME type
      String mimeType = 'application/octet-stream';
      if (['jpg', 'jpeg'].contains(extension)) {
        mimeType = 'image/jpeg';
      } else if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
        'empresaId': empresaId,
        if (entidadTipo != null) 'entidadTipo': entidadTipo,
        if (entidadId != null) 'entidadId': entidadId,
        if (categoria != null) 'categoria': categoria,
        if (orden != null) 'orden': orden,
      });

      final response = await _dioClient.post(
        '/storage/upload',
        data: formData,
        onSendProgress: onProgress != null
            ? (sent, total) {
                if (total > 0) {
                  onProgress(sent / total);
                }
              }
            : null,
      );

      return ArchivoResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Error al subir archivo: $e');
    }
  }

  /// Elimina un archivo del backend
  Future<void> deleteFile({
    required String archivoId,
    required String empresaId,
  }) async {
    try {
      await _dioClient.delete(
        '/storage/$archivoId',
        queryParameters: {'empresaId': empresaId},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Error al eliminar archivo: $e');
    }
  }

  /// Obtiene archivos de una entidad
  Future<List<ArchivoResponse>> getFilesByEntity({
    required String entidadTipo,
    required String entidadId,
    required String empresaId,
  }) async {
    try {
      final response = await _dioClient.get(
        '/storage/entidad/$entidadTipo/$entidadId',
        queryParameters: {'empresaId': empresaId},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => ArchivoResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Error al obtener archivos: $e');
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      String message = 'Error del servidor';
      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ??
            data['error'] as String? ??
            message;
      }

      switch (statusCode) {
        case 400:
          return Exception('Archivo inválido: $message');
        case 401:
          return Exception('No autorizado: $message');
        case 403:
          return Exception('Sin permisos para subir archivos');
        case 413:
          return Exception('Archivo demasiado grande');
        case 415:
          return Exception('Tipo de archivo no soportado');
        default:
          return Exception('Error HTTP $statusCode: $message');
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception('Tiempo de espera agotado al subir archivo');
    }

    return Exception('Error de red: ${error.message}');
  }
}
