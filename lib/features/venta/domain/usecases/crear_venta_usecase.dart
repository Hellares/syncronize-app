import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/venta.dart';
import '../repositories/venta_repository.dart';

@lazySingleton
class CrearVentaUseCase {
  final VentaRepository _repository;

  CrearVentaUseCase(this._repository);

  Future<Resource<Venta>> call({required Map<String, dynamic> data}) {
    return _repository.crearVenta(data: data);
  }
}
