import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/tipo_cambio.dart';
import '../repositories/tipo_cambio_repository.dart';

@injectable
class RegistrarTipoCambioManualUseCase {
  final TipoCambioRepository _repository;
  RegistrarTipoCambioManualUseCase(this._repository);

  Future<Resource<TipoCambio>> call({
    required double compra,
    required double venta,
    required String fecha,
  }) {
    return _repository.registrarManual(
      compra: compra,
      venta: venta,
      fecha: fecha,
    );
  }
}
