import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/anulacion.dart';
import '../entities/comunicacion_baja.dart';
import '../entities/resumen_diario.dart';
import '../repositories/facturacion_repository.dart';

@lazySingleton
class ListarCDBsUseCase {
  final FacturacionRepository _repository;
  ListarCDBsUseCase(this._repository);

  Future<Resource<AnulacionesPaginadas<ComunicacionBaja>>> call({
    String? estadoSunat,
    String? fechaDesde,
    String? fechaHasta,
    int page = 1,
    int limit = 20,
  }) {
    return _repository.listarCDBs(
      estadoSunat: estadoSunat,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
      page: page,
      limit: limit,
    );
  }
}

@lazySingleton
class ListarRCsUseCase {
  final FacturacionRepository _repository;
  ListarRCsUseCase(this._repository);

  Future<Resource<AnulacionesPaginadas<ResumenDiario>>> call({
    String? estadoSunat,
    String? fechaDesde,
    String? fechaHasta,
    int page = 1,
    int limit = 20,
  }) {
    return _repository.listarRCs(
      estadoSunat: estadoSunat,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
      page: page,
      limit: limit,
    );
  }
}

@lazySingleton
class ConsultarCDBUseCase {
  final FacturacionRepository _repository;
  ConsultarCDBUseCase(this._repository);

  Future<Resource<ComunicacionBaja>> call(String id) {
    return _repository.consultarComunicacionBaja(id);
  }
}

@lazySingleton
class ConsultarRCUseCase {
  final FacturacionRepository _repository;
  ConsultarRCUseCase(this._repository);

  Future<Resource<ResumenDiario>> call(String id) {
    return _repository.consultarResumenDiario(id);
  }
}
