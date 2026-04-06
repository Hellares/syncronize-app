import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/guia_remision.dart';
import '../repositories/guia_remision_repository.dart';

@lazySingleton
class ListarGuiasRemisionUseCase {
  final GuiaRemisionRepository _repository;
  ListarGuiasRemisionUseCase(this._repository);

  Future<Resource<({List<GuiaRemision> data, int total, int totalPages})>> call({
    String? tipo,
    String? estado,
    String? sunatStatus,
    String? motivoTraslado,
    String? fechaDesde,
    String? fechaHasta,
    String? busqueda,
    int page = 1,
    int limit = 20,
  }) {
    return _repository.listar(
      tipo: tipo,
      estado: estado,
      sunatStatus: sunatStatus,
      motivoTraslado: motivoTraslado,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
      busqueda: busqueda,
      page: page,
      limit: limit,
    );
  }
}
