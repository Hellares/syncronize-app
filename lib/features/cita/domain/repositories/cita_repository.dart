import '../../../../core/utils/resource.dart';
import '../entities/cita.dart';
import '../entities/cliente_con_citas.dart';
import '../entities/slot_disponibilidad.dart';

abstract class CitaRepository {
  Future<Resource<DisponibilidadResponse>> getDisponibilidad({
    required String fecha,
    required String sedeId,
    required String servicioId,
    String? tecnicoId,
  });

  Future<Resource<List<TecnicoDisponible>>> getTecnicosDisponibles({
    required String fecha,
    required String horaInicio,
    required String sedeId,
    required String servicioId,
  });

  Future<Resource<Cita>> create(Map<String, dynamic> data);

  Future<Resource<CitasPaginadas>> findAll(Map<String, dynamic> queryParams);

  Future<Resource<CitasPaginadas>> findMisCitas(Map<String, dynamic> queryParams);

  Future<Resource<Cita>> findOne(String id);

  Future<Resource<Cita>> update(String id, Map<String, dynamic> data);

  Future<Resource<Map<String, dynamic>>> transitionEstado(
    String id,
    Map<String, dynamic> data,
  );

  Future<Resource<({List<CitaItem> items, double total})>> getItems(String citaId);

  Future<Resource<List<ClienteConCitas>>> getClientesConCitas({String? search});

  Future<Resource<({List<Cita> citas, int total})>> getHistorialCliente(
    String clienteId, {
    String? clienteEmpresaId,
  });

  Future<Resource<void>> addItem(String citaId, Map<String, dynamic> data);

  Future<Resource<void>> updateItem(String citaId, String itemId, Map<String, dynamic> data);

  Future<Resource<void>> removeItem(String citaId, String itemId);
}
