import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/transferencia_stock.dart';
import '../repositories/transferencia_stock_repository.dart';

@injectable
class CrearTransferenciaUseCase {
  final TransferenciaStockRepository _repository;

  CrearTransferenciaUseCase(this._repository);

  Future<Resource<TransferenciaStock>> call({
    required String empresaId,
    required String sedeOrigenId,
    required String sedeDestinoId,
    String? productoId,
    String? varianteId,
    required int cantidad,
    String? motivo,
    String? observaciones,
  }) async {
    return await _repository.crearTransferencia(
      empresaId: empresaId,
      sedeOrigenId: sedeOrigenId,
      sedeDestinoId: sedeDestinoId,
      productoId: productoId,
      varianteId: varianteId,
      cantidad: cantidad,
      motivo: motivo,
      observaciones: observaciones,
    );
  }
}
