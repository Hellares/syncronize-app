import 'package:equatable/equatable.dart';
import 'producto_atributo.dart';

/// Entity que representa un atributo dentro de una plantilla
/// Incluye información del orden y override de requerido y valores
class PlantillaAtributo extends Equatable {
  final String id;
  final String atributoId;
  final int orden;
  final bool? requeridoOverride;
  final List<String>? valoresOverride;
  final PlantillaAtributoInfo atributo;

  const PlantillaAtributo({
    required this.id,
    required this.atributoId,
    required this.orden,
    this.requeridoOverride,
    this.valoresOverride,
    required this.atributo,
  });

  /// Obtener si el atributo es requerido
  /// Usa override si está definido, sino usa el valor del atributo
  bool get esRequerido => requeridoOverride ?? atributo.requerido;

  /// Obtener valores a usar
  /// Usa valoresOverride si está definido y no está vacío, sino usa los valores del atributo base
  List<String> get valoresActuales {
    if (valoresOverride != null && valoresOverride!.isNotEmpty) {
      return valoresOverride!;
    }
    return atributo.valores;
  }

  PlantillaAtributo copyWith({
    String? id,
    String? atributoId,
    int? orden,
    bool? requeridoOverride,
    List<String>? valoresOverride,
    PlantillaAtributoInfo? atributo,
  }) {
    return PlantillaAtributo(
      id: id ?? this.id,
      atributoId: atributoId ?? this.atributoId,
      orden: orden ?? this.orden,
      requeridoOverride: requeridoOverride ?? this.requeridoOverride,
      valoresOverride: valoresOverride ?? this.valoresOverride,
      atributo: atributo ?? this.atributo,
    );
  }

  @override
  List<Object?> get props => [
        id,
        atributoId,
        orden,
        requeridoOverride,
        valoresOverride,
        atributo,
      ];
}

/// Información simplificada del atributo dentro de una plantilla
class PlantillaAtributoInfo extends Equatable {
  final String id;
  final String nombre;
  final String clave;
  final String tipo;
  final bool requerido;
  final String? descripcion;
  final String? unidad;
  final List<String> valores;

  const PlantillaAtributoInfo({
    required this.id,
    required this.nombre,
    required this.clave,
    required this.tipo,
    required this.requerido,
    this.descripcion,
    this.unidad,
    required this.valores,
  });

  /// Convertir tipo string a enum
  AtributoTipo get tipoEnum {
    switch (tipo.toLowerCase()) {
      case 'texto':
        return AtributoTipo.texto;
      case 'numero':
        return AtributoTipo.numero;
      case 'select':
        return AtributoTipo.select;
      case 'boolean':
        return AtributoTipo.boolean;
      case 'color':
        return AtributoTipo.color;
      case 'talla':
        return AtributoTipo.talla;
      case 'material':
        return AtributoTipo.material;
      case 'capacidad':
        return AtributoTipo.capacidad;
      case 'multiselect':
      case 'multi_select':
        return AtributoTipo.multiSelect;
      default:
        return AtributoTipo.texto;
    }
  }

  PlantillaAtributoInfo copyWith({
    String? id,
    String? nombre,
    String? clave,
    String? tipo,
    bool? requerido,
    String? descripcion,
    String? unidad,
    List<String>? valores,
  }) {
    return PlantillaAtributoInfo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      clave: clave ?? this.clave,
      tipo: tipo ?? this.tipo,
      requerido: requerido ?? this.requerido,
      descripcion: descripcion ?? this.descripcion,
      unidad: unidad ?? this.unidad,
      valores: valores ?? this.valores,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        clave,
        tipo,
        requerido,
        descripcion,
        unidad,
        valores,
      ];
}

/// Información de la categoría asociada a una plantilla
class CategoriaInfo extends Equatable {
  final String id;
  final String? nombreLocal;
  final String? nombrePersonalizado;

  const CategoriaInfo({
    required this.id,
    this.nombreLocal,
    this.nombrePersonalizado,
  });

  /// Obtener nombre a mostrar (personalizado o local)
  String get nombreDisplay => nombrePersonalizado ?? nombreLocal ?? '';

  CategoriaInfo copyWith({
    String? id,
    String? nombreLocal,
    String? nombrePersonalizado,
  }) {
    return CategoriaInfo(
      id: id ?? this.id,
      nombreLocal: nombreLocal ?? this.nombreLocal,
      nombrePersonalizado: nombrePersonalizado ?? this.nombrePersonalizado,
    );
  }

  @override
  List<Object?> get props => [id, nombreLocal, nombrePersonalizado];
}

/// Entity que representa una plantilla de atributos
/// Por ejemplo: "Motherboard", "Procesador", "Memoria RAM", etc.
class AtributoPlantilla extends Equatable {
  final String id;
  final String empresaId;
  final String? categoriaId;
  final String nombre;
  final String? descripcion;
  final String? icono;
  final bool esPredefinida;
  final int orden;
  final bool isActive;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  final List<PlantillaAtributo> atributos;
  final CategoriaInfo? categoria;

  const AtributoPlantilla({
    required this.id,
    required this.empresaId,
    this.categoriaId,
    required this.nombre,
    this.descripcion,
    this.icono,
    required this.esPredefinida,
    required this.orden,
    required this.isActive,
    required this.creadoEn,
    required this.actualizadoEn,
    required this.atributos,
    this.categoria,
  });

  /// Obtener cantidad de atributos en la plantilla
  int get cantidadAtributos => atributos.length;

  /// Obtener cantidad de atributos requeridos
  int get cantidadRequeridos =>
      atributos.where((a) => a.esRequerido).length;

  /// Obtener atributos por tipo
  List<PlantillaAtributo> getAtributosPorTipo(AtributoTipo tipo) {
    return atributos
        .where((a) => a.atributo.tipoEnum == tipo)
        .toList();
  }

  /// Verificar si tiene atributos
  bool get hasAtributos => atributos.isNotEmpty;

  /// Obtener resumen de tipos de atributos
  Map<AtributoTipo, int> get resumenTipos {
    final Map<AtributoTipo, int> resumen = {};
    for (var plantillaAtributo in atributos) {
      final tipo = plantillaAtributo.atributo.tipoEnum;
      resumen[tipo] = (resumen[tipo] ?? 0) + 1;
    }
    return resumen;
  }

  /// Obtener nombre de categoría para mostrar
  String? get nombreCategoria => categoria?.nombreDisplay;

  /// Crear copia con modificaciones
  AtributoPlantilla copyWith({
    String? id,
    String? empresaId,
    String? categoriaId,
    String? nombre,
    String? descripcion,
    String? icono,
    bool? esPredefinida,
    int? orden,
    bool? isActive,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
    List<PlantillaAtributo>? atributos,
    CategoriaInfo? categoria,
  }) {
    return AtributoPlantilla(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      categoriaId: categoriaId ?? this.categoriaId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      icono: icono ?? this.icono,
      esPredefinida: esPredefinida ?? this.esPredefinida,
      orden: orden ?? this.orden,
      isActive: isActive ?? this.isActive,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      atributos: atributos ?? this.atributos,
      categoria: categoria ?? this.categoria,
    );
  }

  @override
  List<Object?> get props => [
        id,
        empresaId,
        categoriaId,
        nombre,
        descripcion,
        icono,
        esPredefinida,
        orden,
        isActive,
        creadoEn,
        actualizadoEn,
        atributos,
        categoria,
      ];
}
