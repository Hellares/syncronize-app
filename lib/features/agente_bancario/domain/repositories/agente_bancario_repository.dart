import '../../../../core/utils/resource.dart';
import '../entities/agente_bancario.dart';

abstract class AgenteBancarioRepository {
  Future<Resource<ResumenAgentes>> getResumen({String? sedeId});
  Future<Resource<List<AgenteBancario>>> getAgentes({String? sedeId});
  Future<Resource<AgenteBancario>> getDetalle(String id);
  Future<Resource<AgenteBancario>> crear(
      String sedeId, Map<String, dynamic> data);
  Future<Resource<OperacionAgente>> registrarOperacion(
      String agenteId, Map<String, dynamic> data);
  Future<Resource<void>> anularOperacion(
      String agenteId, String operacionId, String motivo);
  Future<Resource<List<OperacionAgente>>> getOperaciones(
    String agenteId, {
    String? tipo,
    String? fechaDesde,
    int? limit,
  });
}
