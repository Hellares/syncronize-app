import '../../../../core/utils/resource.dart';
import '../entities/vinculacion.dart';

abstract class VinculacionRepository {
  Future<Resource<EmpresaVinculable?>> checkRuc({
    required String ruc,
  });

  Future<Resource<VinculacionEmpresa>> crear({
    String? clienteEmpresaId,
    String? ruc,
    String? mensaje,
  });

  Future<Resource<VinculacionesPaginadas>> listar({
    required String empresaId,
    String? tipo,
    String? estado,
    int page = 1,
    int limit = 20,
  });

  Future<Resource<VinculacionEmpresa>> getById({
    required String id,
  });

  Future<Resource<List<VinculacionEmpresa>>> getPendientes();

  Future<Resource<VinculacionEmpresa>> responder({
    required String id,
    required bool aceptar,
    String? motivoRechazo,
  });

  Future<Resource<VinculacionEmpresa>> cancelar({
    required String id,
  });

  Future<Resource<VinculacionEmpresa>> desvincular({
    required String id,
  });
}
