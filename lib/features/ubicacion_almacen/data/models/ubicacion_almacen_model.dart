import '../../domain/entities/ubicacion_almacen.dart';

class UbicacionAlmacenModel extends UbicacionAlmacen {
  const UbicacionAlmacenModel({
    required super.id,
    required super.empresaId,
    required super.sedeId,
    required super.codigo,
    required super.nombre,
    super.tipo,
    super.parentId,
    super.parentNombre,
    super.capacidadMaxima,
    super.descripcion,
    super.isActive,
    super.childrenCount,
    super.productosEnUbicacion,
    super.children,
  });

  factory UbicacionAlmacenModel.fromJson(Map<String, dynamic> json) {
    return UbicacionAlmacenModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String? ?? '',
      sedeId: json['sedeId'] as String? ?? '',
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      tipo: _parseTipo(json['tipo'] as String?),
      parentId: json['parentId'] as String?,
      parentNombre: json['parent']?['nombre'] as String?,
      capacidadMaxima: json['capacidadMaxima'] as int?,
      descripcion: json['descripcion'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      childrenCount: json['_count']?['children'] as int? ??
          (json['children'] as List?)?.length ??
          0,
      productosEnUbicacion: json['productosEnUbicacion'] as int?,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) =>
                  UbicacionAlmacenModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static TipoUbicacion _parseTipo(String? tipo) {
    switch (tipo) {
      case 'ZONA':
        return TipoUbicacion.zona;
      case 'PASILLO':
        return TipoUbicacion.pasillo;
      case 'ESTANTE':
        return TipoUbicacion.estante;
      case 'NIVEL':
        return TipoUbicacion.nivel;
      case 'BIN':
        return TipoUbicacion.bin;
      default:
        return TipoUbicacion.zona;
    }
  }
}
