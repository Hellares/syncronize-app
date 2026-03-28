import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/plan_suscripcion_detail_model.dart';

@lazySingleton
class PlanSuscripcionRemoteDataSource {
  final DioClient _dioClient;

  PlanSuscripcionRemoteDataSource(this._dioClient);

  /// Obtiene la lista de planes de suscripcion disponibles
  ///
  /// GET /empresas/planes
  Future<List<PlanSuscripcionDetailModel>> getPlanes() async {
    final response = await _dioClient.get(
      '${ApiConstants.empresas}/planes',
    );

    if (response.data is! List) {
      throw Exception('Respuesta invalida del servidor');
    }

    return (response.data as List)
        .map((json) =>
            PlanSuscripcionDetailModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Cambia el plan de suscripcion de una empresa
  ///
  /// POST /empresas/:empresaId/cambiar-plan
  Future<void> cambiarPlan({
    required String empresaId,
    required String planId,
    String periodo = 'MENSUAL',
  }) async {
    await _dioClient.post(
      '${ApiConstants.empresas}/$empresaId/cambiar-plan',
      data: {'planId': planId, 'periodo': periodo},
    );
  }
}
