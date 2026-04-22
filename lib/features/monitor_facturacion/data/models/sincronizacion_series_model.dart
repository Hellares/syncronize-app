import '../../domain/entities/sincronizacion_series.dart';

class DiffSerieModel {
  static DiffSerie fromJson(Map<String, dynamic> json) {
    return DiffSerie(
      tipoDocumento: json['tipoDocumento'] as String,
      tipoDocumentoNombre: json['tipoDocumentoNombre'] as String,
      serieLocal: json['serieLocal'] as String?,
      correlativoLocal: (json['correlativoLocal'] as num?)?.toInt(),
      serieProveedor: json['serieProveedor'] as String?,
      correlativoProveedor: (json['correlativoProveedor'] as num?)?.toInt(),
      proximoNumeroProveedor: json['proximoNumeroProveedor'] as String?,
      accion: AccionDiff.fromString(json['accion'] as String? ?? 'EN_SINCRONIA'),
      mensaje: json['mensaje'] as String?,
      comprobantesEmitidosLocalmente:
          (json['comprobantesEmitidosLocalmente'] as num?)?.toInt() ?? 0,
    );
  }
}

class BranchPreviewInfoModel {
  static BranchPreviewInfo fromJson(Map<String, dynamic> json) {
    final diffsRaw = (json['diffs'] as List?) ?? const [];
    return BranchPreviewInfo(
      branchIdProveedor: json['branchIdProveedor'],
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      esActualDeLaSede: json['esActualDeLaSede'] as bool? ?? false,
      diffs: diffsRaw
          .map((e) => DiffSerieModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SincronizacionPreviewModel {
  static SincronizacionPreview fromJson(Map<String, dynamic> json) {
    final branchesRaw = (json['branches'] as List?) ?? const [];
    DateTime? fecha;
    final rawFecha = json['seriesSincronizadasEn'];
    if (rawFecha is String && rawFecha.isNotEmpty) {
      fecha = DateTime.tryParse(rawFecha);
    }
    return SincronizacionPreview(
      empresaId: json['empresaId'] as String,
      sedeId: json['sedeId'] as String,
      sedeNombre: json['sedeNombre'] as String? ?? '',
      rucEmpresa: json['rucEmpresa'] as String?,
      proveedorActivo: json['proveedorActivo'] as String? ?? '',
      seriesSincronizadasEn: fecha,
      branches: branchesRaw
          .map((e) => BranchPreviewInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

class CambioSerieModel {
  static CambioSerie fromJson(Map<String, dynamic> json) {
    return CambioSerie(
      tipoDocumento: json['tipoDocumento'] as String,
      campoSerie: json['campoSerie'] as String,
      campoContador: json['campoContador'] as String,
      serieAntes: json['serieAntes'] as String?,
      serieDespues: json['serieDespues'] as String,
      correlativoAntes: (json['correlativoAntes'] as num?)?.toInt(),
      correlativoDespues: (json['correlativoDespues'] as num?)?.toInt() ?? 0,
      accion: AccionDiff.fromString(json['accion'] as String? ?? 'EN_SINCRONIA'),
    );
  }
}

class ResultadoSincronizacionModel {
  static ResultadoSincronizacion fromJson(Map<String, dynamic> json) {
    final cambiosRaw = (json['cambios'] as List?) ?? const [];
    final erroresRaw = (json['errores'] as List?) ?? const [];
    return ResultadoSincronizacion(
      aplicados: (json['aplicados'] as num?)?.toInt() ?? 0,
      omitidos: (json['omitidos'] as num?)?.toInt() ?? 0,
      rechazados: (json['rechazados'] as num?)?.toInt() ?? 0,
      sedeId: json['sedeId'] as String,
      branchIdProveedor: json['branchIdProveedor'],
      cambios: cambiosRaw
          .map((e) => CambioSerieModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      errores: erroresRaw.map((e) => e.toString()).toList(),
    );
  }
}
