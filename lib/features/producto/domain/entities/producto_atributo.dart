import 'package:equatable/equatable.dart';

/// Tipos de atributos disponibles
enum AtributoTipo {
  color('COLOR'),
  talla('TALLA'),
  material('MATERIAL'),
  capacidad('CAPACIDAD'),
  select('SELECT'),
  multiSelect('MULTI_SELECT'),
  boolean('BOOLEAN'),
  numero('NUMERO'),
  texto('TEXTO');

  final String value;
  const AtributoTipo(this.value);

  static AtributoTipo fromString(String value) {
    return AtributoTipo.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AtributoTipo.texto,
    );
  }
}

/// Entity que representa un atributo configurable de producto
class ProductoAtributo extends Equatable {
  final String id;
  final String empresaId;
  final String? categoriaId;
  final String nombre;
  final String clave;
  final AtributoTipo tipo;
  final bool requerido;
  final String? descripcion;
  final String? unidad;
  final List<String> valores;
  final int orden;
  final bool mostrarEnListado;
  final bool usarParaFiltros;
  final bool mostrarEnMarketplace;
  final bool isActive;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  const ProductoAtributo({
    required this.id,
    required this.empresaId,
    this.categoriaId,
    required this.nombre,
    required this.clave,
    required this.tipo,
    required this.requerido,
    this.descripcion,
    this.unidad,
    required this.valores,
    required this.orden,
    required this.mostrarEnListado,
    required this.usarParaFiltros,
    required this.mostrarEnMarketplace,
    required this.isActive,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  /// Crea un ProductoAtributo desde la información de una plantilla.
  /// Usado para renderizar AtributoInputWidget con datos de plantilla.
  factory ProductoAtributo.fromPlantillaInfo({
    required String atributoId,
    required String nombre,
    required String clave,
    required AtributoTipo tipo,
    required bool requerido,
    String? descripcion,
    String? unidad,
    required List<String> valores,
    required int orden,
    String empresaId = '',
  }) {
    return ProductoAtributo(
      id: atributoId,
      empresaId: empresaId,
      categoriaId: null,
      nombre: nombre,
      clave: clave,
      tipo: tipo,
      requerido: requerido,
      descripcion: descripcion,
      unidad: unidad,
      valores: valores,
      orden: orden,
      mostrarEnListado: true,
      usarParaFiltros: true,
      mostrarEnMarketplace: true,
      isActive: true,
      creadoEn: DateTime.timestamp(),
      actualizadoEn: DateTime.timestamp(),
    );
  }

  /// Verifica si tiene valores predefinidos
  bool get hasValores => valores.isNotEmpty;

  /// Verifica si es un atributo de selección múltiple
  bool get isMultiSelect => tipo == AtributoTipo.multiSelect;

  /// Verifica si es un atributo de color
  bool get isColor => tipo == AtributoTipo.color;

  /// Verifica si es un atributo de talla
  bool get isTalla => tipo == AtributoTipo.talla;

  @override
  List<Object?> get props => [
        id,
        empresaId,
        categoriaId,
        nombre,
        clave,
        tipo,
        requerido,
        descripcion,
        unidad,
        valores,
        orden,
        mostrarEnListado,
        usarParaFiltros,
        mostrarEnMarketplace,
        isActive,
        creadoEn,
        actualizadoEn,
      ];
}
