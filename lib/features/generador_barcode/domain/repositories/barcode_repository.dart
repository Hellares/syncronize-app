import '../../../../core/utils/resource.dart';
import '../entities/barcode_item.dart';

abstract class BarcodeRepository {
  Future<Resource<List<BarcodeItem>>> getProductosSinBarcode({String? sedeId});
  Future<Resource<GenerarCodigosResult>> generarCodigos({
    required List<String> productoIds,
    String formato = 'INTERNO',
  });
}
