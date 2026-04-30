import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/reversion_total.dart';
import '../repositories/venta_repository.dart';

@injectable
class CrearReversionTotalUseCase {
  final VentaRepository _repository;
  CrearReversionTotalUseCase(this._repository);

  Future<Resource<ReversionTotal>> call({
    required String ventaId,
    String? motivo,
  }) {
    return _repository.crearReversionTotal(ventaId: ventaId, motivo: motivo);
  }
}

@injectable
class ObtenerReversionTotalUseCase {
  final VentaRepository _repository;
  ObtenerReversionTotalUseCase(this._repository);

  Future<Resource<ReversionTotal?>> call({required String ventaId}) {
    return _repository.obtenerReversionTotal(ventaId: ventaId);
  }
}
