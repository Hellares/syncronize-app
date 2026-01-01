import '../../domain/entities/atributo_valor.dart';

class AtributoValorModel extends AtributoValor {
  const AtributoValorModel({
    required super.id,
    required super.atributoId,
    required super.valor,
    required super.atributo,
  });

  factory AtributoValorModel.fromJson(Map<String, dynamic> json) {
    return AtributoValorModel(
      id: json['id'] as String,
      atributoId: json['atributoId'] as String,
      valor: json['valor'] as String,
      atributo: AtributoInfoModel.fromJson(json['atributo'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'atributoId': atributoId,
      'valor': valor,
      'atributo': {
        'id': atributo.id,
        'nombre': atributo.nombre,
        'clave': atributo.clave,
        'tipo': atributo.tipo,
        if (atributo.unidad != null) 'unidad': atributo.unidad,
      },
    };
  }

  AtributoValor toEntity() => this;

  factory AtributoValorModel.fromEntity(AtributoValor entity) {
    return AtributoValorModel(
      id: entity.id,
      atributoId: entity.atributoId,
      valor: entity.valor,
      atributo: AtributoInfoModel.fromEntity(entity.atributo),
    );
  }
}

class AtributoInfoModel extends AtributoInfo {
  const AtributoInfoModel({
    required super.id,
    required super.nombre,
    required super.clave,
    required super.tipo,
    super.unidad,
  });

  factory AtributoInfoModel.fromJson(Map<String, dynamic> json) {
    return AtributoInfoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      clave: json['clave'] as String,
      tipo: json['tipo'] as String,
      unidad: json['unidad'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'clave': clave,
      'tipo': tipo,
      if (unidad != null) 'unidad': unidad,
    };
  }

  AtributoInfo toEntity() => this;

  factory AtributoInfoModel.fromEntity(AtributoInfo entity) {
    return AtributoInfoModel(
      id: entity.id,
      nombre: entity.nombre,
      clave: entity.clave,
      tipo: entity.tipo,
      unidad: entity.unidad,
    );
  }
}
