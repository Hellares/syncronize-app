import '../../../../core/utils/resource.dart';
import '../entities/cita.dart';
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

  Future<Resource<Cita>> findOne(String id);

  Future<Resource<Cita>> update(String id, Map<String, dynamic> data);

  Future<Resource<Map<String, dynamic>>> transitionEstado(
    String id,
    Map<String, dynamic> data,
  );
}
