import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/transferencia_stock.dart';
import '../repositories/transferencia_stock_repository.dart';

@injectable
class ListarTransferenciasUseCase {
  final TransferenciaStockRepository _repository;

  ListarTransferenciasUseCase(this._repository);

  Future<Resource<Map<String, dynamic>>> call({
    required String empresaId,
    String? sedeId,
    EstadoTransferencia? estado,
    int page = 1,
    int limit = 50,
  }) async {
    return await _repository.listarTransferencias(
      empresaId: empresaId,
      sedeId: sedeId,
      estado: estado,
      page: page,
      limit: limit,
    );
  }
}
