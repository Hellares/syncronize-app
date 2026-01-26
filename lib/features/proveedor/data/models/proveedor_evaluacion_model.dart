import '../../domain/entities/proveedor_evaluacion.dart';

/// Model que representa una evaluación del proveedor
class ProveedorEvaluacionModel extends ProveedorEvaluacion {
  const ProveedorEvaluacionModel({
    required super.id,
    required super.proveedorId,
    required super.empresaId,
    required super.calidadProductos,
    required super.cumplimientoPlazos,
    required super.atencionServicio,
    required super.preciosCompetitivos,
    required super.calificacionGeneral,
    super.comentarios,
    required super.evaluadoPor,
    required super.fechaEvaluacion,
  });

  /// Crea una instancia desde JSON
  factory ProveedorEvaluacionModel.fromJson(Map<String, dynamic> json) {
    return ProveedorEvaluacionModel(
      id: json['id'] as String,
      proveedorId: json['proveedorId'] as String,
      empresaId: json['empresaId'] as String,
      calidadProductos: json['calidadProductos'] as int,
      cumplimientoPlazos: json['cumplimientoPlazos'] as int,
      atencionServicio: json['atencionServicio'] as int,
      preciosCompetitivos: json['preciosCompetitivos'] as int,
      calificacionGeneral: double.parse(json['calificacionGeneral'].toString()),
      comentarios: json['comentarios'] as String?,
      evaluadoPor: json['evaluadoPor'] as String,
      fechaEvaluacion: DateTime.parse(json['fechaEvaluacion'] as String),
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'calidadProductos': calidadProductos,
      'cumplimientoPlazos': cumplimientoPlazos,
      'atencionServicio': atencionServicio,
      'preciosCompetitivos': preciosCompetitivos,
      'comentarios': comentarios,
    };
  }
}
