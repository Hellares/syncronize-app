import 'package:equatable/equatable.dart';
import 'comunicacion_baja.dart';
import 'resumen_diario.dart';

/// Tipo de mecanismo SUNAT que ejecutó la anulación.
enum TipoAnulacion { cdb, rc }

/// Vista unificada de Comunicación de Baja (CDB / RA) y Resumen Diario (RC).
/// Se construye desde una `ComunicacionBaja` o `ResumenDiario` para que la UI
/// pueda iterar una sola lista mezclada.
class Anulacion extends Equatable {
  final TipoAnulacion tipo;
  final String id;
  final String numeroCompleto;
  final String estadoSunat;
  final DateTime fechaEmision;
  final DateTime fechaReferencia;
  final String motivo;
  final String? ticket;
  final String? errorProveedor;
  final int cantidadDocumentos;
  final List<DocumentoAnulado> documentos;

  /// Original CDB (solo si tipo == cdb). Útil para vista detalle.
  final ComunicacionBaja? cdb;

  /// Original RC (solo si tipo == rc). Útil para vista detalle.
  final ResumenDiario? rc;

  const Anulacion({
    required this.tipo,
    required this.id,
    required this.numeroCompleto,
    required this.estadoSunat,
    required this.fechaEmision,
    required this.fechaReferencia,
    required this.motivo,
    this.ticket,
    this.errorProveedor,
    required this.cantidadDocumentos,
    required this.documentos,
    this.cdb,
    this.rc,
  });

  bool get esAceptado => estadoSunat == 'ACEPTADO';
  bool get esRechazado => estadoSunat == 'RECHAZADO';
  bool get esProcesando =>
      estadoSunat == 'PROCESANDO' ||
      estadoSunat == 'PENDIENTE' ||
      estadoSunat == 'ENVIADO';

  String get tipoLabel => tipo == TipoAnulacion.cdb ? 'CDB' : 'RC';
  String get tipoDescripcion =>
      tipo == TipoAnulacion.cdb ? 'Comunicación de Baja' : 'Resumen Diario';

  factory Anulacion.fromCDB(ComunicacionBaja cdb) {
    return Anulacion(
      tipo: TipoAnulacion.cdb,
      id: cdb.id,
      numeroCompleto: cdb.numeroCompleto,
      estadoSunat: cdb.estadoSunat,
      fechaEmision: cdb.fechaEmision,
      fechaReferencia: cdb.fechaReferencia,
      motivo: cdb.motivoBaja,
      ticket: cdb.ticket,
      errorProveedor: cdb.errorProveedor,
      cantidadDocumentos: cdb.detalles.length,
      documentos: cdb.detalles
          .map((d) => DocumentoAnulado(
                id: d.id,
                comprobanteId: d.comprobanteId,
                comprobanteCodigo: d.comprobanteCodigo,
                tipoComprobante: d.tipoComprobante,
                motivoEspecifico: d.motivoEspecifico,
              ))
          .toList(),
      cdb: cdb,
    );
  }

  factory Anulacion.fromRC(ResumenDiario rc) {
    return Anulacion(
      tipo: TipoAnulacion.rc,
      id: rc.id,
      numeroCompleto: rc.numeroCompleto,
      estadoSunat: rc.estadoSunat,
      fechaEmision: rc.fechaEmision,
      fechaReferencia: rc.fechaReferencia,
      motivo: rc.motivoAnulacion,
      ticket: rc.ticket,
      errorProveedor: rc.errorProveedor,
      cantidadDocumentos: rc.detalles.length,
      documentos: rc.detalles
          .map((d) => DocumentoAnulado(
                id: d.id,
                comprobanteId: d.comprobanteId,
                comprobanteCodigo: d.comprobanteCodigo,
                tipoComprobante: d.tipoComprobante,
                motivoEspecifico: d.motivoEspecifico,
              ))
          .toList(),
      rc: rc,
    );
  }

  @override
  List<Object?> get props => [tipo, id, estadoSunat];
}

class DocumentoAnulado extends Equatable {
  final String id;
  final String comprobanteId;
  final String comprobanteCodigo;
  final String tipoComprobante;
  final String motivoEspecifico;

  const DocumentoAnulado({
    required this.id,
    required this.comprobanteId,
    required this.comprobanteCodigo,
    required this.tipoComprobante,
    required this.motivoEspecifico,
  });

  @override
  List<Object?> get props => [id, comprobanteId];
}

/// Página de resultados (común a CDB y RC, los endpoints devuelven la misma forma).
class AnulacionesPaginadas<T> extends Equatable {
  final List<T> data;
  final int total;
  final int totalPages;
  final int page;

  const AnulacionesPaginadas({
    required this.data,
    required this.total,
    required this.totalPages,
    required this.page,
  });

  @override
  List<Object?> get props => [data, total, totalPages, page];
}
