import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/lote.dart';
import '../repositories/compra_repository.dart';

@injectable
class GetLotesProximosVencerUseCase {
  final CompraRepository _repository;

  GetLotesProximosVencerUseCase(this._repository);

  Future<Resource<List<Lote>>> call({
    required String empresaId,
    int dias = 30,
  }) async {
    return await _repository.getLotesProximosVencer(
      empresaId: empresaId,
      dias: dias,
    );
  }
}
