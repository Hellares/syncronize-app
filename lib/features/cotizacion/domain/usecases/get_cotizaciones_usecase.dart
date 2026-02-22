import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cotizacion.dart';
import '../repositories/cotizacion_repository.dart';

@injectable
class GetCotizacionesUseCase {
  final CotizacionRepository _repository;

  GetCotizacionesUseCase(this._repository);

  Future<Resource<List<Cotizacion>>> call({
    String? sedeId,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    String? clienteId,
    String? search,
  }) {
    return _repository.getCotizaciones(
      sedeId: sedeId,
      estado: estado,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
      clienteId: clienteId,
      search: search,
    );
  }
}
