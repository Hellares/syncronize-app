import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/devolucion_venta.dart';
import '../repositories/devolucion_venta_repository.dart';

@injectable
class CrearDevolucionUseCase {
  final DevolucionVentaRepository _repository;
  CrearDevolucionUseCase(this._repository);

  Future<Resource<DevolucionVenta>> call({required Map<String, dynamic> data}) {
    return _repository.crear(data: data);
  }
}
