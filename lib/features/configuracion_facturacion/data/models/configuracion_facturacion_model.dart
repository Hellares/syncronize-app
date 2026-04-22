import '../../domain/entities/configuracion_facturacion.dart';

class ConfiguracionFacturacionModel extends ConfiguracionFacturacion {
  const ConfiguracionFacturacionModel({
    required super.proveedorActivo,
    super.proveedorRuta,
    super.proveedorToken,
    super.proveedorConfig,
    super.facturacionActiva,
    super.entorno,
    super.emailFacturacion,
    super.resolucionSunat,
  });

  factory ConfiguracionFacturacionModel.fromJson(Map<String, dynamic> json) {
    final proveedorConfig = json['proveedorConfig'];
    return ConfiguracionFacturacionModel(
      proveedorActivo: ProveedorFacturacion.fromString(
        (json['proveedorActivo'] as String?) ?? 'SYNCROFACT',
      ),
      proveedorRuta: json['proveedorRuta'] as String?,
      proveedorToken: json['proveedorToken'] as String?,
      proveedorConfig: proveedorConfig is Map<String, dynamic>
          ? Map<String, dynamic>.from(proveedorConfig)
          : null,
      facturacionActiva: (json['facturacionActiva'] as bool?) ?? false,
      entorno: EntornoFacturacion.fromString(json['entorno'] as String?),
      emailFacturacion: json['emailFacturacion'] as String?,
      resolucionSunat: json['resolucionSunat'] as String?,
    );
  }

  ConfiguracionFacturacion toEntity() => this;
}

class ResultadoProbarConexionModel extends ResultadoProbarConexion {
  const ResultadoProbarConexionModel({
    required super.ok,
    required super.mensaje,
    required super.proveedor,
    super.branches,
    super.error,
  });

  factory ResultadoProbarConexionModel.fromJson(Map<String, dynamic> json) {
    final rawBranches = json['branches'];
    final branches = rawBranches is List
        ? rawBranches
            .whereType<Map<String, dynamic>>()
            .map((b) => BranchProbado(
                  branchIdProveedor: (b['branchIdProveedor'] as num?)?.toInt() ?? 0,
                  codigo: (b['codigo'] as String?) ?? '',
                  nombre: (b['nombre'] as String?) ?? '',
                  totalSeries: (b['totalSeries'] as num?)?.toInt() ?? 0,
                ))
            .toList()
        : const <BranchProbado>[];

    return ResultadoProbarConexionModel(
      ok: (json['ok'] as bool?) ?? false,
      mensaje: (json['mensaje'] as String?) ?? '',
      proveedor: ProveedorFacturacion.fromString(
        (json['proveedor'] as String?) ?? 'SYNCROFACT',
      ),
      branches: branches,
      error: json['error'] as String?,
    );
  }
}
