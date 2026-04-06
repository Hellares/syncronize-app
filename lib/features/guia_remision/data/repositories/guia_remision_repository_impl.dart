import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/guia_remision.dart';
import '../../domain/repositories/guia_remision_repository.dart';
import '../datasources/guia_remision_remote_datasource.dart';

@LazySingleton(as: GuiaRemisionRepository)
class GuiaRemisionRepositoryImpl implements GuiaRemisionRepository {
  final GuiaRemisionRemoteDatasource _datasource;
  GuiaRemisionRepositoryImpl(this._datasource);

  @override
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
  }) async {
    try {
      final result = await _datasource.listar(
        tipo: tipo,
        estado: estado,
        sunatStatus: sunatStatus,
        motivoTraslado: motivoTraslado,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        busqueda: busqueda,
        page: page,
        limit: limit,
      );
      return Success(result);
    } catch (e) {
      return Error('Error al listar guias de remision: $e');
    }
  }

  @override
  Future<Resource<GuiaRemision>> obtener(String id) async {
    try {
      final result = await _datasource.obtener(id);
      return Success(result);
    } catch (e) {
      return Error('Error al obtener guia de remision: $e');
    }
  }

  @override
  Future<Resource<GuiaRemision>> actualizar(String id, Map<String, dynamic> data) async {
    try {
      final result = await _datasource.actualizar(id, data);
      return Success(result);
    } catch (e) {
      return Error('Error al actualizar guia de remision: $e');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> prefillDesdeVenta(String ventaId) async {
    try {
      final result = await _datasource.prefillDesdeVenta(ventaId);
      return Success(result);
    } catch (e) {
      return Error('Error al cargar datos de la venta: $e');
    }
  }

  @override
  Future<Resource<GuiaRemision>> crear(Map<String, dynamic> data) async {
    try {
      final result = await _datasource.crear(data);
      return Success(result);
    } catch (e) {
      return Error('Error al crear guia de remision: $e');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> enviar(String id) async {
    try {
      final result = await _datasource.enviar(id);
      return Success(result);
    } catch (e) {
      return Error('Error al enviar guia de remision: $e');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> consultar(String id) async {
    try {
      final result = await _datasource.consultar(id);
      return Success(result);
    } catch (e) {
      return Error('Error al consultar guia de remision: $e');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> enviarPendientes() async {
    try {
      final result = await _datasource.enviarPendientes();
      return Success(result);
    } catch (e) {
      return Error('Error al enviar pendientes: $e');
    }
  }

  // --- Catalogos ---

  @override
  Future<Resource<List<VehiculoEmpresa>>> listarVehiculos() async {
    try {
      final result = await _datasource.listarVehiculos();
      return Success(result);
    } catch (e) {
      return Error('Error al listar vehiculos: $e');
    }
  }

  @override
  Future<Resource<VehiculoEmpresa>> crearVehiculo(Map<String, dynamic> data) async {
    try {
      final result = await _datasource.crearVehiculo(data);
      return Success(result);
    } catch (e) {
      return Error('Error al crear vehiculo: $e');
    }
  }

  @override
  Future<Resource<List<ConductorEmpresa>>> listarConductores() async {
    try {
      final result = await _datasource.listarConductores();
      return Success(result);
    } catch (e) {
      return Error('Error al listar conductores: $e');
    }
  }

  @override
  Future<Resource<ConductorEmpresa>> crearConductor(Map<String, dynamic> data) async {
    try {
      final result = await _datasource.crearConductor(data);
      return Success(result);
    } catch (e) {
      return Error('Error al crear conductor: $e');
    }
  }

  @override
  Future<Resource<List<TransportistaEmpresa>>> listarTransportistas() async {
    try {
      final result = await _datasource.listarTransportistas();
      return Success(result);
    } catch (e) {
      return Error('Error al listar transportistas: $e');
    }
  }

  @override
  Future<Resource<TransportistaEmpresa>> crearTransportista(Map<String, dynamic> data) async {
    try {
      final result = await _datasource.crearTransportista(data);
      return Success(result);
    } catch (e) {
      return Error('Error al crear transportista: $e');
    }
  }
}
