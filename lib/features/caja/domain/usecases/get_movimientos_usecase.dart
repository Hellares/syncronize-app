import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/movimiento_caja.dart';
import '../repositories/caja_repository.dart';

@injectable
class GetMovimientosUseCase {
  final CajaRepository _repository;

  GetMovimientosUseCase(this._repository);

  Future<Resource<List<MovimientoCaja>>> call({required String cajaId}) {
    return _repository.getMovimientos(cajaId: cajaId);
  }
}
