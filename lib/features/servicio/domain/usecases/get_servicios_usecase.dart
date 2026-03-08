import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/servicio.dart';
import '../entities/servicio_filtros.dart';
import '../repositories/servicio_repository.dart';

@injectable
class GetServiciosUseCase {
  final ServicioRepository _repository;

  GetServiciosUseCase(this._repository);

  Future<Resource<ServiciosPaginados>> call({
    required String empresaId,
    required ServicioFiltros filtros,
  }) async {
    return await _repository.getServicios(
      empresaId: empresaId,
      filtros: filtros,
    );
  }
}
