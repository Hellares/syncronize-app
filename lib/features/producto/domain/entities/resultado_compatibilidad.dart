import 'package:equatable/equatable.dart';

/// Resultado de validación de compatibilidad entre productos
class ResultadoCompatibilidad extends Equatable {
  final bool compatible;
  final List<ConflictoCompatibilidad> conflictos;

  const ResultadoCompatibilidad({
    required this.compatible,
    required this.conflictos,
  });

  @override
  List<Object?> get props => [compatible, conflictos];
}

/// Detalle de un conflicto de compatibilidad
class ConflictoCompatibilidad extends Equatable {
  final String reglaId;
  final String reglaNombre;
  final String productoOrigenId;
  final String productoOrigenNombre;
  final String productoDestinoId;
  final String productoDestinoNombre;
  final String atributoClave;
  final String valorOrigen;
  final String valorDestino;
  final String mensaje;

  const ConflictoCompatibilidad({
    required this.reglaId,
    required this.reglaNombre,
    required this.productoOrigenId,
    required this.productoOrigenNombre,
    required this.productoDestinoId,
    required this.productoDestinoNombre,
    required this.atributoClave,
    required this.valorOrigen,
    required this.valorDestino,
    required this.mensaje,
  });

  @override
  List<Object?> get props => [
        reglaId,
        reglaNombre,
        productoOrigenId,
        productoOrigenNombre,
        productoDestinoId,
        productoDestinoNombre,
        atributoClave,
        valorOrigen,
        valorDestino,
        mensaje,
      ];
}
