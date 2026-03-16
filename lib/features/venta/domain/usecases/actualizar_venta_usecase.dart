import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/venta.dart';
import '../repositories/venta_repository.dart';

@injectable
class ActualizarVentaUseCase {
  final VentaRepository _repository;

  ActualizarVentaUseCase(this._repository);

  Future<Resource<Venta>> call({
    required String ventaId,
    required Map<String, dynamic> data,
  }) {
    return _repository.actualizarVenta(ventaId: ventaId, data: data);
  }
}
