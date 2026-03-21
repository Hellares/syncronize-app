import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../network/dio_client.dart';

/// Servicio reutilizable para exportar archivos Excel desde la API.
///
/// Descarga bytes desde el endpoint, los guarda en un archivo temporal
/// y abre el diálogo nativo de compartir.
@lazySingleton
class ExportService {
  final DioClient _dioClient;

  ExportService(this._dioClient);

  /// Descarga un archivo Excel desde [endpoint] con [queryParams],
  /// lo guarda como [fileName] en el directorio temporal y abre el
  /// diálogo de compartir del sistema.
  ///
  /// Muestra SnackBars de progreso, éxito y error a través de [context].
  Future<void> exportAndShare({
    required BuildContext context,
    required String endpoint,
    required Map<String, dynamic> queryParams,
    required String fileName,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    // Mostrar SnackBar de progreso
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Exportando...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final response = await _dioClient.get(
        endpoint,
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.data as List<int>);

      // Ocultar SnackBar de progreso
      messenger.hideCurrentSnackBar();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: fileName,
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
