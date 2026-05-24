import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/tesoreria.dart';
import '../repositories/caja_repository.dart';

@injectable
class GetTesoreriaMovimientosUseCase {
  final CajaRepository _repository;

  GetTesoreriaMovimientosUseCase(this._repository);

  Future<Resource<TesoreriaMovimientosPage>> call({
    required String sedeId,
    required TesoreriaMovimientosFilter filter,
  }) {
    return _repository.getTesoreriaMovimientos(sedeId: sedeId, filter: filter);
  }
}
