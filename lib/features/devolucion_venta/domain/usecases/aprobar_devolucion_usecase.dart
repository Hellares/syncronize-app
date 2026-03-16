import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/devolucion_venta.dart';
import '../repositories/devolucion_venta_repository.dart';

@injectable
class AprobarDevolucionUseCase {
  final DevolucionVentaRepository _repository;
  AprobarDevolucionUseCase(this._repository);

  Future<Resource<DevolucionVenta>> call({required String id}) {
    return _repository.aprobar(id: id);
  }
}
