import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/devolucion_venta.dart';
import '../repositories/devolucion_venta_repository.dart';

@injectable
class GetDevolucionesUseCase {
  final DevolucionVentaRepository _repository;
  GetDevolucionesUseCase(this._repository);

  Future<Resource<List<DevolucionVenta>>> call({
    String? sedeId, String? estado, String? ventaId, String? search,
  }) {
    return _repository.getAll(sedeId: sedeId, estado: estado, ventaId: ventaId, search: search);
  }
}
