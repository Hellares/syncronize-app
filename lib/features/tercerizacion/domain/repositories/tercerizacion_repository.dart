import '../../../../core/utils/resource.dart';
import '../entities/directorio_empresa.dart';
import '../entities/tercerizacion.dart';

abstract class TercerizacionRepository {
  Future<Resource<DirectorioPaginado>> buscarEmpresas({
    required String empresaId,
    String? search,
    String? tipoServicio,
    String? departamento,
    String? distrito,
    int page = 1,
    int limit = 20,
  });

  Future<Resource<TercerizacionServicio>> crear({
    required String empresaDestinoId,
    required String ordenOrigenId,
    String? notasOrigen,
    String? descripcionProblema,
    List<String>? sintomas,
  });

  Future<Resource<TercerizacionesPaginadas>> listar({
    required String empresaId,
    String? tipo, // 'enviadas' | 'recibidas'
    String? estado,
    int page = 1,
    int limit = 20,
  });

  Future<Resource<TercerizacionServicio>> getById({
    required String id,
  });

  Future<Resource<List<TercerizacionServicio>>> getPendientes();

  Future<Resource<TercerizacionServicio>> responder({
    required String id,
    required bool aceptar,
    String? motivoRechazo,
    String? notasDestino,
  });

  Future<Resource<TercerizacionServicio>> completar({
    required String id,
    required double precioB2B,
    String? metodoPagoB2B,
    String? notasDestino,
  });

  Future<Resource<TercerizacionServicio>> cancelar({
    required String id,
  });
}
