import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/transferencia_stock_repository.dart';

@injectable
class CrearTransferenciasMultiplesUseCase {
  final TransferenciaStockRepository _repository;

  CrearTransferenciasMultiplesUseCase(this._repository);

  Future<Resource<Map<String, dynamic>>> call({
    required String empresaId,
    required String sedeOrigenId,
    required String sedeDestinoId,
    required List<Map<String, dynamic>> productos,
    String? motivoGeneral,
    String? observaciones,
  }) async {
    return await _repository.crearTransferenciasMultiples(
      empresaId: empresaId,
      sedeOrigenId: sedeOrigenId,
      sedeDestinoId: sedeDestinoId,
      productos: productos,
      motivoGeneral: motivoGeneral,
      observaciones: observaciones,
    );
  }
}
