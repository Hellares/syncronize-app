import '../../domain/entities/empresa_statistics.dart';

class EmpresaStatisticsModel extends EmpresaStatistics {
  const EmpresaStatisticsModel({
    required super.totalProductos,
    required super.totalServicios,
    required super.totalUsuarios,
    required super.totalSedes,
    super.totalCotizaciones,
    super.totalProveedores,
    required super.ordenesPendientes,
    super.comprobantesMes,
    super.ingresosMes,
  });

  factory EmpresaStatisticsModel.fromJson(Map<String, dynamic> json) {
    return EmpresaStatisticsModel(
      totalProductos: json['totalProductos'] as int? ?? 0,
      totalServicios: json['totalServicios'] as int? ?? 0,
      totalUsuarios: json['totalUsuarios'] as int? ?? 0,
      totalSedes: json['totalSedes'] as int? ?? 0,
      totalCotizaciones: json['totalCotizaciones'] as int? ?? 0,
      totalProveedores: json['totalProveedores'] as int? ?? 0,
      ordenesPendientes: json['ordenesPendientes'] as int? ?? 0,
      comprobantesMes: json['comprobantesMes'] as int?,
      ingresosMes: json['ingresosMes'] != null
          ? (json['ingresosMes'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalProductos': totalProductos,
      'totalServicios': totalServicios,
      'totalUsuarios': totalUsuarios,
      'totalSedes': totalSedes,
      'totalCotizaciones': totalCotizaciones,
      'totalProveedores': totalProveedores,
      'ordenesPendientes': ordenesPendientes,
      if (comprobantesMes != null) 'comprobantesMes': comprobantesMes,
      if (ingresosMes != null) 'ingresosMes': ingresosMes,
    };
  }

  EmpresaStatistics toEntity() => this;

  factory EmpresaStatisticsModel.fromEntity(EmpresaStatistics entity) {
    return EmpresaStatisticsModel(
      totalProductos: entity.totalProductos,
      totalServicios: entity.totalServicios,
      totalUsuarios: entity.totalUsuarios,
      totalSedes: entity.totalSedes,
      totalCotizaciones: entity.totalCotizaciones,
      totalProveedores: entity.totalProveedores,
      ordenesPendientes: entity.ordenesPendientes,
      comprobantesMes: entity.comprobantesMes,
      ingresosMes: entity.ingresosMes,
    );
  }
}

class PlanLimitInfoModel extends PlanLimitInfo {
  const PlanLimitInfoModel({
    super.limite,
    required super.actual,
    super.disponible,
  });

  factory PlanLimitInfoModel.fromJson(Map<String, dynamic> json) {
    return PlanLimitInfoModel(
      limite: json['limite'] as int?,
      actual: json['actual'] as int? ?? 0,
      disponible: json['disponible'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'limite': limite,
        'actual': actual,
        'disponible': disponible,
      };
}

class PlanLimitsInfoModel extends PlanLimitsInfo {
  const PlanLimitsInfoModel({
    super.planName,
    required super.productos,
    required super.servicios,
    required super.usuarios,
    required super.sedes,
    required super.plantillasAtributos,
    required super.cotizaciones,
  });

  factory PlanLimitsInfoModel.fromJson(Map<String, dynamic> json) {
    final limites = json['limites'] as Map<String, dynamic>? ?? {};
    return PlanLimitsInfoModel(
      planName: json['plan'] as String?,
      productos: limites['productos'] != null
          ? PlanLimitInfoModel.fromJson(
              limites['productos'] as Map<String, dynamic>)
          : const PlanLimitInfoModel(actual: 0),
      servicios: limites['servicios'] != null
          ? PlanLimitInfoModel.fromJson(
              limites['servicios'] as Map<String, dynamic>)
          : const PlanLimitInfoModel(actual: 0),
      usuarios: limites['usuarios'] != null
          ? PlanLimitInfoModel.fromJson(
              limites['usuarios'] as Map<String, dynamic>)
          : const PlanLimitInfoModel(actual: 0),
      sedes: limites['sedes'] != null
          ? PlanLimitInfoModel.fromJson(
              limites['sedes'] as Map<String, dynamic>)
          : const PlanLimitInfoModel(actual: 0),
      plantillasAtributos: limites['plantillasAtributos'] != null
          ? PlanLimitInfoModel.fromJson(
              limites['plantillasAtributos'] as Map<String, dynamic>)
          : const PlanLimitInfoModel(actual: 0),
      cotizaciones: limites['cotizaciones'] != null
          ? PlanLimitInfoModel.fromJson(
              limites['cotizaciones'] as Map<String, dynamic>)
          : const PlanLimitInfoModel(actual: 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'plan': planName,
        'limites': {
          'productos': (productos as PlanLimitInfoModel).toJson(),
          'servicios': (servicios as PlanLimitInfoModel).toJson(),
          'usuarios': (usuarios as PlanLimitInfoModel).toJson(),
          'sedes': (sedes as PlanLimitInfoModel).toJson(),
          'plantillasAtributos':
              (plantillasAtributos as PlanLimitInfoModel).toJson(),
          'cotizaciones': (cotizaciones as PlanLimitInfoModel).toJson(),
        },
      };

  PlanLimitsInfo toEntity() => this;
}
