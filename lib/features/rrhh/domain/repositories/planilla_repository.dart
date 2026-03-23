import '../../../../core/utils/resource.dart';
import '../entities/periodo_planilla.dart';
import '../entities/boleta_pago.dart';

abstract class PlanillaRepository {
  // Periodos
  Future<Resource<PeriodoPlanilla>> createPeriodo(Map<String, dynamic> data);

  Future<Resource<List<PeriodoPlanilla>>> getPeriodos({
    Map<String, dynamic>? queryParams,
  });

  Future<Resource<PeriodoPlanilla>> getPeriodo(String id);

  Future<Resource<PeriodoPlanilla>> calcularPlanilla(String periodoId);

  Future<Resource<PeriodoPlanilla>> aprobarPeriodo(String id);

  Future<Resource<Map<String, dynamic>>> pagarPlanilla(
      String periodoId, Map<String, dynamic> data);

  // Boletas
  Future<Resource<List<BoletaPago>>> getBoletas({
    Map<String, dynamic>? queryParams,
  });

  Future<Resource<BoletaPago>> getBoleta(String id);

  Future<Resource<BoletaPago>> pagarBoleta(
      String boletaId, Map<String, dynamic> data);
}
