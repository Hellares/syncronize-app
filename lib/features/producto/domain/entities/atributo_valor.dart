import 'package:equatable/equatable.dart';

/// Entidad que representa el valor de un atributo asignado a un producto o variante
class AtributoValor extends Equatable {
  final String id;
  final String atributoId;
  final String valor;
  final AtributoInfo atributo;

  const AtributoValor({
    required this.id,
    required this.atributoId,
    required this.valor,
    required this.atributo,
  });

  @override
  List<Object?> get props => [id, atributoId, valor, atributo];
}

/// Información básica del atributo (plantilla)
class AtributoInfo extends Equatable {
  final String id;
  final String nombre;
  final String clave;
  final String tipo;
  final String? unidad;

  const AtributoInfo({
    required this.id,
    required this.nombre,
    required this.clave,
    required this.tipo,
    this.unidad,
  });

  @override
  List<Object?> get props => [id, nombre, clave, tipo, unidad];
}
