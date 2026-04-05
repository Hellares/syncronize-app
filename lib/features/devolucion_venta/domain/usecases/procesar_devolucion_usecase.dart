import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/devolucion_venta.dart';
import '../repositories/devolucion_venta_repository.dart';

@injectable
class ProcesarDevolucionUseCase {
  final DevolucionVentaRepository _repository;
  ProcesarDevolucionUseCase(this._repository);

  Future<Resource<DevolucionVenta>> call({required String id}) {
    return _repository.procesar(id: id);
  }
}
