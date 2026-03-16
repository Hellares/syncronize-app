import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/venta.dart';
import '../repositories/venta_repository.dart';

@injectable
class GetVentasUseCase {
  final VentaRepository _repository;

  GetVentasUseCase(this._repository);

  Future<Resource<List<Venta>>> call({
    String? sedeId,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    String? clienteId,
    String? search,
  }) {
    return _repository.getVentas(
      sedeId: sedeId,
      estado: estado,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
      clienteId: clienteId,
      search: search,
    );
  }
}
