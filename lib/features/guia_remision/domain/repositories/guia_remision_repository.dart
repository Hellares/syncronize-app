import '../../../../core/utils/resource.dart';
import '../entities/guia_remision.dart';

abstract class GuiaRemisionRepository {
  Future<Resource<({List<GuiaRemision> data, int total, int totalPages})>> listar({
    String? tipo,
    String? estado,
    String? sunatStatus,
    String? motivoTraslado,
    String? fechaDesde,
    String? fechaHasta,
    String? busqueda,
    int page = 1,
    int limit = 20,
  });

  Future<Resource<GuiaRemision>> obtener(String id);
  Future<Resource<GuiaRemision>> actualizar(String id, Map<String, dynamic> data);
  Future<Resource<Map<String, dynamic>>> prefillDesdeVenta(String ventaId);
  Future<Resource<GuiaRemision>> crear(Map<String, dynamic> data);
  Future<Resource<Map<String, dynamic>>> enviar(String id);
  Future<Resource<Map<String, dynamic>>> consultar(String id);
  Future<Resource<Map<String, dynamic>>> enviarPendientes();

  // Catalogos
  Future<Resource<List<VehiculoEmpresa>>> listarVehiculos();
  Future<Resource<VehiculoEmpresa>> crearVehiculo(Map<String, dynamic> data);
  Future<Resource<List<ConductorEmpresa>>> listarConductores();
  Future<Resource<ConductorEmpresa>> crearConductor(Map<String, dynamic> data);
  Future<Resource<List<TransportistaEmpresa>>> listarTransportistas();
  Future<Resource<TransportistaEmpresa>> crearTransportista(Map<String, dynamic> data);
}
