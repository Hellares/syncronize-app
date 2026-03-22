import 'package:equatable/equatable.dart';

enum TipoUbicacion { zona, pasillo, estante, nivel, bin }

class UbicacionAlmacen extends Equatable {
  final String id;
  final String empresaId;
  final String sedeId;
  final String codigo;
  final String nombre;
  final TipoUbicacion tipo;
  final String? parentId;
  final String? parentNombre;
  final int? capacidadMaxima;
  final String? descripcion;
  final bool isActive;
  final int childrenCount;
  final int? productosEnUbicacion;
  final List<UbicacionAlmacen> children;

  const UbicacionAlmacen({
    required this.id,
    required this.empresaId,
    required this.sedeId,
    required this.codigo,
    required this.nombre,
    this.tipo = TipoUbicacion.zona,
    this.parentId,
    this.parentNombre,
    this.capacidadMaxima,
    this.descripcion,
    this.isActive = true,
    this.childrenCount = 0,
    this.productosEnUbicacion,
    this.children = const [],
  });

  String get tipoLabel {
    switch (tipo) {
      case TipoUbicacion.zona:
        return 'Zona';
      case TipoUbicacion.pasillo:
        return 'Pasillo';
      case TipoUbicacion.estante:
        return 'Estante';
      case TipoUbicacion.nivel:
        return 'Nivel';
      case TipoUbicacion.bin:
        return 'Bin';
    }
  }

  @override
  List<Object?> get props => [id, codigo, nombre, tipo, parentId, isActive];
}
