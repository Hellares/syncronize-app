import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/comprobante_elegible_baja.dart';
import '../../domain/entities/comunicacion_baja.dart';
import '../../domain/entities/crear_comunicacion_baja_request.dart';
import '../../domain/entities/crear_nota_request.dart';
import '../../domain/entities/motivo_nota.dart';
import '../../domain/entities/nota_emitida.dart';
import '../../domain/entities/tipo_nota.dart';
import '../../domain/repositories/facturacion_repository.dart';
import '../datasources/facturacion_remote_datasource.dart';

@LazySingleton(as: FacturacionRepository)
class FacturacionRepositoryImpl implements FacturacionRepository {
  final FacturacionRemoteDatasource _datasource;
  FacturacionRepositoryImpl(this._datasource);

  @override
  Future<Resource<List<MotivoNota>>> obtenerMotivosNota(TipoNota tipo) async {
    try {
      final result = await _datasource.obtenerMotivosNota(tipo);
      return Success<List<MotivoNota>>(result);
    } catch (e) {
      return Error('No se pudieron cargar los motivos: ${_humanize(e)}');
    }
  }

  @override
  Future<Resource<NotaEmitida>> crearNotaCredito({
    required String comprobanteOrigenId,
    required CrearNotaRequest request,
  }) async {
    try {
      final result = await _datasource.crearNotaCredito(
        comprobanteOrigenId: comprobanteOrigenId,
        request: request,
      );
      return Success<NotaEmitida>(result);
    } catch (e) {
      return Error('Error al emitir nota de crédito: ${_humanize(e)}');
    }
  }

  @override
  Future<Resource<NotaEmitida>> crearNotaDebito({
    required String comprobanteOrigenId,
    required CrearNotaRequest request,
  }) async {
    try {
      final result = await _datasource.crearNotaDebito(
        comprobanteOrigenId: comprobanteOrigenId,
        request: request,
      );
      return Success<NotaEmitida>(result);
    } catch (e) {
      return Error('Error al emitir nota de débito: ${_humanize(e)}');
    }
  }

  // ── Comunicaciones de Baja (RA) ──

  @override
  Future<Resource<ComunicacionBaja>> crearComunicacionBaja(
      CrearComunicacionBajaRequest request) async {
    try {
      final result = await _datasource.crearComunicacionBaja(request);
      return Success<ComunicacionBaja>(result);
    } catch (e) {
      return Error('Error al crear comunicación de baja: ${_humanize(e)}');
    }
  }

  @override
  Future<Resource<List<ComprobanteElegibleBaja>>> obtenerElegiblesBaja({
    required String sedeId,
    required String fechaReferencia,
  }) async {
    try {
      final result = await _datasource.obtenerElegiblesBaja(
        sedeId: sedeId,
        fechaReferencia: fechaReferencia,
      );
      return Success<List<ComprobanteElegibleBaja>>(result);
    } catch (e) {
      return Error('Error al obtener elegibles: ${_humanize(e)}');
    }
  }

  @override
  Future<Resource<ComunicacionBaja>> consultarComunicacionBaja(String id) async {
    try {
      final result = await _datasource.consultarComunicacionBaja(id);
      return Success<ComunicacionBaja>(result);
    } catch (e) {
      return Error('Error al consultar CDB: ${_humanize(e)}');
    }
  }

  String _humanize(Object e) {
    final s = e.toString();
    return s.length > 300 ? '${s.substring(0, 300)}…' : s;
  }
}
