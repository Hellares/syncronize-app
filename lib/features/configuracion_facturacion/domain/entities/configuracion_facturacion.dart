import 'package:equatable/equatable.dart';

enum ProveedorFacturacion {
  nubefact,
  syncrofact;

  static ProveedorFacturacion fromString(String raw) {
    switch (raw.toUpperCase()) {
      case 'NUBEFACT':
        return ProveedorFacturacion.nubefact;
      case 'SYNCROFACT':
        return ProveedorFacturacion.syncrofact;
      default:
        return ProveedorFacturacion.syncrofact;
    }
  }

  String get value {
    switch (this) {
      case ProveedorFacturacion.nubefact:
        return 'NUBEFACT';
      case ProveedorFacturacion.syncrofact:
        return 'SYNCROFACT';
    }
  }

  String get label {
    switch (this) {
      case ProveedorFacturacion.nubefact:
        return 'Nubefact';
      case ProveedorFacturacion.syncrofact:
        return 'Syncrofact';
    }
  }

  /// URL por defecto del ambiente indicado para este proveedor.
  String defaultUrl(EntornoFacturacion entorno) {
    switch (this) {
      case ProveedorFacturacion.syncrofact:
        return entorno == EntornoFacturacion.produccion
            ? 'https://syncrofact.net.pe/api'
            : 'http://beta.syncrofact.net.pe/api';
      case ProveedorFacturacion.nubefact:
        // Nubefact usa URL específica por RUC — no hay default genérico.
        return '';
    }
  }

  /// ¿El proveedor requiere companyId y branchId en proveedorConfig?
  bool get requiereCompanyBranch => this == ProveedorFacturacion.syncrofact;
}

enum EntornoFacturacion {
  beta,
  produccion;

  static EntornoFacturacion fromString(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'PRODUCCION':
        return EntornoFacturacion.produccion;
      case 'BETA':
      default:
        return EntornoFacturacion.beta;
    }
  }

  String get value {
    switch (this) {
      case EntornoFacturacion.beta:
        return 'BETA';
      case EntornoFacturacion.produccion:
        return 'PRODUCCION';
    }
  }

  String get label {
    switch (this) {
      case EntornoFacturacion.beta:
        return 'Pruebas (BETA)';
      case EntornoFacturacion.produccion:
        return 'Producción';
    }
  }
}

class ConfiguracionFacturacion extends Equatable {
  final ProveedorFacturacion proveedorActivo;
  final String? proveedorRuta;
  final String? proveedorToken;
  final Map<String, dynamic>? proveedorConfig;
  final bool facturacionActiva;
  final EntornoFacturacion entorno;
  final String? emailFacturacion;
  final String? resolucionSunat;

  const ConfiguracionFacturacion({
    required this.proveedorActivo,
    this.proveedorRuta,
    this.proveedorToken,
    this.proveedorConfig,
    this.facturacionActiva = false,
    this.entorno = EntornoFacturacion.beta,
    this.emailFacturacion,
    this.resolucionSunat,
  });

  /// Lectura segura de companyId desde proveedorConfig (Syncrofact).
  int? get companyId {
    final v = proveedorConfig?['companyId'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// Lectura segura de branchId desde proveedorConfig (Syncrofact).
  int? get branchId {
    final v = proveedorConfig?['branchId'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  ConfiguracionFacturacion copyWith({
    ProveedorFacturacion? proveedorActivo,
    String? proveedorRuta,
    String? proveedorToken,
    Map<String, dynamic>? proveedorConfig,
    bool? facturacionActiva,
    EntornoFacturacion? entorno,
    String? emailFacturacion,
    String? resolucionSunat,
  }) {
    return ConfiguracionFacturacion(
      proveedorActivo: proveedorActivo ?? this.proveedorActivo,
      proveedorRuta: proveedorRuta ?? this.proveedorRuta,
      proveedorToken: proveedorToken ?? this.proveedorToken,
      proveedorConfig: proveedorConfig ?? this.proveedorConfig,
      facturacionActiva: facturacionActiva ?? this.facturacionActiva,
      entorno: entorno ?? this.entorno,
      emailFacturacion: emailFacturacion ?? this.emailFacturacion,
      resolucionSunat: resolucionSunat ?? this.resolucionSunat,
    );
  }

  @override
  List<Object?> get props => [
        proveedorActivo,
        proveedorRuta,
        proveedorToken,
        proveedorConfig,
        facturacionActiva,
        entorno,
        emailFacturacion,
        resolucionSunat,
      ];
}

/// Resultado de probar conexión con el proveedor.
class ResultadoProbarConexion extends Equatable {
  final bool ok;
  final String mensaje;
  final ProveedorFacturacion proveedor;
  final List<BranchProbado> branches;
  final String? error;

  const ResultadoProbarConexion({
    required this.ok,
    required this.mensaje,
    required this.proveedor,
    this.branches = const [],
    this.error,
  });

  @override
  List<Object?> get props => [ok, mensaje, proveedor, branches, error];
}

class BranchProbado extends Equatable {
  final int branchIdProveedor;
  final String codigo;
  final String nombre;
  final int totalSeries;

  const BranchProbado({
    required this.branchIdProveedor,
    required this.codigo,
    required this.nombre,
    required this.totalSeries,
  });

  @override
  List<Object?> get props => [branchIdProveedor, codigo, nombre, totalSeries];
}
