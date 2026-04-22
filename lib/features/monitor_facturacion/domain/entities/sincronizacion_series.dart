import 'package:equatable/equatable.dart';

enum AccionDiff {
  enSincronia,
  actualizarCorrelativo,
  reemplazarSerie,
  crearNueva,
  conflicto,
  noEmitible;

  static AccionDiff fromString(String raw) {
    switch (raw) {
      case 'EN_SINCRONIA': return AccionDiff.enSincronia;
      case 'ACTUALIZAR_CORRELATIVO': return AccionDiff.actualizarCorrelativo;
      case 'REEMPLAZAR_SERIE': return AccionDiff.reemplazarSerie;
      case 'CREAR_NUEVA': return AccionDiff.crearNueva;
      case 'CONFLICTO': return AccionDiff.conflicto;
      case 'NO_EMITIBLE': return AccionDiff.noEmitible;
      default: return AccionDiff.enSincronia;
    }
  }

  String get value {
    switch (this) {
      case AccionDiff.enSincronia: return 'EN_SINCRONIA';
      case AccionDiff.actualizarCorrelativo: return 'ACTUALIZAR_CORRELATIVO';
      case AccionDiff.reemplazarSerie: return 'REEMPLAZAR_SERIE';
      case AccionDiff.crearNueva: return 'CREAR_NUEVA';
      case AccionDiff.conflicto: return 'CONFLICTO';
      case AccionDiff.noEmitible: return 'NO_EMITIBLE';
    }
  }

  /// ¿Puede el usuario activar el switch "Aplicar" para este diff?
  bool get esAplicable =>
      this != AccionDiff.conflicto &&
      this != AccionDiff.enSincronia &&
      this != AccionDiff.noEmitible;
}

class DiffSerie extends Equatable {
  final String tipoDocumento;       // "01", "03", ...
  final String tipoDocumentoNombre; // "Factura", "Boleta", ...
  final String? serieLocal;
  final int? correlativoLocal;
  final String? serieProveedor;
  final int? correlativoProveedor;
  final String? proximoNumeroProveedor;
  final AccionDiff accion;
  final String? mensaje;
  final int comprobantesEmitidosLocalmente;

  const DiffSerie({
    required this.tipoDocumento,
    required this.tipoDocumentoNombre,
    this.serieLocal,
    this.correlativoLocal,
    this.serieProveedor,
    this.correlativoProveedor,
    this.proximoNumeroProveedor,
    required this.accion,
    this.mensaje,
    required this.comprobantesEmitidosLocalmente,
  });

  @override
  List<Object?> get props => [
        tipoDocumento,
        serieLocal,
        correlativoLocal,
        serieProveedor,
        correlativoProveedor,
        accion,
      ];
}

class BranchPreviewInfo extends Equatable {
  final dynamic branchIdProveedor; // string | number
  final String codigo;
  final String nombre;
  final bool esActualDeLaSede;
  final List<DiffSerie> diffs;

  const BranchPreviewInfo({
    required this.branchIdProveedor,
    required this.codigo,
    required this.nombre,
    required this.esActualDeLaSede,
    required this.diffs,
  });

  @override
  List<Object?> get props => [branchIdProveedor, codigo, esActualDeLaSede, diffs];
}

class SincronizacionPreview extends Equatable {
  final String empresaId;
  final String sedeId;
  final String sedeNombre;
  final String? rucEmpresa;
  final String proveedorActivo;
  final DateTime? seriesSincronizadasEn;
  final List<BranchPreviewInfo> branches;
  final Map<String, dynamic>? metadata;

  const SincronizacionPreview({
    required this.empresaId,
    required this.sedeId,
    required this.sedeNombre,
    this.rucEmpresa,
    required this.proveedorActivo,
    this.seriesSincronizadasEn,
    required this.branches,
    this.metadata,
  });

  @override
  List<Object?> get props => [sedeId, proveedorActivo, branches, seriesSincronizadasEn];
}

/// Selección que el usuario envía al aplicar.
class SeleccionSerie extends Equatable {
  final String tipoDocumento;
  final String serieProveedor;
  final int correlativoProveedor;
  final bool aplicar;

  const SeleccionSerie({
    required this.tipoDocumento,
    required this.serieProveedor,
    required this.correlativoProveedor,
    required this.aplicar,
  });

  Map<String, dynamic> toJson() => {
        'tipoDocumento': tipoDocumento,
        'serieProveedor': serieProveedor,
        'correlativoProveedor': correlativoProveedor,
        'accion': aplicar ? 'APLICAR' : 'OMITIR',
      };

  @override
  List<Object?> get props => [tipoDocumento, serieProveedor, correlativoProveedor, aplicar];
}

class CambioSerie extends Equatable {
  final String tipoDocumento;
  final String campoSerie;
  final String campoContador;
  final String? serieAntes;
  final String serieDespues;
  final int? correlativoAntes;
  final int correlativoDespues;
  final AccionDiff accion;

  const CambioSerie({
    required this.tipoDocumento,
    required this.campoSerie,
    required this.campoContador,
    this.serieAntes,
    required this.serieDespues,
    this.correlativoAntes,
    required this.correlativoDespues,
    required this.accion,
  });

  @override
  List<Object?> get props => [tipoDocumento, serieAntes, serieDespues, correlativoAntes, correlativoDespues];
}

class ResultadoSincronizacion extends Equatable {
  final int aplicados;
  final int omitidos;
  final int rechazados;
  final String sedeId;
  final dynamic branchIdProveedor;
  final List<CambioSerie> cambios;
  final List<String> errores;

  const ResultadoSincronizacion({
    required this.aplicados,
    required this.omitidos,
    required this.rechazados,
    required this.sedeId,
    this.branchIdProveedor,
    required this.cambios,
    required this.errores,
  });

  @override
  List<Object?> get props => [aplicados, omitidos, rechazados, sedeId, cambios.length, errores.length];
}
