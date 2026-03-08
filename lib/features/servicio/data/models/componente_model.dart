import '../../domain/entities/componente.dart';

class TipoComponenteModel extends TipoComponente {
  const TipoComponenteModel({
    required super.id,
    super.empresaId,
    required super.nombre,
    required super.categoria,
    super.descripcion,
    super.esGlobal,
  });

  factory TipoComponenteModel.fromJson(Map<String, dynamic> json) {
    return TipoComponenteModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String?,
      nombre: json['nombre'] as String,
      categoria: json['categoria'] as String,
      descripcion: json['descripcion'] as String?,
      esGlobal: json['esGlobal'] as bool? ?? false,
    );
  }
}

class ComponenteModel extends Componente {
  const ComponenteModel({
    required super.id,
    required super.empresaId,
    required super.tipoComponenteId,
    required super.codigo,
    super.marca,
    super.modelo,
    super.numeroSerie,
    super.estado,
    super.tipoComponente,
  });

  factory ComponenteModel.fromJson(Map<String, dynamic> json) {
    return ComponenteModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      tipoComponenteId: json['tipoComponenteId'] as String,
      codigo: json['codigo'] as String,
      marca: json['marca'] as String?,
      modelo: json['modelo'] as String?,
      numeroSerie: json['numeroSerie'] as String?,
      estado: json['estado'] as String? ?? 'INGRESADO',
      tipoComponente: json['tipoComponente'] != null
          ? TipoComponenteModel.fromJson(
              json['tipoComponente'] as Map<String, dynamic>)
          : null,
    );
  }
}
