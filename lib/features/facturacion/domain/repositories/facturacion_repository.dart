import '../../../../core/utils/resource.dart';
import '../entities/comprobante_elegible_baja.dart';
import '../entities/comunicacion_baja.dart';
import '../entities/crear_comunicacion_baja_request.dart';
import '../entities/crear_nota_request.dart';
import '../entities/motivo_nota.dart';
import '../entities/nota_emitida.dart';
import '../entities/tipo_nota.dart';

abstract class FacturacionRepository {
  /// Devuelve los motivos válidos del catálogo SUNAT correspondiente.
  Future<Resource<List<MotivoNota>>> obtenerMotivosNota(TipoNota tipo);

  /// Emite una Nota de Crédito asociada al comprobante origen.
  Future<Resource<NotaEmitida>> crearNotaCredito({
    required String comprobanteOrigenId,
    required CrearNotaRequest request,
  });

  /// Emite una Nota de Débito asociada al comprobante origen.
  Future<Resource<NotaEmitida>> crearNotaDebito({
    required String comprobanteOrigenId,
    required CrearNotaRequest request,
  });

  // ── Comunicaciones de Baja (RA) ──

  /// Crea una CDB y la envía a SUNAT (asíncrono).
  Future<Resource<ComunicacionBaja>> crearComunicacionBaja(
      CrearComunicacionBajaRequest request);

  /// Lista comprobantes elegibles para anular en una fecha.
  Future<Resource<List<ComprobanteElegibleBaja>>> obtenerElegiblesBaja({
    required String sedeId,
    required String fechaReferencia,
  });

  /// Re-consulta estado de una CDB.
  Future<Resource<ComunicacionBaja>> consultarComunicacionBaja(String id);
}
