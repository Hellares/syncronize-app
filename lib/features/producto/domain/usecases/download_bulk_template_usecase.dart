import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/producto_repository.dart';

@injectable
class DownloadBulkTemplateUseCase {
  final ProductoRepository _repository;

  DownloadBulkTemplateUseCase(this._repository);

  Future<Resource<List<int>>> call() async {
    return await _repository.downloadBulkUploadTemplate();
  }
}
