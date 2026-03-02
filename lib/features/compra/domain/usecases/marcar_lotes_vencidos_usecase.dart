import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/compra_repository.dart';

@injectable
class MarcarLotesVencidosUseCase {
  final CompraRepository _repository;

  MarcarLotesVencidosUseCase(this._repository);

  Future<Resource<Map<String, dynamic>>> call({
    required String empresaId,
  }) async {
    return await _repository.marcarLotesVencidos(
      empresaId: empresaId,
    );
  }
}
