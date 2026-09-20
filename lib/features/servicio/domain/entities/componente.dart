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

  /// Como se nombra el componente: "OFFICE 365 - MICROSOFT".
  ///
  /// El tipo es la CATEGORIA y el modelo es el nombre concreto: van juntos y
  /// se leen como una cosa sola, con la marca detras. Leerlo como
  /// "OFFICE - MICROSOFT - 365" llevaba a crear una categoria llamada
  /// "OFFICE 365", que es justo lo que la categoria viene a evitar.
  ///
  /// 🔴 Separador ASCII: esto entra al ticket termico
  /// (ticket_esc_pos_generator) y los code pages de esas impresoras no tienen
  /// cualquier caracter. La web usa "·" porque solo va a pantalla.
  String get displayName {
    final queEs = [
      tipoComponente?.nombre,
      modelo,
    ].whereType<String>().where((e) => e.isNotEmpty).join(' ');
    final parts = <String>[];
    if (queEs.isNotEmpty) parts.add(queEs);
    if (marca != null && marca!.isNotEmpty) parts.add(marca!);
    return parts.isEmpty ? codigo : parts.join(' - ');
  }

  @override
  List<Object?> get props => [id, codigo, tipoComponenteId];
}
