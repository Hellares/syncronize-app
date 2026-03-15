import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/orden_servicio.dart';
import '../entities/servicio_filtros.dart';
import '../repositories/orden_servicio_repository.dart';

@injectable
class GetOrdenesServicioUseCase {
  final OrdenServicioRepository _repository;

  GetOrdenesServicioUseCase(this._repository);

  Future<Resource<OrdenesServicioPaginadas>> call({
    required String empresaId,
    required OrdenServicioFiltros filtros,
    bool asCliente = false,
  }) async {
    if (asCliente) {
      return await _repository.getMisOrdenes(filtros: filtros);
    }
    return await _repository.getOrdenes(
      empresaId: empresaId,
      filtros: filtros,
    );
  }
}
