import '../../../../core/utils/resource.dart';
import '../entities/plan_suscripcion_detail.dart';

abstract class PlanSuscripcionRepository {
  /// Obtiene la lista de planes de suscripcion disponibles
  Future<Resource<List<PlanSuscripcionDetail>>> getPlanes();

  /// Cambia el plan de suscripcion de una empresa
  Future<Resource<void>> cambiarPlan({
    required String empresaId,
    required String planId,
    String periodo = 'MENSUAL',
  });
}
