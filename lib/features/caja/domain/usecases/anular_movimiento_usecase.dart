import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/caja_repository.dart';

@injectable
class AnularMovimientoUseCase {
  final CajaRepository _repository;

  AnularMovimientoUseCase(this._repository);

  Future<Resource<void>> call({
    required String cajaId,
    required String movimientoId,
    required String autorizadoPorId,
    required String motivo,
  }) {
    return _repository.anularMovimiento(
      cajaId: cajaId,
      movimientoId: movimientoId,
      autorizadoPorId: autorizadoPorId,
      motivo: motivo,
    );
  }
}
