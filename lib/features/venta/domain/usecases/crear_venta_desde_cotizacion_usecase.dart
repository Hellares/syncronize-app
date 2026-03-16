import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/venta.dart';
import '../repositories/venta_repository.dart';

@injectable
class CrearVentaDesdeCotizacionUseCase {
  final VentaRepository _repository;

  CrearVentaDesdeCotizacionUseCase(this._repository);

  Future<Resource<Venta>> call({
    required String cotizacionId,
    required Map<String, dynamic> data,
  }) {
    return _repository.crearVentaDesdeCotizacion(
      cotizacionId: cotizacionId,
      data: data,
    );
  }
}
