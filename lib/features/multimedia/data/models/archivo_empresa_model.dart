import '../../domain/entities/archivo_empresa.dart';

class ArchivoEmpresaModel extends ArchivoEmpresa {
  const ArchivoEmpresaModel({
    required super.id,
    required super.url,
    super.urlThumbnail,
    required super.nombreOriginal,
    required super.tipoArchivo,
    required super.mimeType,
    required super.tamanoBytes,
    super.entidadTipo,
    super.entidadId,
    super.entidadNombre,
    super.categoria,
    super.ancho,
    super.alto,
    required super.creadoEn,
  });

  factory ArchivoEmpresaModel.fromJson(Map<String, dynamic> json) {
    return ArchivoEmpresaModel(
      id: json['id'] as String,
      url: json['url'] as String,
      urlThumbnail: json['urlThumbnail'] as String?,
      nombreOriginal: json['nombreOriginal'] as String? ?? '',
      tipoArchivo: json['tipoArchivo'] as String? ?? 'OTRO',
      mimeType: json['mimeType'] as String? ?? '',
      tamanoBytes: json['tamanoBytes'] as int? ?? 0,
      entidadTipo: json['entidadTipo'] as String?,
      entidadId: json['entidadId'] as String?,
      entidadNombre: json['entidadNombre'] as String?,
      categoria: json['categoria'] as String?,
      ancho: json['ancho'] as int?,
      alto: json['alto'] as int?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
  }
}

class GaleriaStatsModel extends GaleriaStats {
  const GaleriaStatsModel({
    required super.totalArchivos,
    required super.usadoMB,
    super.limiteMB,
    super.plan,
    required super.porTipo,
  });

  factory GaleriaStatsModel.fromJson(Map<String, dynamic> json) {
    return GaleriaStatsModel(
      totalArchivos: json['totalArchivos'] as int? ?? 0,
      usadoMB: json['usadoMB'] as int? ?? 0,
      limiteMB: json['limiteMB'] as int?,
      plan: json['plan'] as String?,
      porTipo: (json['porTipo'] as List?)
              ?.map((t) => TipoStats(
                    tipo: t['tipo'] as String? ?? '',
                    cantidad: t['cantidad'] as int? ?? 0,
                    mb: t['mb'] as int? ?? 0,
                  ))
              .toList() ??
          [],
    );
  }
}
