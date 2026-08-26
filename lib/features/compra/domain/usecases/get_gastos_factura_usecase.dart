import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/compra_analytics.dart';
import '../repositories/compra_repository.dart';

/// Reporte de los GASTOS DE LA FACTURA con filtros propios.
///
/// Va aparte de `GetCompraAnalyticsUseCase` —que trae el dashboard entero de
/// una— porque la pantalla dedicada cambia de filtros seguido y no tiene por
/// qué volver a pedir los top de productos, las alertas y el comparativo cada
/// vez que se mueve el rango de fechas.
@injectable
class GetGastosFacturaUseCase {
  final CompraRepository _repository;

  GetGastosFacturaUseCase(this._repository);

  Future<Resource<GastosFacturaReporte>> call({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
    String? proveedorId,
    String? categoriaGastoId,
    String? periodo,
  }) {
    return _repository.getAnalyticsGastosFactura(
      empresaId: empresaId,
      sedeId: sedeId,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      proveedorId: proveedorId,
      categoriaGastoId: categoriaGastoId,
      periodo: periodo,
    );
  }
}
