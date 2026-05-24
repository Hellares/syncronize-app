import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/movimiento_caja.dart';
import '../repositories/caja_repository.dart';

@injectable
class CrearAjusteTesoreriaUseCase {
  final CajaRepository _repository;

  CrearAjusteTesoreriaUseCase(this._repository);

  Future<Resource<MovimientoCaja>> call({
    required String sedeId,
    required TipoMovimientoCaja tipo,
    required MetodoPago metodoPago,
    required double monto,
    required String descripcion,
    String? categoriaGastoId,
  }) {
    return _repository.crearAjusteTesoreria(
      sedeId: sedeId,
      tipo: tipo,
      metodoPago: metodoPago,
      monto: monto,
      descripcion: descripcion,
      categoriaGastoId: categoriaGastoId,
    );
  }
}
