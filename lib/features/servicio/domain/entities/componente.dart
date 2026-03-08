import 'package:equatable/equatable.dart';

class TipoComponente extends Equatable {
  final String id;
  final String? empresaId;
  final String nombre;
  final String categoria;
  final String? descripcion;
  final bool esGlobal;

  const TipoComponente({
    required this.id,
    this.empresaId,
    required this.nombre,
    required this.categoria,
    this.descripcion,
    this.esGlobal = false,
  });

  @override
  List<Object?> get props => [id, nombre, categoria];
}

class Componente extends Equatable {
  final String id;
  final String empresaId;
  final String tipoComponenteId;
  final String codigo;
  final String? marca;
  final String? modelo;
  final String? numeroSerie;
  final String estado;
  final TipoComponente? tipoComponente;

  const Componente({
    required this.id,
    required this.empresaId,
    required this.tipoComponenteId,
    required this.codigo,
    this.marca,
    this.modelo,
    this.numeroSerie,
    this.estado = 'INGRESADO',
    this.tipoComponente,
  });

  String get displayName {
    final parts = <String>[];
    if (tipoComponente != null) parts.add(tipoComponente!.nombre);
    if (marca != null) parts.add(marca!);
    if (modelo != null) parts.add(modelo!);
    return parts.isEmpty ? codigo : parts.join(' - ');
  }

  @override
  List<Object?> get props => [id, codigo, tipoComponenteId];
}
