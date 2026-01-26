import 'package:equatable/equatable.dart';

/// Entity que representa una evaluación del proveedor
class ProveedorEvaluacion extends Equatable {
  final String id;
  final String proveedorId;
  final String empresaId;

  // Criterios de evaluación (1-5)
  final int calidadProductos;
  final int cumplimientoPlazos;
  final int atencionServicio;
  final int preciosCompetitivos;

  // Promedio
  final double calificacionGeneral;

  final String? comentarios;
  final String evaluadoPor;
  final DateTime fechaEvaluacion;

  const ProveedorEvaluacion({
    required this.id,
    required this.proveedorId,
    required this.empresaId,
    required this.calidadProductos,
    required this.cumplimientoPlazos,
    required this.atencionServicio,
    required this.preciosCompetitivos,
    required this.calificacionGeneral,
    this.comentarios,
    required this.evaluadoPor,
    required this.fechaEvaluacion,
  });

  /// Obtiene la calificación en estrellas
  String get estrellasCalificacion {
    final estrellas = calificacionGeneral.round();
    return '⭐' * estrellas;
  }

  /// Verifica si es una buena evaluación (>= 4.0)
  bool get esBuenaEvaluacion {
    return calificacionGeneral >= 4.0;
  }

  /// Verifica si es una evaluación excelente (>= 4.5)
  bool get esExcelenteEvaluacion {
    return calificacionGeneral >= 4.5;
  }

  /// Obtiene el criterio con menor puntuación
  String get criterioMenorPuntuacion {
    final criterios = {
      'Calidad de Productos': calidadProductos,
      'Cumplimiento de Plazos': cumplimientoPlazos,
      'Atención y Servicio': atencionServicio,
      'Precios Competitivos': preciosCompetitivos,
    };

    final menorEntry = criterios.entries.reduce(
      (a, b) => a.value < b.value ? a : b,
    );

    return menorEntry.key;
  }

  /// Obtiene el criterio con mayor puntuación
  String get criterioMayorPuntuacion {
    final criterios = {
      'Calidad de Productos': calidadProductos,
      'Cumplimiento de Plazos': cumplimientoPlazos,
      'Atención y Servicio': atencionServicio,
      'Precios Competitivos': preciosCompetitivos,
    };

    final mayorEntry = criterios.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return mayorEntry.key;
  }

  /// Obtiene un mapa de todos los criterios
  Map<String, int> get criteriosMap => {
        'Calidad de Productos': calidadProductos,
        'Cumplimiento de Plazos': cumplimientoPlazos,
        'Atención y Servicio': atencionServicio,
        'Precios Competitivos': preciosCompetitivos,
      };

  @override
  List<Object?> get props => [
        id,
        proveedorId,
        empresaId,
        calidadProductos,
        cumplimientoPlazos,
        atencionServicio,
        preciosCompetitivos,
        calificacionGeneral,
        comentarios,
        evaluadoPor,
        fechaEvaluacion,
      ];
}
