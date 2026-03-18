import '../../../../core/utils/resource.dart';
import '../entities/direccion_persona.dart';

abstract class DireccionRepository {
  Future<Resource<List<DireccionPersona>>> listar();
  Future<Resource<DireccionPersona>> crear(Map<String, dynamic> data);
  Future<Resource<DireccionPersona>> actualizar(String id, Map<String, dynamic> data);
  Future<Resource<void>> eliminar(String id);
  Future<Resource<DireccionPersona>> marcarPredeterminada(String id);
}
