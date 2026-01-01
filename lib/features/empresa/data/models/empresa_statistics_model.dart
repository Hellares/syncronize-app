import '../../domain/entities/empresa_statistics.dart';

class EmpresaStatisticsModel extends EmpresaStatistics {
  const EmpresaStatisticsModel({
    required super.totalProductos,
    required super.totalServicios,
    required super.totalUsuarios,
    required super.totalSedes,
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
      ordenesPendientes: entity.ordenesPendientes,
      comprobantesMes: entity.comprobantesMes,
      ingresosMes: entity.ingresosMes,
    );
  }
}
