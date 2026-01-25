import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/transferencia_stock.dart';
import '../repositories/transferencia_stock_repository.dart';

@injectable
class ProcesarCompletoTransferenciaUseCase {
  final TransferenciaStockRepository _repository;

  ProcesarCompletoTransferenciaUseCase(this._repository);

  Future<Resource<TransferenciaStock>> call({
    required String transferenciaId,
    required String empresaId,
    String? ubicacion,
    String? observaciones,
  }) async {
    return await _repository.procesarCompletoTransferencia(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
      ubicacion: ubicacion,
      observaciones: observaciones,
    );
  }
}
