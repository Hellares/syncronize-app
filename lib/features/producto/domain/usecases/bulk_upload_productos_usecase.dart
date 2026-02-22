import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/bulk_upload_result.dart';
import '../repositories/producto_repository.dart';

@injectable
class BulkUploadProductosUseCase {
  final ProductoRepository _repository;

  BulkUploadProductosUseCase(this._repository);

  Future<Resource<BulkUploadResult>> call({
    required String filePath,
    required String fileName,
    List<String>? sedesIds,
  }) async {
    return await _repository.bulkUploadProductos(
      filePath: filePath,
      fileName: fileName,
      sedesIds: sedesIds,
    );
  }
}
