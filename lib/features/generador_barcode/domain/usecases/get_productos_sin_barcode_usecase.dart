import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/barcode_item.dart';
import '../repositories/barcode_repository.dart';

@injectable
class GetProductosSinBarcodeUseCase {
  final BarcodeRepository _repository;
  GetProductosSinBarcodeUseCase(this._repository);

  Future<Resource<List<BarcodeItem>>> call({String? sedeId}) {
    return _repository.getProductosSinBarcode(sedeId: sedeId);
  }
}
