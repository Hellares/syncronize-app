import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/barcode_item.dart';
import '../repositories/barcode_repository.dart';

@injectable
class GenerarCodigosUseCase {
  final BarcodeRepository _repository;
  GenerarCodigosUseCase(this._repository);

  Future<Resource<GenerarCodigosResult>> call({
    required List<String> productoIds,
    String formato = 'INTERNO',
  }) {
    return _repository.generarCodigos(
      productoIds: productoIds,
      formato: formato,
    );
  }
}
