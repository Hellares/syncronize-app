import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/venta.dart';
import '../entities/ventas_page.dart';
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

  /// Página por cursor (scroll infinito) + resumen agregado. Método del
  /// mismo usecase para no tocar el registro de DI.
  Future<Resource<VentasPage>> paginado({
    String? sedeId,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    String? search,
    String? canalVenta,
    required int limit,
    String? cursor,
  }) {
    return _repository.getVentasPaginadas(
      sedeId: sedeId,
      estado: estado,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
      search: search,
      canalVenta: canalVenta,
      limit: limit,
      cursor: cursor,
    );
  }
}
