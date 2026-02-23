import 'package:equatable/equatable.dart';

/// Entidad completa del plan de suscripción con todos los límites
class PlanSuscripcionDetail extends Equatable {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String periodo;
  final int? limiteProductos;
  final int? limiteServicios;
  final int? limiteUsuarios;
  final int? limiteSedes;
  final int? limitePlantillasAtributos;
  final int? limiteCotizaciones;
  final bool tienePersonalizacion;
  final bool tieneDominioPropio;
  final bool tieneApi;
  final bool tieneReportesAvanzados;
  final Map<String, dynamic> caracteristicas;

  const PlanSuscripcionDetail({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.periodo,
    this.limiteProductos,
    this.limiteServicios,
    this.limiteUsuarios,
    this.limiteSedes,
    this.limitePlantillasAtributos,
    this.limiteCotizaciones,
    required this.tienePersonalizacion,
    required this.tieneDominioPropio,
    required this.tieneApi,
    required this.tieneReportesAvanzados,
    required this.caracteristicas,
  });

  bool get isFreePlan => precio == 0;

  String get precioFormateado {
    if (isFreePlan) return 'Gratis';
    return 'S/ ${precio.toStringAsFixed(2)}';
  }

  String get periodoFormateado {
    final periodoMap = {
      'MENSUAL': 'mes',
      'TRIMESTRAL': 'trimestre',
      'SEMESTRAL': 'semestre',
      'ANUAL': 'año',
    };
    return periodoMap[periodo] ?? periodo;
  }

  String formatLimite(int? limite) {
    if (limite == null) return 'Ilimitado';
    return '$limite';
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        descripcion,
        precio,
        periodo,
        limiteProductos,
        limiteServicios,
        limiteUsuarios,
        limiteSedes,
        limitePlantillasAtributos,
        limiteCotizaciones,
        tienePersonalizacion,
        tieneDominioPropio,
        tieneApi,
        tieneReportesAvanzados,
      ];
}
