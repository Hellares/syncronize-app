import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/bulk_upload_result.dart';
import '../../../domain/usecases/download_bulk_template_usecase.dart';
import '../../../domain/usecases/bulk_upload_productos_usecase.dart';
import 'bulk_upload_state.dart';

@injectable
class BulkUploadCubit extends Cubit<BulkUploadState> {
  final DownloadBulkTemplateUseCase _downloadTemplateUseCase;
  final BulkUploadProductosUseCase _bulkUploadUseCase;

  BulkUploadCubit(
    this._downloadTemplateUseCase,
    this._bulkUploadUseCase,
  ) : super(const BulkUploadInitial());

  Future<void> downloadTemplate() async {
    emit(const BulkUploadDownloadingTemplate());

    // Solicitar permiso de almacenamiento en Android antes de descargar
    if (Platform.isAndroid) {
      final granted = await _requestStoragePermission();
      if (!granted) {
        emit(const BulkUploadError(
          'Se necesita permiso de almacenamiento para guardar la plantilla. '
          'Por favor, habilítalo en la configuración de la app.',
        ));
        return;
      }
    }

    final result = await _downloadTemplateUseCase();

    if (result is Success<List<int>>) {
      try {
        final filePath = await _getDownloadPath('plantilla_productos.xlsx');
        final file = File(filePath);
        await file.writeAsBytes(result.data);
        emit(BulkUploadTemplateDownloaded(filePath));
      } catch (e) {
        emit(BulkUploadError('Error al guardar la plantilla: $e'));
      }
    } else if (result is Error<List<int>>) {
      emit(BulkUploadError(result.message, errorCode: result.errorCode));
    }
  }

  /// Solicita permiso de almacenamiento en Android
  Future<bool> _requestStoragePermission() async {
    // En Android 13+ (API 33) no se necesita permiso de storage para escribir
    // en carpetas públicas. Intentamos con storage primero.
    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    // En Android 11+ puede necesitar MANAGE_EXTERNAL_STORAGE
    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) return true;

    // Si ambos fueron denegados permanentemente, el usuario debe ir a settings
    return false;
  }

  /// Obtiene la ruta de descarga accesible para el usuario
  Future<String> _getDownloadPath(String fileName) async {
    if (Platform.isAndroid) {
      // Carpeta de Descargas pública en Android
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        return '${downloadDir.path}/$fileName';
      }
      // Fallback: directorio externo de la app
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        return '${extDir.path}/$fileName';
      }
    }
    // iOS u otro: directorio de documentos de la app
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileName';
  }

  Future<void> uploadExcel({
    required String filePath,
    required String fileName,
    List<String>? sedesIds,
  }) async {
    emit(const BulkUploadUploading());

    final result = await _bulkUploadUseCase(
      filePath: filePath,
      fileName: fileName,
      sedesIds: sedesIds,
    );

    if (result is Success<BulkUploadResult>) {
      emit(BulkUploadSuccess(result.data));
    } else if (result is Error<BulkUploadResult>) {
      emit(BulkUploadError(result.message, errorCode: result.errorCode));
    }
  }

  void reset() {
    emit(const BulkUploadInitial());
  }
}
