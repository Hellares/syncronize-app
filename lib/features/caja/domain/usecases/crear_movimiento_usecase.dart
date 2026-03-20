import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/movimiento_caja.dart';
import '../repositories/caja_repository.dart';

@injectable
class CrearMovimientoUseCase {
  final CajaRepository _repository;

  CrearMovimientoUseCase(this._repository);

  Future<Resource<void>> call({
    required String cajaId,
    required TipoMovimientoCaja tipo,
    required CategoriaMovimientoCaja categoria,
    required MetodoPago metodoPago,
    required double monto,
    String? descripcion,
  }) {
    return _repository.crearMovimiento(
      cajaId: cajaId,
      tipo: tipo,
      categoria: categoria,
      metodoPago: metodoPago,
      monto: monto,
      descripcion: descripcion,
    );
  }
}
