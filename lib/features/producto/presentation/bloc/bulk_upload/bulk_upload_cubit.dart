import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

    final result = await _downloadTemplateUseCase();

    if (result is Success<List<int>>) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/plantilla_productos.xlsx');
        await file.writeAsBytes(result.data);

        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          subject: 'Plantilla de productos',
          text: 'Plantilla Excel para carga masiva de productos',
        );

        emit(BulkUploadTemplateDownloaded(file.path));
      } catch (e) {
        emit(BulkUploadError('Error al compartir la plantilla: $e'));
      }
    } else if (result is Error<List<int>>) {
      emit(BulkUploadError(result.message, errorCode: result.errorCode));
    }
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
