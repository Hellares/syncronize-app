import '../../../../core/network/dio_client.dart';
import '../models/actividad_unificada_model.dart';

class PortalUnificadoRemoteDataSource {
  final DioClient _dioClient;

  PortalUnificadoRemoteDataSource(this._dioClient);

  Future<ActividadUnificadaModel> getActividadUnificada() async {
    final response = await _dioClient.get('/portal-cliente/mi-actividad');
    return ActividadUnificadaModel.fromJson(response.data as Map<String, dynamic>);
  }
}
