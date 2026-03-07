import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/compra_analytics.dart';
import '../repositories/compra_repository.dart';

class CompraAnalyticsData {
  final CompraResumenGeneral resumen;
  final List<GastoPeriodo> gastosPeriodo;
  final List<ProductoTop> topProductos;
  final List<ProveedorTop> topProveedores;
  final ComparativoCosto comparativo;
  final List<AlertaCompra> alertas;

  const CompraAnalyticsData({
    required this.resumen,
    required this.gastosPeriodo,
    required this.topProductos,
    required this.topProveedores,
    required this.comparativo,
    required this.alertas,
  });
}

@injectable
class GetCompraAnalyticsUseCase {
  final CompraRepository _repository;

  GetCompraAnalyticsUseCase(this._repository);

  Future<Resource<CompraAnalyticsData>> call({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
    String? periodo,
  }) async {
    try {
      final results = await Future.wait([
        _repository.getAnalyticsResumen(
          empresaId: empresaId,
          sedeId: sedeId,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
        ),
        _repository.getAnalyticsGastosPeriodo(
          empresaId: empresaId,
          sedeId: sedeId,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          periodo: periodo,
        ),
        _repository.getAnalyticsTopProductos(
          empresaId: empresaId,
          sedeId: sedeId,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
        ),
        _repository.getAnalyticsTopProveedores(
          empresaId: empresaId,
          sedeId: sedeId,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
        ),
        _repository.getAnalyticsComparativoCostos(
          empresaId: empresaId,
          sedeId: sedeId,
          periodo: periodo,
        ),
        _repository.getAnalyticsAlertas(
          empresaId: empresaId,
          sedeId: sedeId,
        ),
      ]);

      final resumen = results[0] as Resource<CompraResumenGeneral>;
      final gastos = results[1] as Resource<List<GastoPeriodo>>;
      final productos = results[2] as Resource<List<ProductoTop>>;
      final proveedores = results[3] as Resource<List<ProveedorTop>>;
      final comparativo = results[4] as Resource<ComparativoCosto>;
      final alertas = results[5] as Resource<List<AlertaCompra>>;

      if (resumen is Error<CompraResumenGeneral>) {
        return Error((resumen as Error).message);
      }

      return Success(CompraAnalyticsData(
        resumen: (resumen as Success<CompraResumenGeneral>).data,
        gastosPeriodo: gastos is Success<List<GastoPeriodo>>
            ? gastos.data
            : [],
        topProductos: productos is Success<List<ProductoTop>>
            ? productos.data
            : [],
        topProveedores: proveedores is Success<List<ProveedorTop>>
            ? proveedores.data
            : [],
        comparativo: comparativo is Success<ComparativoCosto>
            ? comparativo.data
            : ComparativoCosto(
                periodoActual: PeriodoInfo(
                    inicio: DateTime(2000), fin: DateTime(2000), total: 0, cantidad: 0),
                periodoAnterior: PeriodoInfo(
                    inicio: DateTime(2000), fin: DateTime(2000), total: 0, cantidad: 0),
                diferencia: 0,
                porcentajeCambio: 0,
              ),
        alertas: alertas is Success<List<AlertaCompra>>
            ? alertas.data
            : [],
      ));
    } catch (e) {
      return Error(e.toString());
    }
  }
}
