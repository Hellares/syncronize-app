import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/devolucion_venta.dart';
import '../repositories/devolucion_venta_repository.dart';

@injectable
class GetDevolucionUseCase {
  final DevolucionVentaRepository _repository;
  GetDevolucionUseCase(this._repository);

  Future<Resource<DevolucionVenta>> call({required String id}) {
    return _repository.getOne(id: id);
  }
}
