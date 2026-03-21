import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/venta.dart';
import '../repositories/venta_repository.dart';

@lazySingleton
class CrearYCobrarVentaUseCase {
  final VentaRepository _repository;

  CrearYCobrarVentaUseCase(this._repository);

  Future<Resource<Venta>> call({required Map<String, dynamic> data}) {
    return _repository.crearYCobrar(data: data);
  }
}
