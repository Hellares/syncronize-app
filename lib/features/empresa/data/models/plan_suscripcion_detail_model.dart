import '../../domain/entities/plan_suscripcion_detail.dart';

class PlanSuscripcionDetailModel extends PlanSuscripcionDetail {
  const PlanSuscripcionDetailModel({
    required super.id,
    required super.nombre,
    required super.descripcion,
    required super.precio,
    required super.periodo,
    super.limiteProductos,
    super.limiteServicios,
    super.limiteUsuarios,
    super.limiteSedes,
    super.limitePlantillasAtributos,
    super.limiteCotizaciones,
    super.limiteAlmacenamientoMB,
    super.precioSemestral,
    super.precioAnual,
    super.tieneWebPermanente,
    required super.tienePersonalizacion,
    required super.tieneDominioPropio,
    required super.tieneApi,
    required super.tieneReportesAvanzados,
    required super.caracteristicas,
  });

  factory PlanSuscripcionDetailModel.fromJson(Map<String, dynamic> json) {
    return PlanSuscripcionDetailModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      precio: (json['precio'] is String)
          ? double.parse(json['precio'] as String)
          : (json['precio'] as num).toDouble(),
      periodo: json['periodo'] as String,
      limiteProductos: json['limiteProductos'] as int?,
      limiteServicios: json['limiteServicios'] as int?,
      limiteUsuarios: json['limiteUsuarios'] as int?,
      limiteSedes: json['limiteSedes'] as int?,
      limitePlantillasAtributos: json['limitePlantillasAtributos'] as int?,
      limiteCotizaciones: json['limiteCotizaciones'] as int?,
      limiteAlmacenamientoMB: json['limiteAlmacenamientoMB'] as int?,
      precioSemestral: json['precioSemestral'] != null
          ? (json['precioSemestral'] is String
              ? double.parse(json['precioSemestral'] as String)
              : (json['precioSemestral'] as num).toDouble())
          : null,
      precioAnual: json['precioAnual'] != null
          ? (json['precioAnual'] is String
              ? double.parse(json['precioAnual'] as String)
              : (json['precioAnual'] as num).toDouble())
          : null,
      tieneWebPermanente: json['tieneWebPermanente'] as bool? ?? false,
      tienePersonalizacion: json['tienePersonalizacion'] as bool? ?? false,
      tieneDominioPropio: json['tieneDominioPropio'] as bool? ?? false,
      tieneApi: json['tieneApi'] as bool? ?? false,
      tieneReportesAvanzados: json['tieneReportesAvanzados'] as bool? ?? false,
      caracteristicas: json['caracteristicas'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'periodo': periodo,
      'limiteProductos': limiteProductos,
      'limiteServicios': limiteServicios,
      'limiteUsuarios': limiteUsuarios,
      'limiteSedes': limiteSedes,
      'limitePlantillasAtributos': limitePlantillasAtributos,
      'limiteCotizaciones': limiteCotizaciones,
      'limiteAlmacenamientoMB': limiteAlmacenamientoMB,
      'precioSemestral': precioSemestral,
      'precioAnual': precioAnual,
      'tieneWebPermanente': tieneWebPermanente,
      'tienePersonalizacion': tienePersonalizacion,
      'tieneDominioPropio': tieneDominioPropio,
      'tieneApi': tieneApi,
      'tieneReportesAvanzados': tieneReportesAvanzados,
      'caracteristicas': caracteristicas,
    };
  }

  PlanSuscripcionDetail toEntity() {
    return PlanSuscripcionDetail(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      precio: precio,
      periodo: periodo,
      limiteProductos: limiteProductos,
      limiteServicios: limiteServicios,
      limiteUsuarios: limiteUsuarios,
      limiteSedes: limiteSedes,
      limitePlantillasAtributos: limitePlantillasAtributos,
      limiteCotizaciones: limiteCotizaciones,
      limiteAlmacenamientoMB: limiteAlmacenamientoMB,
      precioSemestral: precioSemestral,
      precioAnual: precioAnual,
      tieneWebPermanente: tieneWebPermanente,
      tienePersonalizacion: tienePersonalizacion,
      tieneDominioPropio: tieneDominioPropio,
      tieneApi: tieneApi,
      tieneReportesAvanzados: tieneReportesAvanzados,
      caracteristicas: caracteristicas,
    );
  }
}
