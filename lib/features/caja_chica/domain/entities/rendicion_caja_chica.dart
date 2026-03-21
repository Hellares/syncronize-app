import 'package:equatable/equatable.dart';
import 'gasto_caja_chica.dart';

enum EstadoRendicion {
  pendiente,
  aprobada,
  rechazada;

  String get label {
    switch (this) {
      case EstadoRendicion.pendiente:
        return 'Pendiente';
      case EstadoRendicion.aprobada:
        return 'Aprobada';
      case EstadoRendicion.rechazada:
        return 'Rechazada';
    }
  }

  String get apiValue => name.toUpperCase();

  static EstadoRendicion fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDIENTE':
        return EstadoRendicion.pendiente;
      case 'APROBADA':
        return EstadoRendicion.aprobada;
      case 'RECHAZADA':
        return EstadoRendicion.rechazada;
      default:
        return EstadoRendicion.pendiente;
    }
  }
}

class RendicionCajaChica extends Equatable {
  final String id;
  final String cajaChicaId;
  final String cajaChicaNombre;
  final String codigo;
  final double totalGastado;
  final EstadoRendicion estado;
  final String? observaciones;
  final String? aprobadoPorNombre;
  final DateTime creadoEn;
  final List<GastoCajaChica> gastos;

  const RendicionCajaChica({
    required this.id,
    required this.cajaChicaId,
    required this.cajaChicaNombre,
    required this.codigo,
    required this.totalGastado,
    required this.estado,
    this.observaciones,
    this.aprobadoPorNombre,
    required this.creadoEn,
    this.gastos = const [],
  });

  @override
  List<Object?> get props => [
        id,
        cajaChicaId,
        codigo,
        totalGastado,
        estado,
        creadoEn,
      ];
}
