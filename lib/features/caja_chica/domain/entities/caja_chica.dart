import 'package:equatable/equatable.dart';

enum EstadoCajaChica {
  activa,
  inactiva;

  String get label => this == activa ? 'Activa' : 'Inactiva';
  String get apiValue => name.toUpperCase();

  static EstadoCajaChica fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVA':
        return EstadoCajaChica.activa;
      case 'INACTIVA':
        return EstadoCajaChica.inactiva;
      default:
        return EstadoCajaChica.activa;
    }
  }
}

class CajaChica extends Equatable {
  final String id;
  final String empresaId;
  final String sedeId;
  final String sedeNombre;
  final String nombre;
  final double fondoFijo;
  final double saldoActual;
  final double umbralAlerta;
  final EstadoCajaChica estado;
  final String responsableId;
  final String responsableNombre;

  const CajaChica({
    required this.id,
    required this.empresaId,
    required this.sedeId,
    required this.sedeNombre,
    required this.nombre,
    required this.fondoFijo,
    required this.saldoActual,
    required this.umbralAlerta,
    required this.estado,
    required this.responsableId,
    required this.responsableNombre,
  });

  double get porcentajeUsado => fondoFijo > 0 ? (1 - saldoActual / fondoFijo) : 0;
  bool get fondoBajo => saldoActual <= umbralAlerta && umbralAlerta > 0;

  @override
  List<Object?> get props => [
        id,
        empresaId,
        sedeId,
        sedeNombre,
        nombre,
        fondoFijo,
        saldoActual,
        umbralAlerta,
        estado,
        responsableId,
        responsableNombre,
      ];
}
